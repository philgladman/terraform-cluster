output "bastion_public_ip" {
  value = aws_instance.bastion_instance.public_ip
}

output "EIP_bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}

# rke2_subnet_id

 
#output "config-file" {
#  value = aws_ssm_parameter.cloudwatch_agent.value
#  sensitive = false
#}