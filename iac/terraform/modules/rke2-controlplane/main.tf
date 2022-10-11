locals {
  uname             = lower(var.resource_name)
}

resource "aws_security_group" "allow-ssh-from-bastion" {
  name        = "${local.uname}-allow-ssh-from-bastion"
  description = "Allow SSH inbound traffic from bastion host"
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow SSH from bastion"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = ["${var.bastion_security_group_id}"]
  }

  ingress {
    description      = "Allow all access from bastion"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups  = ["${var.bastion_security_group_id}"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = var.tags
}

#
# SSM Paramater for cloudwatch agent
#

resource "aws_instance" "controlplane_instance" {
  ami                    = var.source_ami
  instance_type          = var.instance_type
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${aws_security_group.allow-ssh-from-bastion.id}"] 
  subnet_id              = var.rke2_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.controlplane-profile-role.name
  user_data              = data.cloudinit_config.this.rendered
  tags                   = merge({
    "Name" = "${local.uname}-controlplane",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id   = var.ebs_kms_key_id
  }
}

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