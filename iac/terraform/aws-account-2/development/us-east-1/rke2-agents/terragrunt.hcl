locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  rke2          = read_terragrunt_config(find_in_parent_folders("rke2.hcl"))
}


include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/rke2-agents/"
}

dependency "vpc" {
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
}

dependency "controlplane" {
  config_path = "../rke2-controlplane"
}

# enumerate all the Terragrunt modules that need to be applied in order for this module to be able to apply
dependencies {
  paths = [
    "..//vpc",
    "..//master-pem",
    "..//sops",
    "..//bastion",
    "..//controlplane"
  ]
}

inputs = {
  resource_name                  = "phil-${local.common.locals.env_name}"
  source_ami                     = "${local.rke2.locals.source_ami}"
  agent_instance_type            = "${local.rke2.locals.agent_instance_type}"
  rke2_subnet_ids                = dependency.vpc.outputs.rke2_subnet_ids
  master_ssh_key_name            = dependency.master-pem.outputs.master_ssh_key_name
  vpc_id                         = dependency.vpc.outputs.vpc_id
  ebs_kms_key_id                 = dependency.sops.outputs.ebs_kms_key_id
  ebs_kms_key_arn                = dependency.sops.outputs.ebs_kms_key_arn
  region                         = local.region.locals.region
  cloudwatch_agent_ssm_name      = "phil-${local.common.locals.env_name}-cloudwatch-agent-config"
  bastion_security_group_id      = dependency.bastion.outputs.bastion_security_group_id
  is_agent                       = true
  controlplane_security_group_id = dependency.controlplane.outputs.controlplane_security_group_id
  token_bucket_id                = dependency.controlplane.outputs.token_bucket_id
  token_bucket_arn               = dependency.controlplane.outputs.token_bucket_arn
  token_object_id                = dependency.controlplane.outputs.token_object_id
  
  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}