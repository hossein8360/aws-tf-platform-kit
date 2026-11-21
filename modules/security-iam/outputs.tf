output "kms_key_arn" {
  description = "ARN of the platform KMS CMK."
  value       = aws_kms_key.platform.arn
}

output "kms_key_id" {
  description = "Key ID of the platform KMS CMK."
  value       = aws_kms_key.platform.key_id
}

output "kms_alias_arn" {
  description = "ARN of the platform KMS alias."
  value       = aws_kms_alias.platform.arn
}

output "lambda_exec_role_arn" {
  description = "ARN of the Lambda execution IAM role."
  value       = aws_iam_role.lambda_exec.arn
}

output "lambda_exec_role_name" {
  description = "Name of the Lambda execution IAM role."
  value       = aws_iam_role.lambda_exec.name
}

output "flow_logs_role_arn" {
  description = "ARN of the VPC Flow Logs IAM role."
  value       = aws_iam_role.flow_logs.arn
}
