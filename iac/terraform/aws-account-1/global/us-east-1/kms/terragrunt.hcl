
locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  alerts        = read_terragrunt_config(find_in_parent_folders("alerts.hcl"))
}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/kms/"
}

inputs = {
  resource_name = "phil-${local.common.locals.env_name}"
  create_key    = true
  key_alias     = "general-key"
  description   = "KMS key to be used for all services"

  attach_sns_kms_policy        = true
  attach_cloudtrail_kms_policy = true
  attach_cloudwatch_kms_policy = true
  attach_s3_kms_policy         = true
  attach_iam_kms_policy        = true

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}

