locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  vpc    = read_terragrunt_config(find_in_parent_folders("vpc.hcl"))
}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/vpc/"
}

inputs = {
  resource_name = "phil-${local.common.locals.env_name}"
  cidr          = local.vpc.locals.cidr
  endpoints     = local.vpc.locals.endpoints
  region        = local.region.locals.region

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}
