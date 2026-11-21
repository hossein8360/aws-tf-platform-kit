terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack provider — no real credentials required
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = var.localstack_endpoint
    iam      = var.localstack_endpoint
    kms      = var.localstack_endpoint
    lambda   = var.localstack_endpoint
    sqs      = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    ec2      = var.localstack_endpoint
    logs     = var.localstack_endpoint
    sts      = var.localstack_endpoint
    events   = var.localstack_endpoint
  }
}
