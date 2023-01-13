##### Module to create a Cloudwatch Metric Filter and Alarm

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
