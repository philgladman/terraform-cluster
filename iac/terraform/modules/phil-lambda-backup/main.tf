locals {
  uname                 = lower(var.resource_name)
}

#resource "aws_cloudwatch_event_rule" "k8s_deploy_trigger" {
#  name                = "${local.uname}k8s-deploy-trigger"
#  description         = "Run deploy.sh after clusters spin back up"
#  schedule_expression = "cron(0 10 ? * 2-6 *)"
#}
#
#resource "aws_cloudwatch_event_target" "k8s_target_target" {
#  arn  = module.lambda_function.lambda_function_arn
#  rule = aws_cloudwatch_event_rule.k8s_deploy_trigger.name
#}
#
#resource "aws_lambda_permission" "allow_cloudwatch_to_call_k8s_deploy" {
#  statement_id  = "AllowExecutionFromCloudWatch"
#  action        = "lambda:InvokeFunction"
#  function_name = module.lambda_function.lambda_function_name
#  principal     = "events.amazonaws.com"
#  source_arn    = aws_cloudwatch_event_rule.k8s_deploy_trigger.arn
#}

###### k8s_deploy resources

# tfsec:ignore:enable-tracing
module "lambda_function" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "4.0.2"

  function_name = "${local.uname}-k8s-deploy"
  description   = "Lambda function to run deploy.sh on clusters after the are spun back up"
  handler       = "k8s_deploy.lambda_handler"
  runtime       = "python3.8"
  source_path   = "files/k8s_deploy"
  role_name     = aws_iam_role.k8s_deploy_lambda_role.name
  timeout       = "15"
  environment_variables = {
    AWS_REGION = "${var.region}"
  }

  tags          = merge({
    "Name" = "${local.uname}-k8s-deploy",
    }, var.tags)
}

resource "aws_iam_role" "k8s_deploy_lambda_role" {
name               = "${local.uname}-k8s-deploy-lambda-role"
assume_role_policy = jsonencode(
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
    ]
  })
  tags          = merge({
    "Name" = "${local.uname}-k8s-deploy",
    }, var.tags)
}

# tfsec:ignore:no-policy-wildcards
resource "aws_iam_policy" "k8s_deploy_iam_policy" {
 
 name         = "${local.uname}-k8s-deploy-iam-policy"
 path         = "/"
 description  = "Policy to allow k8s_deploy lambda function to access AWS Resource"
 policy       = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter"
          ],
        "Resource": "arn:aws:ssm:us-east-1:310951227237:parameter/raft-tcode-il2-mgmt-cloudwatch-agent-config"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*"
      }
    ]
  })
  tags          = merge({
    "Name" = "${local.uname}-k8s-deploy",
    }, var.tags)
}

resource "aws_iam_role_policy_attachment" "k8s_deploy_policy_attachment" {
 role        = aws_iam_role.k8s_deploy_lambda_role.name
 policy_arn  = aws_iam_policy.k8s_deploy_iam_policy.arn
}
