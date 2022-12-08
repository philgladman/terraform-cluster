
variable "domain" {
  description = "The domain to create the SES identity for."
  type        = string
}

variable "zone_id" {
  type        = string
  description = "Route53 parent zone ID. If provided (not empty), the module will create Route53 DNS records used for verification"
}

variable "verify_domain" {
  type        = bool
  description = "If provided the module will create Route53 DNS records used for domain verification."
  default     = true
}

variable "verify_dkim" {
  type        = bool
  description = "If provided the module will create Route53 DNS records used for DKIM verification."
  default     = true
}

variable "tags" {
  description = "Map of tags to add to all resources created"
  type        = map(string)
}

variable "emails" {
  description = "email to add as a verified identity"
  type        = list(string)
  default     = []
}
