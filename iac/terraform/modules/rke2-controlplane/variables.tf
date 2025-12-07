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

variable "controlplane_instance_type" {
  type    = string
  default = ""
}

variable "bastion_security_group_id" {
  default = ""
}

variable "is_agent" {
  type        = bool
  default     = null
  description = "true for an agent, and false for controlplane"
}