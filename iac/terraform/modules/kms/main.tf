locals {
  uname             = lower(var.resource_name)
}


module "kms" {
  count                   = var.create_key? 1 : 0
  source                  = "../common/kms"
  key_name                = "alias/${local.uname}-${var.key_alias}"
  description             = var.description
  key_usage               = var.key_usage
  deletion_window_in_days = var.deletion_window_in_days
  is_enabled              = var.is_enabled
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  kms_policy              = var.kms_policy
  tags                    = var.tags

  attach_sns_kms_policy        = var.attach_sns_kms_policy
  attach_cloudtrail_kms_policy = var.attach_cloudtrail_kms_policy
  attach_cloudwatch_kms_policy = var.attach_cloudwatch_kms_policy
  attach_s3_kms_policy         = var.attach_s3_kms_policy
}