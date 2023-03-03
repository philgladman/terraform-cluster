locals {
  uname                 = lower(var.resource_name)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "quarterly_email" {
  source = "terraform-aws-modules/lambda/aws"

  description   = "Lambda Function to go off each quarter to email ISSM"
  function_name = "${local.uname}-quarterly-email"
  create_role   = true
  handler       = "quarterly_email.lambda_handler"
  runtime       = "python3.9"
  timeout       = 180

  source_path = "${path.module}/files/quarterly_email"

  environment_variables = {
    LOGGING_LEVEL = "${var.logging_level}"
    REGION        = "${var.region}"
    SNS_TOPIC_ARN = "${var.sns_topic_arn}"
  }
}

# tfsec:ignore:no-policy-wildcards
resource "aws_iam_policy" "allow_sns" {

  name        = "${local.uname}-allow-sns-for-lambda"
  path        = "/"
  description = "AWS IAM Policy for lambda to send emails via sns"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "sns:Publish",
          ],
          "Resource" : "${var.sns_topic_arn}"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_quarterly_email_role" {
  role       = module.quarterly_email.lambda_role_name       
  policy_arn = aws_iam_policy.allow_sns.arn
}

resource "aws_cloudwatch_event_rule" "quarterly_cron" {
  name                = "${local.uname}-quarterly-cron"
  description         = "Cronjob to go off each quarter to email ISSM"
  schedule_expression = "cron(0 14 ? */3 4#2 *)"
  event_bus_name      = "default"
}

resource "aws_cloudwatch_event_target" "quarterly_email_target" {
  arn  = module.quarterly_email.lambda_function_arn
  rule = aws_cloudwatch_event_rule.quarterly_cron.name
}

resource "aws_lambda_permission" "allow_quarterly_cron" {
  statement_id  = "AllowExecutionFromQuartlyCron"
  action        = "lambda:InvokeFunction"
  function_name = module.quarterly_email.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.quarterly_cron.arn
}
