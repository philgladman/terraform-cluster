locals {
  uname             = lower(var.resource_name)
}

resource "aws_kms_key" "kms_key" {

  description             = var.description
  key_usage               = var.key_usage
  deletion_window_in_days = var.deletion_window_in_days
  is_enabled              = var.is_enabled
  enable_key_rotation     = var.enable_key_rotation
  multi_region            = var.multi_region
  policy                  = var.kms_policy
  tags                    = var.tags
}

resource "aws_kms_alias" "kms_alias" {
  name          = var.key_name
  target_key_id = aws_kms_key.kms_key.key_id
}