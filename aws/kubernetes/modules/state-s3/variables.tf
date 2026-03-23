
variable "aws_region" {
  description = "AWS region where the state bucket is created."
  type        = string
}

variable "environment" {
  description = "Environment name used for bucket naming (for example: dev, stage, prod)."
  type        = string
}

variable "bucket_name_override" {
  description = "Optional explicit bucket name. If unset, a name is derived from environment."
  type        = string
  default     = null
}
