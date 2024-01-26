output "kms_key_id" {
  value = try(aws_kms_key.kms_key[0].key_id, "")
}

output "kms_key_arn" {
  value = try(aws_kms_key.kms_key[0].arn, "")
}
