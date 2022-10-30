data "cloudinit_config" "this" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "00_userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/userdata.sh", {
      ssm_cloudwatch_config   = var.cloudwatch_agent_ssm_name
      type                    = var.is_agent ? "agent" : "server"
      token_bucket            = var.token_bucket_id
      token_object            = var.token_object_id
    })
  }
}

data "aws_iam_policy_document" "assume-agent-role" {
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
  statement {
    sid    = "BucketAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [var.token_bucket_arn, "${var.token_bucket_arn}/*"]
  }

  statement {
    sid    = "s3ListAccess"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets"
    ]

    resources = [replace(var.token_bucket_arn, var.token_bucket_id, "*")]
  }

  statement {
    sid    = "ec2DescribeInstances"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances"
    ]

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
