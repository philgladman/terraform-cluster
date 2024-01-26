locals {
  region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  aws_region    = "${local.region.locals.region}"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "phil-account-2-${local.aws_region}-tfstate-backend"
    key            = format("%s/terraform.tfstate", path_relative_to_include())
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "phil-account-2-${local.aws_region}-table"
  }
}