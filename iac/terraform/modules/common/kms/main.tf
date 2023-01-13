resource "aws_kms_key" "kms_key" {
  description             = var.kms_description
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = false
  policy                  = var.kms_policy
  tags                    = var.tags
}

resource "aws_kms_alias" "kms_alias" {
  name          = "alias/${var.kms_alias}"
  target_key_id = aws_kms_key.kms_key.key_id
}
