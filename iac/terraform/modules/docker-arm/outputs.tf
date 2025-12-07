output "EIP_docker_public_ip" {
  value = aws_eip.docker_arm_eip.public_ip
}

# rke2_subnet_id


#output "config-file" {
#  value = aws_ssm_parameter.cloudwatch_agent.value
#  sensitive = false
#}