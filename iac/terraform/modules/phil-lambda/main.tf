locals {
  uname                 = lower(var.resource_name)
}

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

resource "aws_lambda_layer_version" "paramiko_lambda_layer" {
  filename   = "k8s_deploy/paramiko-layer/layer.zip"
  layer_name = "${local.uname}-paramiko-layer"

  compatible_runtimes = ["python3.8"]
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
        "Resource": [
          "${var.master_private_key_ssm_parameter_arn}",
          "${aws_ssm_parameter.github_pat.arn}",
          "${aws_ssm_parameter.github_username.arn}"
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
  value       = "YOUR_USERNAME"
}

resource "aws_ssm_parameter" "github_pat" {
  description = "github PAT"
  name        = "${local.uname}-github-pat"
  type        = "SecureString"
  value       = "YOUR_PAT"
}