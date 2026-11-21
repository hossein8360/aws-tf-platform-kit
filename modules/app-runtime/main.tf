terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

locals {
  common_tags = merge(var.tags, { Module = "app-runtime" })
  handler_src = "${path.module}/src/handler.py"
}

# ── Lambda Package ────────────────────────────────────────────────────────────

data "archive_file" "handler" {
  type        = "zip"
  source_file = local.handler_src
  output_path = "${path.module}/src/handler.zip"
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.common_tags
}

# ── Code Signing (optional) ───────────────────────────────────────────────────

resource "aws_signer_signing_profile" "this" {
  count = var.enable_code_signing ? 1 : 0

  name_prefix = replace(var.function_name, "-", "_")
  platform_id = "AWSLambda-SHA384-ECDSA"

  signature_validity_period {
    value = 5
    type  = "YEARS"
  }

  tags = local.common_tags
}

resource "aws_lambda_code_signing_config" "this" {
  count = var.enable_code_signing ? 1 : 0

  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.this[0].version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }

  description = "${var.function_name} code signing"
}

# ── Lambda Function ───────────────────────────────────────────────────────────

resource "aws_lambda_function" "handler" {
  function_name = var.function_name
  description   = "Platform event handler"
  role          = var.execution_role_arn
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  timeout       = var.timeout
  memory_size   = var.memory_size

  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256

  reserved_concurrent_executions = var.reserved_concurrency

  kms_key_arn = var.kms_key_arn

  code_signing_config_arn = var.enable_code_signing ? aws_lambda_code_signing_config.this[0].arn : null

  environment {
    variables = {
      QUEUE_URL   = aws_sqs_queue.processor.url
      LOG_LEVEL   = var.log_level
      ENVIRONMENT = var.environment
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = merge(local.common_tags, { Name = var.function_name })
}

# ── SQS — Dead-Letter Queue ───────────────────────────────────────────────────

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.function_name}-dlq"
  message_retention_seconds = 1209600

  kms_master_key_id = var.kms_key_arn

  tags = merge(local.common_tags, { Name = "${var.function_name}-dlq" })
}

data "aws_iam_policy_document" "dlq" {
  statement {
    sid       = "AllowLambdaSend"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_lambda_function.handler.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id
  policy    = data.aws_iam_policy_document.dlq.json
}

# ── SQS — Main Processor Queue ────────────────────────────────────────────────

resource "aws_sqs_queue" "processor" {
  name                       = "${var.function_name}-processor"
  visibility_timeout_seconds = var.timeout * 6

  kms_master_key_id = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = merge(local.common_tags, { Name = "${var.function_name}-processor" })
}

data "aws_iam_policy_document" "processor_queue" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "processor" {
  queue_url = aws_sqs_queue.processor.id
  policy    = data.aws_iam_policy_document.processor_queue.json
}

# ── Lambda Event Source Mapping ───────────────────────────────────────────────

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn                   = aws_sqs_queue.processor.arn
  function_name                      = aws_lambda_function.handler.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  enabled                            = true

  function_response_types = ["ReportBatchItemFailures"]
}

# ── EventBridge Scheduled Rule ────────────────────────────────────────────────

resource "aws_cloudwatch_event_rule" "heartbeat" {
  name                = "${var.function_name}-heartbeat"
  description         = "Scheduled heartbeat for ${var.function_name}"
  schedule_expression = var.schedule_expression
  state               = "ENABLED"

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "heartbeat" {
  rule      = aws_cloudwatch_event_rule.heartbeat.name
  target_id = "lambda-heartbeat"
  arn       = aws_lambda_function.handler.arn

  input = jsonencode({ source = "heartbeat" })
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.heartbeat.arn
}
