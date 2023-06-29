variable "resource_name" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "ebs_kms_key" {
  type = string
  default = ""
}

variable "endpoints" {
  type        = list(string)
  default     = []
}

variable "cidr" {
  type = string
  default = ""
}
