locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/ec2-image-builder/"
}

dependency "vpc" {
  config_path = "../vpc"
}

# enumerate all the Terragrunt modules that need to be applied in order for this module to be able to apply
dependencies {
  paths = [
    "..//vpc"
  ]
}

inputs = {
  resource_name       = "phil-${local.common.locals.env_name}"
  global_kms_key_name = "phil-global-general-key"
  private_subnet_id   = dependency.vpc.outputs.private_subnet_ids[0]
  vpc_id              = dependency.vpc.outputs.vpc_id
  ami_name_prefix     = "amazon-eks-node-al2023"
  source_ami_arch     = "x86_64"
  eks_version         = "1.34"
  kms_key_alias       = "alias/phil-global-general-key"

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}