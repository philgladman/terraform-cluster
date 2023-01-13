
locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  rke2          = read_terragrunt_config(find_in_parent_folders("rke2.hcl"))
  ses           = read_terragrunt_config(find_in_parent_folders("ses.hcl"))

}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/ses/"
}

/* dependency "vpc" {
  config_path = "../vpc"
}

dependency "master-pem" {
  config_path = "../master-pem"
}

dependency "sops" {
  config_path = "../sops"
}

dependency "bastion" {
  config_path = "../bastion"
} */

inputs = {
  resource_name  = "phil-${local.common.locals.env_name}"
  emails         = local.ses.locals.emails
  zone_id        = local.ses.locals.zone_id
  domain         = local.ses.locals.domain

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}

