
locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  alerts        = read_terragrunt_config(find_in_parent_folders("alerts.hcl"))
}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/alerts/"
}

dependency "kms" {
  config_path = "../kms"
}

# enumerate all the Terragrunt modules that need to be applied in order for this module to be able to apply
dependencies {
  paths = [
    "..//kms"
  ]
}

inputs = {
  resource_name                      = "phil-${local.common.locals.env_name}"
  topic_name                         = local.alerts.locals.topic_name
  emails                             = local.alerts.locals.emails
  trail_name                         = local.alerts.locals.trail_name
  team_list                          = local.alerts.locals.team_list
  development_bastion_log_group_name = local.alerts.locals.development_bastion_log_group_name
  production_bastion_log_group_name  = local.alerts.locals.production_bastion_log_group_name
  kms_key_arn                        = dependency.kms.outputs.kms_key_arn
  kms_key_id                         = dependency.kms.outputs.kms_key_id

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}

