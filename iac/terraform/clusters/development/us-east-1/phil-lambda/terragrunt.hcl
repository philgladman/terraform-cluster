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
    "..//sops",
    "..//master-pem"
  ]
}

dependency "master-pem" {
  config_path = "..//master-pem"
}

dependency "sops" {
  config_path = "..//sops"
}

inputs = {
resource_name                          = "phil-${local.common.locals.env_name}"
region                                 = local.region.locals.region
master_private_key_ssm_parameter_arn   = dependency.master-pem.outputs.master_private_key_ssm_parameter_arn
ebs_kms_key_id                         = dependency.sops.outputs.ebs_kms_key_id
ebs_kms_key_arn                        = dependency.sops.outputs.ebs_kms_key_arn
github_username                        = "${local.common.locals.github_username}"
github_pat                             = "${local.common.locals.github_pat}"

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}