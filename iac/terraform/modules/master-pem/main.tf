locals {
  uname = lower(var.resource_name)
}

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name           = "${local.uname}-master-key"
  create_private_key = true

  tags = var.tags
}

resource "aws_ssm_parameter" "private_key" {
  name        = "${module.key_pair.key_pair_name}-private"
  description = "private master key"
  type        = "SecureString"
  value       = module.key_pair.private_key_openssh

  tags = var.tags
}

resource "aws_ssm_parameter" "public_key" {
  name        = "${module.key_pair.key_pair_name}-public"
  description = "public master key"
  type        = "SecureString"
  value       = module.key_pair.public_key_openssh

  tags = var.tags
}
