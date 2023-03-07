output "sns_topic_arn" {
  value = try(module.sns_topic.sns_topic_arn, "")
}
