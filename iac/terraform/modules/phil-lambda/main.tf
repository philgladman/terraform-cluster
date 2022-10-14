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
  source_path   = ["k8s_deploy/k8s_deploy.py"]
  create_role   = true 
  timeout       = "15"
  layers        = [aws_lambda_layer_version.paramiko_lambda_layer.arn]

  environment_variables = {
    aws_region = "${var.region}"
  }

  tags          = merge({
    "Name" = "${local.uname}-k8s-deploy",
    }, var.tags)
}

# module "lambda_layer_s3" {
#   source = "terraform-aws-modules/lambda/aws"

#   create_layer = true

#   layer_name          = "paramiko-layer-terraform-s3"
#   description         = "My amazing lambda layer (deployed from S3)"
#   compatible_runtimes = ["python3.8"]

#   source_path = "k8s_deploy/paramiko-layer/layer.zip"

#   store_on_s3 = true
#   s3_bucket   = "test-bucket-phil-sully-gus"
# }
resource "aws_lambda_layer_version" "paramiko_lambda_layer" {
  filename   = "k8s_deploy/paramiko-layer/layer.zip"
  layer_name = "paramiko-layer-terraform-3"

  compatible_runtimes = ["python3.8"]
}

# resource "aws_lambda_function" "k8s_deploy" {
#   filename        = "${path.module}/files/my-deployment-package.zip"
#   function_name   = "k8s_deploy"
#   role            = aws_iam_role.k8s_deploy_lambda_role.arn
#   handler         = "k8s_deploy.lambda_handler"
#   runtime         = "python3.8"
#   depends_on      = [aws_iam_role_policy_attachment.k8s_deploy_policy_attachment]
#   # layers          = [aws_lambda_layer_version.paramiko_lambda_layer.arn]
# }

# resource "aws_iam_role" "k8s_deploy_lambda_role" {
# name               = "${local.uname}-k8s-deploy-lambda-role"
# assume_role_policy = jsonencode(
#   {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#     ]
#   })
#   tags          = merge({
#     "Name" = "${local.uname}-k8s-deploy",
#     }, var.tags)
# }

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
        "Resource": [
          "arn:aws:ssm:us-east-1:567243246807:parameter/phil-dev-master-key-private",
          "arn:aws:ssm:us-east-1:567243246807:parameter/phil-dev-github-username",
          "arn:aws:ssm:us-east-1:567243246807:parameter/phil-dev-github-pat"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeInstances"
          ],
        "Resource": "*"
      }
    ]
  })
  tags          = merge({
    "Name" = "${local.uname}-k8s-deploy",
    }, var.tags)
}

resource "aws_iam_role_policy_attachment" "k8s_deploy_policy_attachment" {
 role        = module.lambda_function.lambda_role_name
 policy_arn  = aws_iam_policy.k8s_deploy_iam_policy.arn
}

resource "aws_ssm_parameter" "github_username" {
  description = "github username"
  name        = "${local.uname}-github-username"
  type        = "SecureString"
  value       = "CHANGE-WITH-YOUR-USERNAME"
}

resource "aws_ssm_parameter" "github_pat" {
  description = "github PAT"
  name        = "${local.uname}-github-pat"
  type        = "SecureString"
  value       = "CHANGE-WITH-YOUR-PAT"
}