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