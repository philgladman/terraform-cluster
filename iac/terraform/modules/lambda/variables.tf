variable "resource_name" {
  type = string
}

variable "region" {
  description = "aws region"
  type = string
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  default     = {}
  type        = map(string)
}

variable "sns_topic_arn" {
  description = "ARN of SNS Topic to Publish Email"
  type = string
}
