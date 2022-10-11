output "controlplane_security_group_id" {
   value = aws_security_group.allow-ssh-from-bastion.id
}

# resource "aws_security_group" "allow-ssh"
 
#output "config-file" {
#  value = aws_ssm_parameter.cloudwatch_agent.value
#  sensitive = false
#}