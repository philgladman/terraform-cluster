variable "resource_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "create_key" {
  type = bool
}

variable "description" {
  type = string
}

variable "key_usage" {
  type = string
}

variable "deletion_window_in_days" {
  type = string
}

variable "is_enabled" {
  type = bool
}

variable "enable_key_rotation" {
  type = bool
}

variable "multi_region" {
  type = bool
}

variable "key_alias" {
  type = string
}

variable "attach_policy" {
  description = "Controls if KMS key should have policy attached (set to `true` to use value of `policy` as kms policy)"
  type        = bool
}

variable "kms_policy" {
  type = string
}

variable "attach_sns_kms_policy" {
  description = "Controls if KMS Policy for SNS should be created and attached to Key"
  type        = bool
}

variable "attach_cloudtrail_kms_policy" {
  description = "Controls if KMS Policy for Cloudtrail should be created and attached to Key"
  type        = bool
}

variable "attach_cloudwatch_kms_policy" {
  description = "Controls if KMS Policy for Cloudwatch should be created and attached to Key"
  type        = bool
}

variable "attach_iam_kms_policy" {
  description = "Controls if KMS Policy for IAM should be created and attached to Key"
  type        = bool
}
