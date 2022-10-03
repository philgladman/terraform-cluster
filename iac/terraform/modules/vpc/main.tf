locals {
  vpc_subnets       = cidrsubnets("10.4.0.0/16", 8, 8, 8, 8, 8, 8, 8, 8, 8)
  private_subnets   = slice(local.vpc_subnets, 0, 3)
  public_subnets    = slice(local.vpc_subnets, 3, 6)
  database_subnets  = slice(local.vpc_subnets, 6, 9)
  uname             = lower(var.resource_name)
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "3.16.0"
  name                         = local.uname
  cidr                         = "10.4.0.0/19"
  azs                          = slice(data.aws_availability_zones.available.names, 1, 4)
  private_subnets              = local.private_subnets
  public_subnets               = local.public_subnets
  database_subnets             = local.database_subnets
  enable_vpn_gateway           = false
  enable_nat_gateway           = true
  single_nat_gateway           = true
  one_nat_gateway_per_az       = false
  reuse_nat_ips                = false
  create_igw                   = true
  enable_dns_hostnames         = false
  enable_dns_support           = false
  public_subnet_suffix         = "public"
  private_subnet_suffix        = "private"
  database_subnet_suffix       = "database"
  create_database_subnet_group = false
  map_public_ip_on_launch      = true
  enable_ipv6                  = false
  tags = var.tags
}