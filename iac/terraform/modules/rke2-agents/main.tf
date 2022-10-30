locals {
  uname             = lower(var.resource_name)
}

resource "aws_instance" "agent_instance" {
  ami                    = var.source_ami
  instance_type          = var.instance_type
  key_name               = var.master_ssh_key_name
  monitoring             = true
  vpc_security_group_ids = ["${var.controlplane_security_group_id}"] 
  subnet_id              = var.rke2_subnet_id
  iam_instance_profile   = aws_iam_instance_profile.agent-profile-role.name
  user_data              = data.cloudinit_config.this.rendered
  tags                   = merge({
    "Name" = "${local.uname}-agent",
  }, var.tags)

  root_block_device {
    volume_size = 20
    encrypted   = true
    kms_key_id   = var.ebs_kms_key_id
  }
}

##### Creating and attaching IAM roles and policies

resource "aws_iam_role_policy_attachment" "s3-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-s3-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "kms-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-kms-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-ssm-access-policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch-attachment" {
    role       = aws_iam_role.agent-role.name
    policy_arn = aws_iam_policy.agent-cloudwatch-agent-access-policy.arn
}

resource "aws_iam_policy" "agent-s3-access-policy" {
  name        = "${local.uname}-agent-s3-access-policy"
  path        = "/"
  description = "S3 policy"
  policy      = data.aws_iam_policy_document.s3_access_policy_doc.json
}

resource "aws_iam_policy" "agent-kms-access-policy" {
  name        = "${local.uname}-agent-kms-access-policy"
  path        = "/"
  description = "KMS policy"
  policy      = data.aws_iam_policy_document.kms_access_policy_doc.json
} 

resource "aws_iam_policy" "agent-ssm-access-policy" {
  name        = "${local.uname}-agent-ssm-access-policy"
  path        = "/"
  description = "SSM policy"
  policy      = data.aws_iam_policy_document.ssm_access_policy_doc.json
} 

resource "aws_iam_policy" "agent-cloudwatch-agent-access-policy" {
  name        = "${local.uname}-agent-cloudwatch-agent-policy"
  path        = "/"
  description = "Cloudwatch Agent policy"
  policy      = data.aws_iam_policy_document.cloudwatch_agent_policy_doc.json
} 

resource "aws_iam_role" "agent-role" {
  name               = "${local.uname}-agent-role"
  assume_role_policy = data.aws_iam_policy_document.assume-agent-role.json
  tags               = var.tags
}

resource "aws_iam_instance_profile" "agent-profile-role" {
  name = "${local.uname}-agent-profile-role"
  role = aws_iam_role.agent-role.name
}