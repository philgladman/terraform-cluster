variable "resource_name" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "bastion_security_group_id" {
  default = ""
}

variable "private_subnet_ids" {
  type = list(string)
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

variable "ami" {
  type        = string
  default     = ""
}

variable "instance_type" {
  type        = string
  default     = ""
}

variable "eks_admin_role_arn" {
  type        = string
  default     = ""
}
