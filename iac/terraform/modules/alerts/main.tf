locals {
  uname  = lower(var.resource_name)
}

###
# Create cloudtrail s3 bucket
###

/* resource "aws_kms_key" "s3_key" {
  description             = "s3 kms key"
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 10
  is_enabled              = true
  enable_key_rotation     = true
  multi_region            = false
  tags                    = var.tags
}

resource "aws_kms_alias" "s3_alias" {
  name          = "alias/${local.uname}-s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
} */

module "s3_key" {
  source  = "../common/kms"

  kms_description = "s3 kms key"
  kms_alias       = "${local.uname}-s3-key"
  tags            = var.tags
}

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
                "StringEquals": {
                    "AWS:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.uname}-${var.trail_name}"
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
                    "AWS:SourceArn": "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.uname}-${var.trail_name}",
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

###
# Create alerts sns topic
###

/* module "sns_key" {
  source  = "../common/kms"

  kms_description = "sns kms key"
  kms_alias       = "${local.uname}-sns-key"
  tags            = var.tags
} */

module "sns_topic" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 3.0"

  name              = "${local.uname}-${var.topic_name}"
  display_name      = "${local.uname}-${var.topic_name}"
  create_sns_topic  = true
  fifo_topic        = false
  # kms_master_key_id = var.sns_kms_key_id

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
  tags = var.tags
}

resource "aws_iam_policy" "cloudwatch_role_policy" {
  name         = "${local.uname}-cloudwatch-access"
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
  role        = aws_iam_role.cloudwatch_role.name
  policy_arn  = aws_iam_policy.cloudwatch_role_policy.arn
}

resource "aws_cloudwatch_log_group" "alerts_log_group" {
  name       = "${local.uname}-alerts-log-group"
  #kms_key_id = var.ebs_kms_key_arn
  tags       = var.tags
}

###
# Create Cloudtrail Trail
###

resource "aws_cloudtrail" "alerts_trail" {
  name                          = "${local.uname}-alerts-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_s3_bucket.id
  include_global_service_events = true
  enable_log_file_validation    = true
  cloud_watch_logs_role_arn     = aws_iam_role.cloudwatch_role.arn
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.alerts_log_group.arn}:*"
  is_multi_region_trail         = true
  tags                          = var.tags
}

###
# Create Cloudtrail Trail
###

resource "aws_cloudwatch_log_metric_filter" "console_signon_failure_metric_filter" {
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
}

