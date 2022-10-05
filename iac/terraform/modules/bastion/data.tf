data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "00_userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/userdata.sh", {
      ssm_cloudwatch_config = var.cloudwatch_agent_ssm_name
    })
  }
}

data "aws_iam_policy_document" "assume-bastion-role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "kms_access_policy_doc" {
  version = "2012-10-17"
  statement {
    sid       = "EnableKMSIAMUserPermissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["${var.ebs_kms_key_arn}"]
  }
}

data "aws_iam_policy_document" "s3_access_policy_doc" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ssm_access_policy_doc" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.cloudwatch_agent_ssm_name}"
    ]
  }
}

data "aws_iam_policy_document" "cloudwatch_agent_policy_doc" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = [
        "cloudwatch:PutMetricData",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
        ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}

#data "aws_iam_policy" "amazon_ec2_role_for_ssm" {
#  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
#}
#
#
#data "aws_iam_policy" "cloudwatch_agent_server_policy" {
#  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#}
