
locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  rke2          = read_terragrunt_config(find_in_parent_folders("rke2.hcl"))
  sns         = read_terragrunt_config(find_in_parent_folders("sns.hcl"))

}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/sns/"
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
  topic_name     = local.sns.locals.topic_name
  emails         = local.sns.locals.emails
  sns_kms_key_id = local.sns.locals.sns_kms_key_id

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}

