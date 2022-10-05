locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}


include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../..//modules/bastion/"
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

inputs = {
  resource_name              = "phil-${local.common.locals.env_name}"
  bastion_ami                = "ami-06640050dc3f556bb"
  instance_type              = "t3.micro"
  bastion_subnet_id          = dependency.vpc.outputs.bastion_subnet_id
  master_ssh_key_name        = dependency.master-pem.outputs.master_ssh_key_name
  vpc_id                     = dependency.vpc.outputs.vpc_id
  ebs_kms_key_id             = dependency.sops.outputs.ebs_kms_key_id
  ebs_kms_key_arn            = dependency.sops.outputs.ebs_kms_key_arn
  region                     = local.region.locals.region
  cloudwatch_agent_ssm_name  = "phil-${local.common.locals.env_name}-cloudwatch-agent-config"


  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}