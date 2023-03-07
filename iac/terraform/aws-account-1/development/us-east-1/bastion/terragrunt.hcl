locals {
  common        = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  name          = "phil-${local.common.locals.env_name}"
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

# enumerate all the Terragrunt modules that need to be applied in order for this module to be able to apply
dependencies {
  paths = [
    "..//vpc",
    "..//master-pem",
    "..//sops"
  ]
}

inputs = {
  resource_name              = "phil-${local.common.locals.env_name}"
  bastion_ami                = "ami-06640050dc3f556bb"
  instance_type              = "t3.micro"
  bastion_subnet_id          = dependency.vpc.outputs.bastion_subnet_id
  master_ssh_key_name        = dependency.master-pem.outputs.master_ssh_key_name
  master_key_ssm_name        = dependency.master-pem.outputs.master_key_ssm_name
  vpc_id                     = dependency.vpc.outputs.vpc_id
  ebs_kms_key_id             = dependency.sops.outputs.ebs_kms_key_id
  ebs_kms_key_arn            = dependency.sops.outputs.ebs_kms_key_arn
  region                     = local.region.locals.region
  metrics_namespace          = "CloudWatch-Agent-Metrics"
  log_group_name             = "/aws/ec2/${local.name}/bastion"
  log_retention_in_days      = "90"

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}