locals {
  common      = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
    source = "../../../..//modules/phil-lambda"
}

include {
    path = find_in_parent_folders()
}

dependencies {
  paths = [
    "..//vpc",
    "..//sops"
  ]
}

inputs = {
resource_name  = "phil-${local.common.locals.env_name}"
region         = local.region.locals.region

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}