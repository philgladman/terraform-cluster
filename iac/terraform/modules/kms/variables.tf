variable "resource_name" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "create_key" {
  type = bool
  default = true
}

variable "description" {
  type = string
}

variable "key_usage" {
  type = string
  default = "ENCRYPT_DECRYPT"
}

variable "deletion_window_in_days" {
  type = string
  default = 7
}

variable "is_enabled" {
  type = bool
  default = true
}

variable "enable_key_rotation" {
  type = bool
  default = true
}

variable "multi_region" {
  type = bool
  default = false
}

variable "key_alias" {
  type = string
}

variable "kms_policy" {
  type = string
  default = ""
}

variable "attach_sns_kms_policy" {
  description = "Controls if KMS Policy for SNS should be created and attached to Key"
  type        = bool
  default     = true
}

variable "attach_cloudtrail_kms_policy" {
  description = "Controls if KMS Policy for Cloudtrail should be created and attached to Key"
  type        = bool
  default     = true
}

variable "attach_cloudwatch_kms_policy" {
  description = "Controls if KMS Policy for SNS should be created and attached to Key"
  type        = bool
  default     = true
}

variable "attach_s3_kms_policy" {
  description = "Controls if KMS Policy for SNS should be created and attached to Key"
  type        = bool
  default     = true
}
