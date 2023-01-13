variable "kms_description" {
  type = string
  default = ""
}

variable "kms_alias" {
  type = string
  default = ""
}

variable "kms_policy" {
  type = string
  default = ""
}

variable "tags" {
  type = map(string)
}