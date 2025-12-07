variable "resource_name" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "rke2_subnet_ids" {
  type = list(string)
}

variable "master_ssh_key_name" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "ebs_kms_key_id" {
  type    = string
  default = ""
}

variable "ebs_kms_key_arn" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = ""
}

variable "cloudwatch_agent_ssm_name" {
  type    = string
  default = ""
}

variable "source_ami" {
  type    = string
  default = ""
}

variable "agent_instance_type" {
  type    = string
  default = ""
}

variable "bastion_security_group_id" {
  default = ""
}

variable "controlplane_security_group_id" {
  default = ""
}

variable "is_agent" {
  type        = bool
  default     = null
  description = "true for an agent, and false for controlplane"
}

variable "token_bucket_id" {
  type    = string
  default = ""
}

variable "token_bucket_arn" {
  type    = string
  default = ""
}

variable "token_object_id" {
  type    = string
  default = ""
}

variable "wait_for_capacity_timeout" {
  description = "How long Terraform should wait for ASG instances to be healthy before timing out."
  type        = string
  default     = "10m"
}

variable "spot" {
  default = false
  type    = bool
}

variable "instance_refresh" {
  description = "If this block is configured, start an Instance Refresh when this Auto Scaling Group is updated"
  type        = any
  default     = {}
}