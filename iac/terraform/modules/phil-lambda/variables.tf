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