variable "resource_name" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "docker_arm_subnet_id" {
  type    = string
  default = ""
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

variable "docker_arm_ami" {
  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = ""
}

variable "master_key_ssm_name" {
  type    = string
  default = ""
}

variable "docker_arm_sg" {
  type    = string
  default = ""
}

variable "docker_arm_role" {
  type    = string
  default = ""
}