variable "resource_name" {
  description = "The name of your resource"
  type        = string
  default     = ""
}

variable "topic_name" {
  description = "The name of the SNS Topic"
  type        = string
  default     = ""
}

variable "region" {
  type = string
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  type        = map(string)
}

variable "emails" {
  description = "Map of tags to add to all resources created"
  type        = list(string)
  default     = []
}

variable "sns_kms_key_id" {
  description = "The ID for the KMS Key to encrpyt SNS"
  type        = string
  default     = ""
}

variable "trail_name" {
  description = "Cloudtrail trail name"
  type        = string
  default     = ""
}

variable "development_bastion_log_group_name" {
  description = "Development Bastions log group name"
  type        = string
}

variable "production_bastion_log_group_name" {
  description = "Production Bastions log group name"
  type        = string
}

variable "team_list" {
  description = "List of the team that should be allowed to Login to AWS, formatted in a Cloudwatch Metric Filter"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN for the KMS Key to use"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "The ID for the KMS Key to use"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "The Name of the lambda function"
  type        = string
  default     = ""
}

variable "lambda_function_arn" {
  description = "The ARN of the lambda function"
  type        = string
  default     = ""
}
