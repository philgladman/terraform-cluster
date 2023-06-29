locals {
  vpc_subnets      = cidrsubnets("${var.cidr}", 8, 8, 8, 8, 8, 8, 8, 8, 8)
  private_subnets  = slice(local.vpc_subnets, 0, 3)
  public_subnets   = slice(local.vpc_subnets, 3, 6)
  database_subnets = slice(local.vpc_subnets, 6, 9)
  uname            = lower(var.resource_name)
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source                       = "terraform-aws-modules/vpc/aws"
  version                      = "3.16.0"
  name                         = local.uname
  cidr                         = var.cidr
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
  enable_dns_hostnames         = true
  enable_dns_support           = true
  public_subnet_suffix         = "public"
  private_subnet_suffix        = "private"
  database_subnet_suffix       = "database"
  create_database_subnet_group = false
  map_public_ip_on_launch      = true
  enable_ipv6                  = false
  tags = var.tags
}

data "aws_region" "current" {}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.uname}-vpc-endpoints-sg"
  description = "EC2 VPC Endpoint Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "Allow HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["${module.vpc.vpc_cidr_block}"]
  }

  tags = var.tags
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  service_name        = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type   = "Gateway"
  vpc_id              = module.vpc.vpc_id
  route_table_ids     = [
    module.vpc.private_route_table_ids[0],
    module.vpc.public_route_table_ids[0]
  ]
}


resource "aws_vpc_endpoint" "endpoint" {
  count = length(var.endpoints)
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${var.endpoints[count.index]}"
  subnet_ids          = [
    module.vpc.private_subnets[0]
  ]

  security_group_ids = [
    aws_security_group.vpc_endpoints.id,
  ]

  vpc_endpoint_type   = "Interface"
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true

  dns_options {
    dns_record_ip_type = "ipv4"
  }
}
