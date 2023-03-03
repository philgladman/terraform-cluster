locals {
  uname                 = lower(var.resource_name)
}

# tfsec:ignore:enable-tracing
module "lambda_function" {
  source           = "terraform-aws-modules/lambda/aws"
  version          = "4.0.2"
   
  function_name    = "${local.uname}-k8s-deploy"
  description      = "Lambda function to run deploy.sh on clusters after the are spun back up"
  handler          = "k8s_deploy.lambda_handler"
  runtime          = "python3.8"
  source_path      = ["k8s_deploy/k8s_deploy.py"]
  create_role      = true 
  timeout          = "60"
  layers           = [aws_lambda_layer_version.paramiko_lambda_layer.arn,aws_lambda_layer_version.scp_lambda_layer.arn]
  publish          = true
  allowed_triggers = {
    S3Trigger = {
      #service    = "sns"
      principal  = "sns.amazonaws.com"
      source_arn = "${module.sns_topic.sns_topic_arn}"
    }
  }

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

resource "aws_lambda_layer_version" "scp_lambda_layer" {
  filename   = "k8s_deploy/scp-layer/layer.zip"
  layer_name = "${local.uname}-scp-layer"

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
          "${aws_ssm_parameter.github_username.arn}",
          "${aws_ssm_parameter.node_readiness_script.arn}"
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
  value       = var.github_username
  tags        = var.tags
}

resource "aws_ssm_parameter" "github_pat" {
  description = "github PAT"
  name        = "${local.uname}-github-pat"
  type        = "SecureString"
  value       = var.github_pat
  tags        = var.tags
}

resource "aws_ssm_parameter" "node_readiness_script" {
  description = "node readiness probe"
  name        = "${local.uname}-node-readiness"
  type        = "SecureString"
  value       = <<EOF
num_nodes_ready_succcess=4
num_nodes_ready=0

while [[ $num_nodes_ready -ne $num_nodes_ready_succcess ]]
do
	echo "$num_nodes_ready/4 nodes are ready" >> /tmp/node-readiness-output.txt
	sleep 2
	num_nodes_ready=$((num_nodes_ready+1))
done
EOF
  tags        = var.tags
}

# data "aws_iam_policy_document" "node_readiness_ssm_access_policy_doc" {
#   version = "2012-10-17"
#   statement {
#     effect  = "Allow"
#     actions = ["ssm:GetParameter"]
#     resources = [
#       "${aws_ssm_parameter.node_readiness_script.arn}"
#     ]
#   }
# }

# resource "aws_iam_policy" "node_readiness_ssm_access_policy" {
#   name        = "${local.uname}-node-readiness-ssm-access-policy"
#   path        = "/"
#   description = "SSM policy"
#   policy      = data.aws_iam_policy_document.node_readiness_ssm_access_policy_doc.json
# } 

# resource "aws_iam_role_policy_attachment" "node_readiness_ssm_attachment" {
#     role       = aws_iam_role.bastion-role.name
#     policy_arn = aws_iam_policy.bastion-ssm-access-policy.arn
# }

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"

  name              = "${local.uname}-lambda-sns-topic"
  display_name      = "${local.uname}-lambda-sns-topic"
  #kms_master_key_id = var.ebs_kms_key_id
  tags              = var.tags
}

resource "aws_sns_topic_subscription" "lambda_sns_subscription" {
  topic_arn = module.sns_topic.sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.lambda_function.lambda_function_arn
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloudtrail_s3_bucket" {
  bucket_prefix = "${local.uname}-cloudtrail-logging-bucket"
  tags          = var.tags
}

resource "aws_s3_bucket_policy" "cloudtrail_s3_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_s3_bucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.cloudtrail_s3_bucket.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.cloudtrail_s3_bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}




resource "aws_s3_bucket_public_access_block" "restrict_s3_bucket" {
  bucket                  = aws_s3_bucket.cloudtrail_s3_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "cloudwatch_role" {
name   = "${local.uname}-cloudwatch-role"
assume_role_policy = jsonencode(
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
    ]
  })
}

# tfsec:ignore:no-policy-wildcards
resource "aws_iam_policy" "iam_policy_for_cloudwatch_role" {
 
 name         = "${local.uname}-cloudwatch-access"
 path         = "/"
 description  = "AWS IAM Policy for cloudwatch"
 policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.cloudwatch_role.name
 policy_arn  = aws_iam_policy.iam_policy_for_cloudwatch_role.arn
}

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_log_group" {
  name       = "${local.uname}-lambda-log-group"
  #kms_key_id = var.ebs_kms_key_arn
  tags       = var.tags
}

resource "aws_cloudtrail" "s3-trigger-trail" {
  name                          = "${local.uname}-test-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_s3_bucket.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.lambda_cloudwatch_log_group.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudwatch_role.arn
  #kms_key_id                    = var.ebs_kms_key_arn
  tags                          = var.tags

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::test-bucket-phil-sully-gus/test.txt"]
    }
  }
}


resource "aws_cloudwatch_log_metric_filter" "lambda_metric_filter" {
  name           = "${local.uname}-test-metric-filter"
  pattern        = "{ ($.eventSource = s3.amazonaws.com)&&($.eventName = PutObject)&&($.requestParameters.bucketName = test-bucket-phil-sully-gus)&&($.requestParameters.key = test.txt) }"
  log_group_name = "${aws_cloudwatch_log_group.lambda_cloudwatch_log_group.name}"

  metric_transformation {
    name      = "S3TriggerEventCount"
    namespace = "${local.uname}testnamespace"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3-trigger-alarm" {
  alarm_name          = "${local.uname}-s3-trigger"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "S3TriggerEventCount"
  namespace           = "${local.uname}testnamespace"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors s3 bucket"
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
}
