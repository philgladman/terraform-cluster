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

variable "tail_name" {
  description = "Cloudtrail trail name"
  type        = string
  default     = ""
}