output "master_ssh_key_name" {
  value = module.key_pair.key_pair_name
}

output "master_private_key_ssm_parameter_arn" {
  value = aws_ssm_parameter.private_key.arn
}
