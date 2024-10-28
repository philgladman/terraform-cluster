locals {
  uname                 = lower(var.resource_name)
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

################################################################################
# Lambda Layers
################################################################################

module "jmespath_layer" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "lambda-layer-jmespath"
  description         = "Lambda layer for python jmespath module"
  compatible_runtimes = ["python3.9"]

  source_path = "${path.module}/files/layers/jmespath_layer.zip"
}

################################################################################
# Lambda to send quarterly Emails
################################################################################

module "quarterly_email" {
  source = "terraform-aws-modules/lambda/aws"

  description                       = "Lambda Function to go off each quarter to email ISSM"
  function_name                     = "${local.uname}-quarterly-email"
  create_role                       = true
  handler                           = "quarterly_email.lambda_handler"
  runtime                           = "python3.9"
  timeout                           = 180
  source_path                       = "${path.module}/files/quarterly_email"
  cloudwatch_logs_retention_in_days = 90
  cloudwatch_logs_kms_key_id        = var.kms_key_arn

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
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:ReEncrypt*",
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:DescribeKey",
            "kms:Decrypt"
          ],
          "Resource" : "${var.kms_key_arn}"
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

################################################################################
# Lambda to stop all EC2 Instances every night
################################################################################

module "stop_ec2" {
  source = "terraform-aws-modules/lambda/aws"

  description                       = "Lambda Function to go off every night to Stop All EC2 Instances"
  function_name                     = "${local.uname}-stop-ec2"
  create_role                       = true
  handler                           = "stop_ec2.lambda_handler"
  runtime                           = "python3.9"
  timeout                           = 180
  layers                            = [module.jmespath_layer.lambda_layer_arn]
  cloudwatch_logs_retention_in_days = 90
  cloudwatch_logs_kms_key_id        = var.kms_key_arn

  source_path = "${path.module}/files/stop_ec2"

  environment_variables = {
    LOGGING_LEVEL = "${var.logging_level}"
    REGION        = "${var.region}"
  }
}

# tfsec:ignore:no-policy-wildcards
resource "aws_iam_policy" "allow_stop_ec2" {

  name        = "${local.uname}-allow-stop-stop-ec2"
  path        = "/"
  description = "AWS IAM Policy for lambda to stop EC2 Instances"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:StopInstances",
            "ec2:DescribeInstances",
          ],
          "Resource" : "*"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_stop_ec2_role" {
  role       = module.stop_ec2.lambda_role_name       
  policy_arn = aws_iam_policy.allow_stop_ec2.arn
}

resource "aws_cloudwatch_event_rule" "stop_ec2" {
  name                = "${local.uname}-stop-ec2"
  description         = "Cronjob to go off every Night at 9:30pm EST"
  schedule_expression = "cron(30 2 * * ? *)"
  event_bus_name      = "default"
}

resource "aws_cloudwatch_event_target" "stop_ec2_target" {
  arn  = module.stop_ec2.lambda_function_arn
  rule = aws_cloudwatch_event_rule.stop_ec2.name
}

resource "aws_lambda_permission" "allow_stop_ec2_cron" {
  statement_id  = "AllowExecutionFromStopEC2Cron"
  action        = "lambda:InvokeFunction"
  function_name = module.stop_ec2.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_ec2.arn
}

################################################################################
# Lambda to delete old unused EBS Alarms
################################################################################

module "ebs_alarm_cleanup" {
  source = "terraform-aws-modules/lambda/aws"

  description                       = "Lambda Function to go off every Monday and Thursday to Delete all old and unused EBS Alarms"
  function_name                     = "${local.uname}-ebs-alarm-cleanup"
  create_role                       = true
  handler                           = "ebs_alarm_cleanup.lambda_handler"
  runtime                           = "python3.9"
  timeout                           = 180
  layers                            = [module.jmespath_layer.lambda_layer_arn]
  cloudwatch_logs_retention_in_days = 90
  cloudwatch_logs_kms_key_id        = var.kms_key_arn

  source_path = "${path.module}/files/ebs_alarm_cleanup"

  environment_variables = {
    LOGGING_LEVEL = "${var.logging_level}"
    REGION        = "${var.region}"
  }
}

# tfsec:ignore:no-policy-wildcards
resource "aws_iam_policy" "allow_ebs_alarm_cleanup" {

  name        = "${local.uname}-allow-ebs-alarm-cleanup"
  path        = "/"
  description = "AWS IAM Policy for lambda Delete Cloudwatch Alarms"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudwatch:DeleteAlarms",
            "cloudwatch:DescribeAlarms",
          ],
          "Resource" : "*"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_ebs_alarm_cleanup_role" {
  role       = module.ebs_alarm_cleanup.lambda_role_name       
  policy_arn = aws_iam_policy.allow_ebs_alarm_cleanup.arn
}

resource "aws_cloudwatch_event_rule" "ebs_alarm_cleanup" {
  name                = "${local.uname}-ebs-alarm-cleanup"
  description         = "Cronjob to go off every Monday and Thursday at 10:00am EST"
  schedule_expression = "cron(0 14 ? * 2,5 *)"
  event_bus_name      = "default"
}

