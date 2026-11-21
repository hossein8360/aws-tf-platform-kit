variable "function_name" {
  description = "Name of the Lambda function (also used as prefix for related resources)."
  type        = string
}

variable "environment" {
  description = "Deployment environment label (e.g. local, staging, prod)."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role the Lambda function assumes at runtime."
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for SQS and CloudWatch log encryption. Leave empty to use SSE-SQS."
  type        = string
  default     = ""
}

variable "timeout" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900."
  }
}

variable "memory_size" {
  description = "Lambda function memory allocation in MB."
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions for the Lambda function. -1 means unreserved."
  type        = number
  default     = -1
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30
}

variable "log_level" {
  description = "Application log level passed as an environment variable."
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.log_level)
    error_message = "log_level must be one of DEBUG, INFO, WARNING, ERROR, CRITICAL."
  }
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for the heartbeat rule."
  type        = string
  default     = "rate(5 minutes)"
}

variable "subnet_ids" {
  description = "Subnet IDs when deploying Lambda inside a VPC."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs when deploying Lambda inside a VPC."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
