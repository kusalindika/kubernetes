variable "name_prefix" {
  description = "Prefix used for naming resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, stage, prod)."
  type        = string
}

variable "region" {
  description = "AWS region for the VPC deployment."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "Availability Zones used for subnets."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs. Must align 1:1 with azs."
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs must have the same length as azs."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs. Must align 1:1 with azs."
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs must have the same length as azs."
  }
}

variable "enable_vpc_endpoints" {
  description = "Whether to create baseline VPC endpoints."
  type        = bool
  default     = true
}
