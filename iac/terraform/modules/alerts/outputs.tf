/* output "aws_cloudwatch_log_group" {
  value = try(aws_cloudwatch_log_group.alerts_log_group.arn, "")
} */
output "sns_topic_arn" {
  value = try(module.sns_topic.topic_arn, "")
}