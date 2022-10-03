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
    bucket         = "phil-${local.aws_region}-test-tfstate-backend-gus-sully"
    key            = format("%s/terraform.tfstate", path_relative_to_include())
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "phil-${local.aws_region}-test-tf-locks-gus-sully"
  }
}