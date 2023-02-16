locals {
  uname  = lower(var.resource_name)
}

###
# Create S3 bucket for Cloudtrail
###

module "s3_key" {
  source  = "../common/kms"

  kms_description = "s3 kms key"
  kms_alias       = "${local.uname}-s3-key"
  tags            = var.tags
  kms_policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
POLICY
}

    /* {
      "Sid": "Allow_Cloudtrail",
      "Effect": "Allow",
      "Principal": {
        "Service":[
          "cloudtrail.amazonaws.com"
        ]
      },
      "Action": [
        "kms:DescribeKey",
        "kms:GenerateDataKey"
      ],
      "Resource": "*"
    } */

resource "random_password" "bucket_name_suffix" {
  length  = 5
  special = false
  upper   = false
}

resource "aws_s3_bucket" "cloudtrail_s3_bucket" {
  bucket = "${local.uname}-cloudtrail-logging-${random_password.bucket_name_suffix.result}"
  tags          = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_s3_bucket" {
  bucket = aws_s3_bucket.cloudtrail_s3_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.s3_key.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

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
      "Resource": "${aws_s3_bucket.cloudtrail_s3_bucket.arn}",
      "Condition": {
        "StringLike": {
          "AWS:SourceArn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/${local.uname}-${var.trail_name}"
        }
      }
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "${aws_s3_bucket.cloudtrail_s3_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "StringLike": {
          "AWS:SourceArn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/${local.uname}-${var.trail_name}"
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

###
# Create alerts sns topic
###

module "sns_key" {
  source  = "../common/kms"

  kms_description = "sns kms key"
  kms_alias       = "${local.uname}-sns-key"
  tags            = var.tags
  kms_policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow Cloudwatch to use key",
      "Effect": "Allow",
      "Principal": {
        "Service":[
          "cloudwatch.amazonaws.com"
        ]
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"

  name              = "${local.uname}-${var.topic_name}"
  display_name      = "${local.uname}-${var.topic_name}"
  create_sns_topic  = true
  fifo_topic        = false
  kms_master_key_id = module.sns_key.kms_key_id

  tags              = var.tags
}

resource "aws_sns_topic_subscription" "sns_topic_subscription" {
  count     = length(var.emails)
  topic_arn = module.sns_topic.sns_topic_arn
  protocol  = "email"
  endpoint  = var.emails[count.index]
}

###
# Create Cloudwatch Log Group
###

module "cloudwatch_key" {
  source  = "../common/kms"

  kms_description = "cloudwatch kms key"
  kms_alias       = "${local.uname}-cloudwatch-key"
  tags            = var.tags
  kms_policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow Cloudwatch to use key",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ],
      "Resource": "*",
      "Condition": {
        "ArnLike": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:*"
        }
      }
    }    
  ]
}
POLICY
}

###
# Create Cloudtrail Trail
###

module "cloudtrail_key" {
  source  = "../common/kms"

  kms_description = "cloudtrail kms key"
  kms_alias       = "${local.uname}-cloudtrail-key"
  tags            = var.tags
  kms_policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudTrail to encrypt logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:GenerateDataKey*",
      "Resource": "*",
      "Condition": {
        "ArnLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*",
          "AWS:SourceArn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
        }
      }
    },
    {
      "Sid": "Allow CloudTrail to describe key",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "kms:DescribeKey",
      "Resource": "*"
    },
    {
      "Sid": "Allow principals in the account to decrypt log files",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "kms:Decrypt",
        "kms:ReEncryptFrom"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}"
        },
        "StringLike": {
          "kms:EncryptionContext:aws:cloudtrail:arn": "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "cloudtrail_role" {
  name   = "${local.uname}-cloudtrail-role"
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
  tags = var.tags
}

resource "aws_iam_policy" "cloudtrail_role_policy" {
  name         = "${local.uname}-cloudtrail-access"
  path         = "/"
  description  = "Allow CloudTrail to send logs to CloudWatch Logs"
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
        "Resource": "${aws_cloudwatch_log_group.alerts_log_group.arn}:log-stream:*"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.cloudtrail_role.name
  policy_arn  = aws_iam_policy.cloudtrail_role_policy.arn
}

resource "aws_cloudwatch_log_group" "alerts_log_group" {
  name              = "${local.uname}-alerts-log-group"
  retention_in_days = 365
  kms_key_id        = module.cloudwatch_key.kms_key_arn
  tags              = var.tags
}

