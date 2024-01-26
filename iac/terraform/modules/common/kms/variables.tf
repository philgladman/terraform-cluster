variable "resource_name" {
  type = string
  default = ""
}

variable "key_name" {
  description = "Alias of the key"
  type = string
}

variable "tags" {
  type = map(string)
}

variable "description" {
  type = string
}

variable "key_usage" {
  type = string
  default = "ENCRYPT_DECRYPT"
}

variable "create_key" {
  type = bool
  default = true
}

variable "attach_policy" {
  description = "Controls if KMS key should have policy attached (set to `true` to use value of `policy` as kms policy)"
  type        = bool
  default     = false
}

variable "policy" {
  description = "(Optional) A valid KMS policy JSON document. Note that if the policy document is not specific enough (but still valid), Terraform may view the policy as constantly changing in a terraform plan. In this case, please make sure you use the verbose/specific version of the policy. For more information about building AWS IAM policy documents with Terraform, see the AWS IAM Policy Document Guide."
  type        = string
  default     = null
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
  description = "Controls if KMS Policy for Cloudwatch should be created and attached to Key"
  type        = bool
  default     = true
}

variable "attach_iam_kms_policy" {
  description = "Controls if KMS Policy for IAM should be created and attached to Key"
  type        = bool
  default     = true
}
