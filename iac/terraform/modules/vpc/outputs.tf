output "vpc_id" {
  value = module.vpc.vpc_id
}

output "bastion_subnet_id" {
  value = module.vpc.public_subnets[0]
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "database_subnet_ids" {
  value = module.vpc.database_subnets
}