resource "aws_cloudwatch_log_metric_filter" "security_group_changes_metric_filter" {
  name           = "${local.uname}-security-group-changes"
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-security-group-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes_alarm" {
  alarm_name          = "${local.uname}-security-group-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-security-group-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, update or delete a Security Group."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "network_acl_changes_metric_filter" {
  name           = "${local.uname}-network-acl-changes"
  pattern        = "{ ($.eventName = CreateNetworkAcl) || ($.eventName = CreateNetworkAclEntry) || ($.eventName = DeleteNetworkAcl) || ($.eventName = DeleteNetworkAclEntry) || ($.eventName = ReplaceNetworkAclEntry) || ($.eventName = ReplaceNetworkAclAssociation) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-network-acl-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_acl_changes_alarm" {
  alarm_name          = "${local.uname}-network-acl-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-network-acl-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, update or delete a Network ACL."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "gateway_changes_metric_filter" {
  name           = "${local.uname}-gateway-changes"
  pattern        = "{ ($.eventName = CreateCustomerGateway) || ($.eventName = DeleteCustomerGateway) || ($.eventName = AttachInternetGateway) || ($.eventName = CreateInternetGateway) || ($.eventName = DeleteInternetGateway) || ($.eventName = DetachInternetGateway) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-gateway-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "gateway_changes_alarm" {
  alarm_name          = "${local.uname}-gateway-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-gateway-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, update or delete a Customer or Internet Gateway."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "vpc_changes_metric_filter" {
  name           = "${local.uname}-vpc-changes"
  pattern        = "{ ($.eventName = CreateVpc) || ($.eventName = DeleteVpc) || ($.eventName = ModifyVpcAttribute) || ($.eventName = AcceptVpcPeeringConnection) || ($.eventName = CreateVpcPeeringConnection) || ($.eventName = DeleteVpcPeeringConnection) || ($.eventName = RejectVpcPeeringConnection) || ($.eventName = AttachClassicLinkVpc) || ($.eventName = DetachClassicLinkVpc) || ($.eventName = DisableVpcClassicLink) || ($.eventName = EnableVpcClassicLink) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-vpc-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc_changes_alarm" {
  alarm_name          = "${local.uname}-vpc-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-vpc-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, update or delete a VPC, VPC peering connection or VPC connection to classic."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "ec2_instance_changes_metric_filter" {
  name           = "${local.uname}-ec2-instance-changes"
  pattern        = "{ ($.eventName = RunInstances) || ($.eventName = RebootInstances) || ($.eventName = StartInstances) || ($.eventName = StopInstances) || ($.eventName = TerminateInstances) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-ec2-instance-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_instance_changes_alarm" {
  alarm_name          = "${local.uname}-ec2-instance-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-ec2-instance-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, terminate, start, stop or reboot an EC2 instance."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "ec2_large_instance_changes_metric_filter" {
  name           = "${local.uname}-ec2-large-instance-changes"
  pattern        = "{ ($.eventName = RunInstances) && (($.requestParameters.instanceType = *.8xlarge) || ($.requestParameters.instanceType = *.4xlarge)) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-ec2-large-instance-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_large_instance_changes_alarm" {
  alarm_name          = "${local.uname}-ec2-large-instance-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-ec2-large-instance-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, terminate, start, stop or reboot a 4x or 8x-large EC2 instance."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_changes_metric_filter" {
  name           = "${local.uname}-cloudtrail-changes"
  pattern        = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-cloudtrail-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_changes_alarm" {
  alarm_name          = "${local.uname}-cloudtrail-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-cloudtrail-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to create, update or delete a CloudTrail trail, or to start or stop logging to a trail."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "auth_failure_metric_filter" {
  name           = "${local.uname}-auth-failure"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-auth-failure-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "auth_failure_alarm" {
  alarm_name          = "${local.uname}-auth-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-auth-failure-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an unauthorized API call is made."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes_metric_filter" {
  name           = "${local.uname}-iam-policy-changes"
  pattern        = "{ ($.eventName = DeleteGroupPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutUserPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-iam-policy-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes_alarm" {
  alarm_name          = "${local.uname}-iam-policy-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-iam-policy-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to change an IAM policy."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "cmk_changes_metric_filter" {
  name           = "${local.uname}-cmk-changes"
  pattern        = "{ ($.eventSource = kms.amazonaws.com)&&($.eventName = DisableKey)||($.eventName = ScheduleKeyDeletion)||($.eventName = PutKeyPolicy) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-cmk-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cmk_changes_alarm" {
  alarm_name          = "${local.uname}-cmk-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-cmk-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made to schedule the deletion of a CMK, or a CMK is disabled."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

resource "aws_cloudwatch_log_metric_filter" "user_group_changes_metric_filter" {
  name           = "${local.uname}-user-group-changes"
  pattern        = "{ ($.eventName=AddUserToGroup)||($.eventName=AttachUserPolicy)||($.eventName=ChangePassword)||($.eventName=CreateAccessKey)||($.eventName=CreateGroup)||($.eventName=CreateLoginProfile)||($.eventName=CreateRole)||($.eventName=alerts)||($.eventName=DeactivateMFADevice)||($.eventName=DeleteAccessKey)||($.eventName=DeleteAccountPasswordPolicy)||($.eventName=DeleteGroup)||($.eventName=DeleteGroupPolicy)||($.eventName=DeleteLoginProfile)||($.eventName=DeleteUser)||($.eventName=DeleteUserPolicy)||($.eventName=DeleteUserPermissionsBoundary)||($.eventName=DeleteVirtualMFADevice)||($.eventName=DetachGroupPolicy)||($.eventName=DetachRolePolicy)||($.eventName=DetachUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutUserPolicy)||($.eventName=PutUserPermissionsBoundary)||($.eventName=RemoveUserFromGroup)||($.eventName=UntagUser)||($.eventName=UpdateAccessKey)||($.eventName=UpdateAccountPasswordPolicy)||($.eventName=UpdateGroup)||($.eventName=UpdateLoginProfile)||($.eventName=UpdateServiceSpecificCredential) }"
  log_group_name = "${aws_cloudwatch_log_group.alerts_log_group.name}"

  metric_transformation {
    name      = "${local.uname}-user-group-changes-counter"
    namespace = "${local.uname}-cloudtrail-metrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "user_group_changes_alarm" {
  alarm_name          = "${local.uname}-user-group-changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "${local.uname}-user-group-changes-counter"
  namespace           = "${local.uname}-cloudtrail-metrics"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Alarms when an API call is made modify, create, or destroy iam user, group, or credentials."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
}

##### Test out custom module
## Shortens code by 12 lines

module "cloudwatch_metric_filter_and_alarm" {
  source  = "./metrics-and-alarms"

  name                            = "${local.uname}-test-changes"
  pattern                         = "{ ($.eventName=AddUserToGroup)||($.eventName=AttachUserPolicy)||($.eventName=ChangePassword)||($.eventName=CreateAccessKey)||($.eventName=CreateGroup)||($.eventName=CreateLoginProfile)||($.eventName=CreateRole)||($.eventName=alerts)||($.eventName=DeactivateMFADevice)||($.eventName=DeleteAccessKey)||($.eventName=DeleteAccountPasswordPolicy)||($.eventName=DeleteGroup)||($.eventName=DeleteGroupPolicy)||($.eventName=DeleteLoginProfile)||($.eventName=DeleteUser)||($.eventName=DeleteUserPolicy)||($.eventName=DeleteUserPermissionsBoundary)||($.eventName=DeleteVirtualMFADevice)||($.eventName=DetachGroupPolicy)||($.eventName=DetachRolePolicy)||($.eventName=DetachUserPolicy)||($.eventName=PutGroupPolicy)||($.eventName=PutUserPolicy)||($.eventName=PutUserPermissionsBoundary)||($.eventName=RemoveUserFromGroup)||($.eventName=UntagUser)||($.eventName=UpdateAccessKey)||($.eventName=UpdateAccountPasswordPolicy)||($.eventName=UpdateGroup)||($.eventName=UpdateLoginProfile)||($.eventName=UpdateServiceSpecificCredential) }"
  log_group_name                  = "${aws_cloudwatch_log_group.alerts_log_group.name}"
  metric_transformation_namespace = "${local.uname}-cloudtrail-metrics"
  alarm_description               = "Alarms when an API call is made modify, create, or destroy iam user, group, or credentials."
  metric_transformation_name      = "${local.uname}-test-changes-counter"
  tags                            = var.tags
}
