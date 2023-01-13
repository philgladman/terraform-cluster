
resource "aws_cloudwatch_log_metric_filter" "this" {
  name           = var.name
  pattern        = var.pattern
  log_group_name = var.log_group_name

  metric_transformation {
    name          = var.metric_transformation_name
    namespace     = var.metric_transformation_namespace
    value         = var.metric_transformation_value
    default_value = var.metric_transformation_default_value
    unit          = var.metric_transformation_unit
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.name
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_transformation_name
  namespace           = var.metric_transformation_namespace
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = var.alarm_description
  alarm_actions       = var.alarm_actions
  tags                = var.tags
}



/* ###################

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
  period              = var.period
  statistic           = var.statistic
  threshold           = var.threshold
  alarm_description   = "Alarms when an API call is made modify, create, or destroy iam user, group, or credentials."
  alarm_actions       = ["${module.sns_topic.sns_topic_arn}"]
  tags                = var.tags
} */
