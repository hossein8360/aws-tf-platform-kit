variable "project" {
  description = "Project name, used as a resource name prefix."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment label."
  type        = string
  default     = "local"
}

variable "aws_region" {
  description = "AWS region (passed to the LocalStack provider)."
  type        = string
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  description = "LocalStack API endpoint URL."
  type        = string
  default     = "http://localhost:4566"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}