resource "aws_cloudtrail" "alerts_trail" {
  name                          = "${local.uname}-alerts-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_s3_bucket.id
  include_global_service_events = true
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.alerts_log_group.arn}:*"
  is_multi_region_trail         = true
  kms_key_id                    = module.cloudtrail_key.kms_key_arn
  tags                          = var.tags
}

###
# Create Cloudwatch Alarms & Metrics
###

## Without module

/* resource "aws_cloudwatch_log_metric_filter" "console_signon_failure_metric_filter" {
  name           = "${local.uname}-console-signon-failure"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-console-signon-failure-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_signon_failure_alarm" {
  alarm_name          = "${local.uname}-console-signon-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-console-signon-failure-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an unauthenticated API call is made to sign into the console."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
} */

## With new custom module 

module "security_group_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-security-group-changes"
  pattern                         = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to create, update or delete a Security Group."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-security-group-changes-counter"
  tags                            = var.tags
}

module "network_acl_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-network-acl-changes"
  pattern                         = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to create, update or delete a Network ACL."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-network-acl-changes-counter"
  tags                            = var.tags
}

module "gateway_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-gateway-changes"
  pattern                         = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to create, update or delete a Customer or Internet Gateway."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-gateway-changes-counter"
  tags                            = var.tags
}

module "ec2_instance_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-ec2-instance-changes"
  pattern                         = "{ ($.eventName = RunInstances) || ($.eventName = RebootInstances) || ($.eventName = StartInstances) || ($.eventName = StopInstances) || ($.eventName = TerminateInstances) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to create, terminate, start, stop or reboot an EC2 instance."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-ec2-instance-changes-counter"
  tags                            = var.tags
}

module "ec2_large_instance_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-ec2-large-instance-changes"
  pattern                         = "{ ($.eventName = RunInstances) && (($.requestParameters.instanceType = *.8xlarge) || ($.requestParameters.instanceType = *.4xlarge)) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to create, terminate, start, stop or reboot an EC2 instance."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-ec2-large-instance-changes-counter"
  tags                            = var.tags
}

module "cloudtrail_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-cloudtrail-changes"
  pattern                         = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to create, update or delete a CloudTrail trail, or to start or stop logging to a trail."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-cloudtrail-changes-counter"
  tags                            = var.tags
}

module "auth_failure" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-auth-failure"
  pattern                         = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an unauthorized API call is made."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-auth-failure-counter"
  tags                            = var.tags
}

module "iam_policy_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-iam-policy-changes"
  pattern                         = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to change an IAM policy."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-iam-policy-changes-counter"
  tags                            = var.tags
}

## Alarms for C1

module "cmk_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-cmk-changes"
  pattern                         = "{ ($.eventSource = kms.amazonaws.com)&&($.eventName = DisableKey)||($.eventName = ScheduleKeyDeletion) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to schedule the deletion of a CMK, or a CMK is disabled."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-cmk-changes-counter"
  tags                            = var.tags
}

module "user_group_changes" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-user-group-changes"
  pattern                         = "{ ($.eventName=CreateUser)||($.eventName=CreateGroup)||($.eventName=CreateAccessKey)||($.eventName=CreateLoginProfile)||($.eventName=DeleteUser)||($.eventName=DeleteGroup)||($.eventName=DeleteAccessKey)||($.eventName=DeleteLoginProfile) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made modify, create, or destroy iam user, group, or credentials."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-user-group-changes-counter"
  tags                            = var.tags
}

module "root_user_access" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-root-user-access"
  pattern                         = "{ ($.userIdentity.type = \"Root\") && ($.userIdentity.invokedBy NOT EXISTS) && ($.eventType != \"AwsServiceEvent\") }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made to with the ROOT User credentials"
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-root-user-access-counter"
  tags                            = var.tags
}

module "console_signon_failure" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-console-signon-failure"
  pattern                         = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an unauthenticated API call is made to sign into the console."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-console-signon-failure-counter"
  tags                            = var.tags
}

module "non_team_signin" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-non-team-signin"
  pattern                         = "{ ($.eventName = ConsoleLogin) && (($.userIdentity.userName != \"phil\") || ($.userIdentity.userName != \"terraform\"))}"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an someone outside of the Team signs into our AWS Account."
  alarm_actions                   = ["${module.sns_topic.sns_topic_arn}"]
  metric_transformation_name      = "${local.uname}-non-team-signin-counter"
  tags                            = var.tags
}
