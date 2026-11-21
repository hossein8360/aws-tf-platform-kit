variable "project" {
  description = "Project name, used as a resource name prefix."
  type        = string
}

variable "environment" {
  description = "Environment label (e.g. prod, staging)."
  type        = string
}

variable "aws_region" {
  description = "Target AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.1.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones."
  type        = number
  default     = 3
}

variable "state_bucket_name" {
  description = "Name of the existing S3 bucket used for Terraform state."
  type        = string
}

variable "state_lock_table" {
  description = "Name of the DynamoDB table used for state locking."
  type        = string
  default     = "terraform-state-lock"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB."
  type        = number
  default     = 512
}

variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions for Lambda. -1 for unreserved."
  type        = number
  default     = 10
}

variable "extra_tags" {
  description = "Additional tags merged into all resources."
  type        = map(string)
  default     = {}
}
