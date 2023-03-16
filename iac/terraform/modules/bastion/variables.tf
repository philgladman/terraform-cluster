variable "resource_name" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "bastion_subnet_id" {
  type = string
  default = ""
}

variable "master_ssh_key_name" {
  type = string
  default = ""
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "ebs_kms_key_id" {
  type = string
  default = ""
}

variable "ebs_kms_key_arn" {
  type = string
  default = ""
}

variable "region" {
  type        = string
  default     = ""
}

variable "bastion_ami" {
  type        = string
  default     = ""
}

variable "instance_type" {
  type        = string
  default     = ""
}

variable "master_key_ssm_name" {
  type        = string
  default     = ""
}

variable "log_group_name" {
  type        = string
  default     = ""
}

variable "log_retention_in_days" {
  type        = string
  default     = "30"
}

variable "metrics_namespace" {
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  type        = string
  default     = ""
}