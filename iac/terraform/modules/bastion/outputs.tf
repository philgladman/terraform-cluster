output "bastion_public_ip" {
  value = aws_instance.bastion_instance.public_ip
}

output "EIP_bastion_public_ip" {
  value = aws_eip.bastion_eip.public_ip
}