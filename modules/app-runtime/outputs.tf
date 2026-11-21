output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.handler.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.handler.function_name
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function (for API Gateway integration)."
  value       = aws_lambda_function.handler.invoke_arn
}

output "processor_queue_url" {
  description = "URL of the main SQS processor queue."
  value       = aws_sqs_queue.processor.url
}

output "processor_queue_arn" {
  description = "ARN of the main SQS processor queue."
  value       = aws_sqs_queue.processor.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue."
  value       = aws_sqs_queue.dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue."
  value       = aws_sqs_queue.dlq.arn
}

output "log_group_name" {
  description = "Name of the Lambda CloudWatch log group."
  value       = aws_cloudwatch_log_group.lambda.name
}
