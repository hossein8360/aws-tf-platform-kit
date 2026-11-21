module "security_iam" {
  source = "../../modules/security-iam"

  name           = "${var.project}-${var.environment}"
  lambda_in_vpc  = false
  sqs_queue_arns = [module.app_runtime.processor_queue_arn]

  tags = local.common_tags
}

module "storage_state" {
  source = "../../modules/storage-state"

  bucket_name   = "${var.project}-tfstate-${var.environment}"
  force_destroy = true
  kms_key_arn   = module.security_iam.kms_key_arn

  tags = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  name               = "${var.project}-${var.environment}"
  vpc_cidr           = var.vpc_cidr
  az_count           = 2
  enable_nat_gateway = false
  enable_flow_logs   = false

  tags = local.common_tags
}

module "app_runtime" {
  source = "../../modules/app-runtime"

  function_name      = "${var.project}-handler"
  environment        = var.environment
  execution_role_arn = module.security_iam.lambda_exec_role_arn
  kms_key_arn        = module.security_iam.kms_key_arn
  log_level          = "DEBUG"
  reserved_concurrency = -1

  tags = local.common_tags
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
