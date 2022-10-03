output "ebs_kms_key_id" {
  value = aws_kms_key.kms_key.id
}

output "ebs_kms_key_arn" {
  value = aws_kms_key.kms_key.arn
}