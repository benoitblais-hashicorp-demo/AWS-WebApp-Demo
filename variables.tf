variable "admin_laptop_ip" {
  description = "(Optional) Public IP of your local laptop allowed to connect directly to the EC2 and RDS instances for demo verification. Needs /32 suffix."
  type        = string
  default     = "" # Replace with your IP e.g. "123.45.67.89/32"
}

variable "aws_region" {
  description = "(Optional) The AWS region to deploy resources into."
  type        = string
  default     = "ca-central-1"
}

variable "private_hosted_zone" {
  description = "(Optional) Private Route53 Hosted Zone domain name used for internal DNS records."
  type        = string
  default     = "benoit-blais.sbx.hashidemos.local"
}

variable "public_hosted_zone" {
  description = "(Optional) Public Route53 Hosted Zone domain name for ACM certificates and external DNS."
  type        = string
  default     = "benoit-blais.sbx.hashidemos.io"
}

variable "vpc_cidr" {
  description = "(Optional) The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}
