output "vpc_id" {
  description = "VPC ID provisioned in LocalStack."
  value       = module.networking.vpc_id
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.app_runtime.lambda_function_name
}

output "processor_queue_url" {
  description = "URL of the SQS processor queue."
  value       = module.app_runtime.processor_queue_url
}

output "state_bucket" {
  description = "Name of the Terraform state S3 bucket."
  value       = module.storage_state.bucket_id
}

output "kms_key_id" {
  description = "ID of the platform KMS CMK."
  value       = module.security_iam.kms_key_id
}
