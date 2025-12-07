locals {
  uname = lower(var.resource_name)
}

resource "aws_security_group" "controlplane_sg" {
  name        = "${local.uname}-controlplan-sg"
  description = "Controlplane security group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.bastion_security_group_id}"]
  }

  ingress {
    description     = "Allow all from bastion"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${var.bastion_security_group_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "random_password" "cluster_token" {
  length  = 40
  special = false
}

resource "random_password" "cluster_bucket_name_suffix" {
  length  = 10
  special = false
  upper   = false
}

/* resource "aws_ssm_parameter" "cluster_token" {
  description = "Rke2 cluster join token"
  name        = "${local.uname}-cluster-token"
  type        = "SecureString"
  value       = random_password.cluster_token
} */

resource "aws_s3_bucket" "cluster_bucket" {
  bucket = "${local.uname}-cluster-${random_password.cluster_bucket_name_suffix.result}"
  tags   = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_object" "cluster_token" {
  bucket                 = aws_s3_bucket.cluster_bucket.id
  key                    = "token"
  content_type           = "text/plain"
  content                = random_password.cluster_token.result
  server_side_encryption = "aws:kms"
  tags                   = var.tags
}

resource "aws_s3_bucket_public_access_block" "restrict_s3_bucket" {
  bucket                  = aws_s3_bucket.cluster_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

#
## Create 1 controlplane without ASG
#

resource "aws_instance" "controlplane_instance" {
  ami                    = var.source_ami
  instance_type          = var.controlplane_instance_type
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.controlplane_sg.id}"]
  subnet_id              = var.rke2_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.controlplane-profile-role.name
  user_data              = data.cloudinit_config.this.rendered
  tags = merge({
    "Name" = "${local.uname}-controlplane",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id  = var.ebs_kms_key_arn
  }
}

#
## Create controlplane with ASG
#

##### Creating and attaching IAM roles and policies

resource "aws_iam_role_policy_attachment" "s3-attachment" {
  role       = aws_iam_role.controlplane-role.name
  policy_arn = aws_iam_policy.controlplane-s3-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "kms-attachment" {
  role       = aws_iam_role.controlplane-role.name
  policy_arn = aws_iam_policy.controlplane-kms-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm-attachment" {
  role       = aws_iam_role.controlplane-role.name
  policy_arn = aws_iam_policy.controlplane-ssm-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-attachment" {
  role       = aws_iam_role.controlplane-role.name
  policy_arn = aws_iam_policy.controlplane-cloudwatch-agent-access-policy.arn
}

resource "aws_iam_policy" "controlplane-s3-access-policy" {
  name        = "${local.uname}-controlplane-s3-access-policy"
  path        = "/"
  description = "S3 policy"
  policy      = data.aws_iam_policy_document.s3_access_policy_doc.json
}

resource "aws_iam_policy" "controlplane-kms-access-policy" {
  name        = "${local.uname}-controlplane-kms-access-policy"
  path        = "/"
  description = "KMS policy"
  policy      = data.aws_iam_policy_document.kms_access_policy_doc.json
}

resource "aws_iam_policy" "controlplane-ssm-access-policy" {
  name        = "${local.uname}-controlplane-ssm-access-policy"
  path        = "/"
  description = "SSM policy"
  policy      = data.aws_iam_policy_document.ssm_access_policy_doc.json
}

resource "aws_iam_policy" "controlplane-cloudwatch-agent-access-policy" {
  name        = "${local.uname}-controlplane-cloudwatch-agent-policy"
  path        = "/"
  description = "Cloudwatch Agent policy"
  policy      = data.aws_iam_policy_document.cloudwatch_agent_policy_doc.json
}

resource "aws_iam_role" "controlplane-role" {
  name               = "${local.uname}-controlplane-role"
  assume_role_policy = data.aws_iam_policy_document.assume-controlplane-role.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "controlplane-profile-role" {
  name = "${local.uname}-controlplane-profile-role"
  role = aws_iam_role.controlplane-role.name
}

resource "aws_kms_grant" "ebs_kms_grant" {
  name              = "ebskey-grant-access"
  key_id            = var.ebs_kms_key_arn
  grantee_principal = data.aws_iam_role.default_asg.arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey", "CreateGrant", "DescribeKey", "ReEncryptFrom", "ReEncryptTo", "GenerateDataKeyWithoutPlaintext"]

}
