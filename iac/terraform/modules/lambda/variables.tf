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

variable "logging_level" {
  description = "Level to set python logger at"
  type = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS Topic to Publish Email"
  type = string
}

# variable "sns_kms_key_arn" {
#   description = "The Key ARN of the KMS Key for the SNS Topic"
#   type        = string
#   default     = ""
# }

# variable "cloudwatch_kms_key_arn" {
#   description = "ARN of Cloudwatch KMS Key"
#   type = string
# }

variable "kms_key_arn" {
  description = "The ARN of the KMS Key"
  type        = string
  default     = ""
}
