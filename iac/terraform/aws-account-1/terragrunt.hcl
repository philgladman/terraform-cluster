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
    kms_key_id     = "arn:aws:kms:us-east-1:567243246807:key/a2fb33f9-e0f8-4eb7-ba29-052bc99c8fca"
    dynamodb_table = "phil-${local.aws_region}-test-tf-locks-gus-sully"
  }
}