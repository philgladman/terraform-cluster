locals {
  uname         = lower(var.resource_name)
  attach_policy = var.attach_sns_kms_policy || var.attach_cloudtrail_kms_policy || var.attach_cloudwatch_kms_policy || var.attach_s3_kms_policy || var.attach_policy
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "kms_key" {
  count                   = var.create_key ? 1 : 0
  description             = var.description
  key_usage               = var.key_usage
  deletion_window_in_days = var.deletion_window_in_days
  is_enabled              = var.is_enabled
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  policy                  = data.aws_iam_policy_document.combined[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "kms_alias" {
  count         = var.create_key ? 1 : 0
  name          = "${var.key_name}-test-1"
  target_key_id = aws_kms_key.kms_key[0].key_id
}

data "aws_iam_policy_document" "combined" {
  count = var.create_key && local.attach_policy ? 1 : 0

  source_policy_documents = compact([
    var.attach_iam_kms_policy  ? data.aws_iam_policy_document.iam_kms_policy[0].json : "",
    var.attach_sns_kms_policy ? data.aws_iam_policy_document.sns_kms_policy[0].json : "",
    var.attach_cloudwatch_kms_policy ? data.aws_iam_policy_document.cloudwatch_kms_policy[0].json : "",
    # var.attach_cloudtrail_kms_policy ? data.aws_iam_policy_document.cloudtrail_kms_policy[0].json : "",
    var.attach_policy ? var.kms_policy : ""
  ])
}

# KMS Policy for IAM Perms
data "aws_iam_policy_document" "iam_kms_policy" {
  count = var.create_key && var.attach_iam_kms_policy ? 1 : 0
  
  statement {
    sid = "Enable IAM User Permissions"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

# KMS Policy for SNS Perms
data "aws_iam_policy_document" "sns_kms_policy" {
  count = var.create_key && var.attach_sns_kms_policy ? 1 : 0
  
  statement {
    sid = "Allow Cloudwatch to use key for SNS"
    principals {
      type = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    effect    = "Allow"
    actions   = [
      "kms:Decrypt",
      "kms:GenerateDataKey*",
    ]
    resources = ["*"]
  }
}

# KMS Policy for Cloudwatch Perms
data "aws_iam_policy_document" "cloudwatch_kms_policy" {
  count = var.create_key && var.attach_cloudwatch_kms_policy ? 1 : 0
  
  statement {
    sid = "Allow Cloudwatch to use key"
    principals {
      type = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }
    effect    = "Allow"
    actions   = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"]
    }
  }
}