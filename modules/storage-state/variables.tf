variable "bucket_name" {
  description = "Globally unique name for the Terraform state S3 bucket."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table used for state locking."
  type        = string
  default     = "terraform-state-lock"
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used for S3 SSE-KMS. Leave empty to use AES-256."
  type        = string
  default     = ""
}

variable "noncurrent_version_expiration_days" {
  description = "Days after which noncurrent S3 object versions are deleted."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Allow destroying the bucket even when non-empty. Use only for ephemeral environments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "enable_lifecycle" {
  description = "Enable S3 bucket lifecycle rules"
  type        = bool
  default     = true
}
