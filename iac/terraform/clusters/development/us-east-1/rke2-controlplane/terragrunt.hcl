locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  rke2          = read_terragrunt_config(find_in_parent_folders("rke2.hcl"))
}


include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/rke2-controlplane/"
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

inputs = {
  resource_name              = "phil-${local.common.locals.env_name}"
  source_ami                 = "${local.rke2.locals.source_ami}"
  instance_type              = "${local.rke2.locals.instance_type}"
  rke2_subnet_id             = dependency.vpc.outputs.rke2_subnet_id
  master_ssh_key_name        = dependency.master-pem.outputs.master_ssh_key_name
  vpc_id                     = dependency.vpc.outputs.vpc_id
  ebs_kms_key_id             = dependency.sops.outputs.ebs_kms_key_id
  ebs_kms_key_arn            = dependency.sops.outputs.ebs_kms_key_arn
  region                     = local.region.locals.region
  cloudwatch_agent_ssm_name  = "phil-${local.common.locals.env_name}-cloudwatch-agent-config"
  bastion_security_group_id  = dependency.bastion.outputs.bastion_security_group_id
  is_agent                   = false



  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}