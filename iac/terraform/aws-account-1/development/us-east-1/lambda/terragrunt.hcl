locals {
  common          = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region          = read_terragrunt_config(find_in_parent_folders("region.hcl"))
}

terraform {
    source = "../../../..//modules/lambda"
}

include {
    path = find_in_parent_folders()
}


dependency "master-pem" {
  config_path = "..//master-pem"
}

dependency "sops" {
  config_path = "..//sops"
}

/* dependency "alerts" {
  config_path = "..//alerts"
} */

# enumerate all the Terragrunt modules that need to be applied in order for this module to be able to apply
dependencies {
  paths = [
    "..//master-pem",
    "..//sops",
    /* "..//alerts" */
  ]
}

inputs = {
resource_name = "phil-${local.common.locals.env_name}"
region        = local.region.locals.region
/* sns_topic_arn = dependencies.alerts.outputs.sns_topic_arnsns_topic_arn */
sns_topic_arn = "arn:aws:sns:us-east-1:567243246807:Test-SNS-Topic"

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}