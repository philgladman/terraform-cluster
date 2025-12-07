locals {
  uname = lower(var.resource_name)
}

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"

  name              = "${local.uname}-${var.topic_name}"
  display_name      = "${local.uname}-${var.topic_name}"
  create_sns_topic  = true
  fifo_topic        = false
  kms_master_key_id = var.sns_kms_key_id

  tags = var.tags
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  count     = length(var.emails)
  topic_arn = module.sns_topic.sns_topic_arn
  protocol  = "email"
  endpoint  = var.emails[count.index]
}
