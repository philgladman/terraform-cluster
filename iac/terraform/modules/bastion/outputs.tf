output "EIP_bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
}

output "bastion_security_group_id" {
  value = aws_security_group.bastion_sg.id
}
