data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "00_userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/userdata.sh", {
      MASTER_KEY_SSM_NAME   = var.master_key_ssm_name
      LOG_GROUP_NAME        = var.log_group_name 
      METRICS_NAMESPACE     = var.metrics_namespace
      LOG_RETENTION_IN_DAYS = var.log_retention_in_days
      SNS_TOPIC_ARN         = var.sns_topic_arn
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
    resources = [
      "${var.ebs_kms_key_arn}",
      "arn:aws:kms:us-east-1:567243246807:key/a993d3be-913f-4a76-be2e-c5294b39a7b5"
      ]
  }
}

data "aws_iam_policy_document" "s3_access_policy_doc" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:List*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ssm_access_policy_doc" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${var.master_key_ssm_name}"]
  }
  statement {
    effect  = "Allow"
    actions = [
        "cloudwatch:PutMetricData",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "ec2:DescribeInstances",
        "ec2:DescribeVolumes",
        "ec2:DescribeTags",
        "ec2:DescribePrefixLists",
        "logs:PutLogEvents",
        "logs:PutRetentionPolicy",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:CreateLogGroup"
        ]
    resources = ["*"]
  }
  statement {
    effect  = "Deny"
    actions = [
        "s3:*",
        "ec2:*",
        "kms:*"
        ]
    condition {
      test = "StringNotEquals"
      variable = "aws:SourceVpc"
      values = ["$${aws:Ec2InstanceSourceVpc}"]
    }
    condition {
      test = "BoolIfExists"
      variable = "aws:ViaAWSService"
      values = ["false"]
    }
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "kubeconfig_access_policy_doc" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["eks:*"]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}
