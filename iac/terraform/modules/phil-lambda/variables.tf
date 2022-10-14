variable "resource_name" {
  type = string
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  default     = {}
  type        = map(string)
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "master_private_key_ssm_parameter_arn" {
  type        = string
  default     = ""
}