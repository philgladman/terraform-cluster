/* locals {
  uname  = lower(var.resource_name)
} */

resource "aws_ses_email_identity" "example" {
  count = length(var.emails)
  email = var.emails[count.index]
}

resource "aws_route53_zone" "main" {
  name = var.domain
}

module "ses" {
  source  = "cloudposse/ses/aws"
  version = "0.22.3"

  domain            = var.domain
  zone_id           = var.zone_id
  ses_user_enabled  = false
  ses_group_enabled = false
  verify_dkim       = true
  verify_domain     = true
}

/* module "ses_iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.3.1"

  name          = "${local.uname}-ses-send-raw-email"
  create_policy = true
  tags          = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["ses:SendRawEmail"]
        Effect = "Allow"
        Resource = ["*"]
      },
    ]
  })
}

resource "aws_ssm_parameter" "ses_username" {
  description = "AWS SES username"
  name        = "${local.uname}-ses-username"
  type        = "SecureString"
  value       = ""
}

resource "aws_ssm_parameter" "ses_password" {
  description = "AWS SES password"
  name        = "${local.uname}-ses-username"
  type        = "SecureString"
  value       = ""
} */
