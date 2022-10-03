output "vpc_id" {
  value = module.vpc.vpc_id
}

output "bastion_subnet_id" {
  value = module.vpc.public_subnets[0]
}