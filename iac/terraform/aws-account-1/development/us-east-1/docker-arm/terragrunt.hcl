locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  name          = "phil-${local.common.locals.env_name}"
}


include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/docker-arm/"
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
  docker_arm_ami             = "ami-03a45a5ac837f33b7"
  instance_type              = "c6g.medium"
  docker_arm_subnet_id       = dependency.vpc.outputs.bastion_subnet_id
  docker_arm_sg              = dependency.bastion.outputs.bastion_security_group_id
  master_ssh_key_name        = dependency.master-pem.outputs.master_ssh_key_name
  master_key_ssm_name        = dependency.master-pem.outputs.master_key_ssm_name
  vpc_id                     = dependency.vpc.outputs.vpc_id
  ebs_kms_key_id             = dependency.sops.outputs.ebs_kms_key_id
  ebs_kms_key_arn            = dependency.sops.outputs.ebs_kms_key_arn
  region                     = local.region.locals.region

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}