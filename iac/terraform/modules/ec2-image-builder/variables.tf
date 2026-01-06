variable "resource_name" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(string)
}

variable "kms_key_alias" {
  type = string
}

################################################################################
# Key Pair
################################################################################

variable "private_key_algorithm" {
  description = "Name of the algorithm to use when generating the private key. Currently-supported values are `RSA` and `ED25519`"
  type        = string
  default     = "RSA"
}

variable "private_key_rsa_bits" {
  description = "When algorithm is `RSA`, the size of the generated RSA key, in bits (default: `4096`)"
  type        = number
  default     = 4096
}

################################################################################
# Image Builder
################################################################################

variable "private_subnet_id" {
  description = "The ID of the subnet to deploy the image builder in"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy the image builder in"
  type        = string
  default     = ""
}

variable "logging_s3_bucket_name" {
  description = "The name of the S3 Bucket to push logs to"
  type        = string
  default     = ""
}

variable "ami_name_prefix" {
  description = "AMI name prefix"
  type        = string
}

variable "source_ami_arch" {
  description = "AMI architecture"
  type        = string
}

variable "eks_version" {
  description = "EKS version"
  type        = string
}