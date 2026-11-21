terraform {
  backend "s3" {
    # Populate via -backend-config flags or environment variables.
    # Example:
    #   terraform init \
    #     -backend-config="bucket=my-org-tfstate-prod" \
    #     -backend-config="key=platform/prod/terraform.tfstate" \
    #     -backend-config="region=us-east-1" \
    #     -backend-config="dynamodb_table=terraform-state-lock" \
    #     -backend-config="encrypt=true" \
    #     -backend-config="kms_key_id=alias/platform"
    encrypt = true
  }
}
