locals {
  uname             = lower(var.resource_name)
}


resource "aws_kms_key" "kms_key" {
  description             = "KMS key 1"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = false
  tags                    = var.tags
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${local.uname}-ebs-key"
  target_key_id = aws_kms_key.kms_key.key_id
}