module "security_iam" {
  source = "../../modules/security-iam"

  name           = "${var.project}-${var.environment}"
  lambda_in_vpc  = true
  sqs_queue_arns = [module.app_runtime.processor_queue_arn]

  tags = var.extra_tags
}

module "storage_state" {
  source = "../../modules/storage-state"

  bucket_name         = var.state_bucket_name
  dynamodb_table_name = var.state_lock_table
  kms_key_arn         = module.security_iam.kms_key_arn
  force_destroy       = false

  tags = var.extra_tags
}

module "networking" {
  source = "../../modules/networking"

  name                     = "${var.project}-${var.environment}"
  vpc_cidr                 = var.vpc_cidr
  az_count                 = var.az_count
  enable_nat_gateway       = true
  enable_flow_logs         = true
  flow_logs_iam_role_arn   = module.security_iam.flow_logs_role_arn
  kms_key_arn              = module.security_iam.kms_key_arn
  flow_logs_retention_days = 365

  tags = var.extra_tags
}

module "app_runtime" {
  source = "../../modules/app-runtime"

  function_name        = "${var.project}-handler"
  environment          = var.environment
  execution_role_arn   = module.security_iam.lambda_exec_role_arn
  kms_key_arn          = module.security_iam.kms_key_arn
  reserved_concurrency = var.lambda_reserved_concurrency
  memory_size          = var.lambda_memory_size
  timeout              = var.lambda_timeout
  log_retention_days   = 365
  enable_code_signing  = true
  subnet_ids           = module.networking.private_subnet_ids
  security_group_ids   = []

  tags = var.extra_tags
}
