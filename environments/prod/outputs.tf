output "vpc_id" {
  description = "VPC ID."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.networking.private_subnet_ids
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.app_runtime.lambda_function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = module.app_runtime.lambda_function_arn
}

output "processor_queue_url" {
  description = "URL of the SQS processor queue."
  value       = module.app_runtime.processor_queue_url
}

output "kms_key_id" {
  description = "ID of the platform KMS CMK."
  value       = module.security_iam.kms_key_id
}

output "state_bucket" {
  description = "Name of the Terraform state S3 bucket."
  value       = module.storage_state.bucket_id
}
