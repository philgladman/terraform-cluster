locals {
  uname         = lower(var.resource_name)
  attach_policy = var.attach_sns_kms_policy || var.attach_cloudtrail_kms_policy || var.attach_cloudwatch_kms_policy || var.attach_s3_kms_policy || var.attach_policy
}

resource "aws_kms_key" "kms_key" {
  count                   = var.create_key ? 1 : 0
  description             = var.description
  key_usage               = var.key_usage
  deletion_window_in_days = var.deletion_window_in_days
  is_enabled              = var.is_enabled
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  # policy                  = data.aws_iam_policy_document.combined[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "kms_alias" {
  count         = var.create_key ? 1 : 0
  name          = "${var.key_name}-test-1"
  target_key_id = aws_kms_key.kms_key[0].key_id
}

# data "aws_iam_policy_document" "combined" {
#   count = local.create_bucket && local.attach_policy ? 1 : 0

#   source_policy_documents = compact([
#     var.attach_sns_kms_policy ? data.aws_iam_policy_document.attach_sns_kms_policy[0].json : "",
#     var.attach_cloudtrail_kms_policy ? data.aws_iam_policy_document.attach_cloudtrail_kms_policy[0].json : "",
#     var.attach_cloudwatch_kms_policy ? data.aws_iam_policy_document.attach_cloudwatch_kms_policy[0].json : "",
#     var.attach_s3_kms_policy  ? data.aws_iam_policy_document.attach_s3_kms_policy[0].json : "",
#     var.attach_policy ? var.kms_policy : ""
#   ])
# }

# # # Enforce ssl-requests-only for s3 buckets
# data "aws_iam_policy_document" "enforce_ssl" {
#   count = local.create_bucket && var.attach_enforce_ssl_policy ? 1 : 0

#   statement {
#     sid = "AllowSSLRequestsOnly"

#     principals {
#       type = "*"
#       identifiers = ["*"]
#     }

#     effect = "Deny"

#     actions = [
#       "s3:*",
#     ]

#     resources = [
#        "${aws_s3_bucket.this[0].arn}",
#        "${aws_s3_bucket.this[0].arn}/*"
#     ]

#     condition {
#       test     = "Bool"
#       variable = "aws:SecureTransport"
#       values = [
#         "false",
#       ]
#     }
#   }
# }