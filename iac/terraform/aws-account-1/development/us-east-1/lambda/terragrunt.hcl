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
resource_name          = "phil-${local.common.locals.env_name}"
logging_level          = "INFO"
region                 = local.region.locals.region
/* sns_topic_arn          = dependencies.alerts.outputs.sns_topic_arnsns_topic_arn */
sns_topic_arn          = "arn:aws:sns:us-east-1:567243246807:phil-global-alerts"
sns_kms_key_arn        = "arn:aws:kms:us-east-1:567243246807:key/9dd69565-efcc-46ba-9fb9-a2001c778965"
cloudwatch_kms_key_arn = "arn:aws:kms:us-east-1:567243246807:key/fb451b06-0e1b-4be3-a217-ec219a0fe074"

  tags = {
    Environment  = "${local.common.locals.env_name}"
    Region       = "${local.region.locals.region}"
    Developer    = "${local.common.locals.developer}"
  }
}