resource "aws_cloudwatch_event_target" "ebs_alarm_cleanup_target" {
  arn  = module.ebs_alarm_cleanup.lambda_function_arn
  rule = aws_cloudwatch_event_rule.ebs_alarm_cleanup.name
}

resource "aws_lambda_permission" "allow_ebs_alarm_cleanup_cron" {
  statement_id  = "AllowExecutionFromEbsAlarmCleanupCron"
  action        = "lambda:InvokeFunction"
  function_name = module.ebs_alarm_cleanup.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ebs_alarm_cleanup.arn
}

################################################################################
# Lambda to send an email alert when non team member signs into AWS Account
################################################################################
/* 
module "nonteam_signin_alarm" {
  source = "terraform-aws-modules/lambda/aws"

  description                       = "Lambda Function send an email alert when non team member signs into AWS Account"
  function_name                     = "${local.uname}-nonteam-signin-alarm"
  create_role                       = true
  handler                           = "nonteam_signin_alarm.lambda_handler"
  runtime                           = "python3.9"
  timeout                           = 180

  cloudwatch_logs_retention_in_days = 365
  cloudwatch_logs_kms_key_id        = var.kms_key_arn

  source_path = "${path.module}/files/nonteam_signin_alarm"

  vpc_subnet_ids         = var.vpc_subnet_ids
  vpc_security_group_ids = [aws_security_group.lambda_sg.id]

  environment_variables = {
    LOGGING_LEVEL        = "${var.logging_level}"
    REGION               = "${var.region}"
    SNS_TOPIC_ARN        = "${var.sns_topic_arn}"
    AUTHORIZED_TEAM_LIST = "${var.authorized_team_list}"
  }
}

# tfsec:ignore:no-policy-wildcards
resource "aws_iam_policy" "nonteam_signin_alarm" {

  name        = "${local.uname}-nonteam-signin-alarm"
  path        = "/"
  description = "AWS IAM Policy for lambda to send emails via sns and to query cloudtrail"
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
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:ReEncrypt*",
            "kms:GenerateDataKey",
            "kms:Encrypt",
            "kms:DescribeKey",
            "kms:Decrypt"
          ],
          "Resource" : "${var.kms_key_arn}"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudtrail:LookupEvents",
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:AssignPrivateIpAddresses",
            "ec2:UnassignPrivateIpAddresses"
          ],
          "Resource" : "*"
        }
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_nonteam_signin_alarm_role" {
  role       = module.nonteam_signin_alarm.lambda_role_name       
  policy_arn = aws_iam_policy.nonteam_signin_alarm.arn
}

resource "aws_cloudwatch_event_rule" "nonteam_signin_alarm_rule" {
  name                = "${local.uname}-nonteam-signin-alarm-rule"
  description         = "This rule is used to trigger the nonteam-signin-alarm lambda function"
  event_pattern       = jsonencode({
    "source": ["aws.cloudwatch"],
    "detail-type": ["CloudWatch Alarm State Change"],
    "resources": ["arn:aws-us-gov:cloudwatch:${var.region}:${data.aws_caller_identity.current.id}:alarm:${local.uname}-non-team-signin"],
    "detail": {
      "alarmName": ["${local.uname}-non-team-signin"],
      "previousState": {
        "value": ["INSUFFICIENT_DATA", "OK"]
      },
      "state": {
        "value": ["ALARM"]
      }
    }
  })
  event_bus_name      = "default"
}

resource "aws_cloudwatch_event_target" "nonteam_signin_alarm_target" {
  arn  = module.nonteam_signin_alarm.lambda_function_arn
  rule = aws_cloudwatch_event_rule.nonteam_signin_alarm_rule.name
}

resource "aws_lambda_permission" "allow_nonteam_signin_alarm_rule" {
  statement_id  = "AllowExecutionFromNonteamSigningAlarm"
  action        = "lambda:InvokeFunction"
  function_name = module.nonteam_signin_alarm.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nonteam_signin_alarm_rule.arn
} */

################################################################################
# Lambda Function to send notifications when Cloudwatch Alarms are triggered
################################################################################

module "cloudwatch_alarms_notification" {
  source = "terraform-aws-modules/lambda/aws"

  description                       = "Lambda Function to print out the CW Alarm details that triggered this function"
  function_name                     = "${local.uname}-cloudwatch-alarms-notification"
  create_role                       = true
  handler                           = "cloudwatch_alarms_notification.lambda_handler"
  runtime                           = "python3.9"
  timeout                           = 180
  source_path                       = "${path.module}/files/cloudwatch_alarms_notification"
  cloudwatch_logs_retention_in_days = 90
  cloudwatch_logs_kms_key_id        = var.kms_key_arn

  environment_variables = {
    LOGGING_LEVEL = "${var.logging_level}"
    REGION        = "${var.region}"
    SNS_TOPIC_ARN = "${var.sns_topic_arn}"
    AWS_PARTITION = "${data.aws_partition.current.partition}"
  }
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_cloudwatch_alarms_notification_role" {
  role       = module.cloudwatch_alarms_notification.lambda_role_name       
  policy_arn = aws_iam_policy.allow_sns.arn
}
