variable "name" {
  description = "Name prefix applied to all resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to use (creates one public + one private subnet per AZ)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 4
    error_message = "az_count must be between 1 and 4."
  }
}

variable "enable_nat_gateway" {
  description = "Create NAT Gateways for private subnet outbound access. Set false for local/cost-sensitive environments."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch log retention in days for VPC Flow Logs."
  type        = number
  default     = 30
}

variable "flow_logs_iam_role_arn" {
  description = "IAM role ARN for VPC Flow Logs delivery to CloudWatch. Required when enable_flow_logs = true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}
