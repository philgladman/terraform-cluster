output "kms_key_id" {
  value = try(module.kms[0].kms_key_id, "")
}

output "kms_key_arn" {
  value = try(module.kms[0].kms_key_arn, "")
}
