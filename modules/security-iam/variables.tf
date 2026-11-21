variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
}

variable "kms_deletion_window" {
  description = "Number of days before KMS key deletion (7–30)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "kms_deletion_window must be between 7 and 30."
  }
}

variable "sqs_queue_arns" {
  description = "List of SQS queue ARNs the Lambda execution role may consume."
  type        = list(string)
  default     = []
}

variable "lambda_in_vpc" {
  description = "Attach the AWSLambdaVPCAccessExecutionRole managed policy to the Lambda role."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
