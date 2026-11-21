.DEFAULT_GOAL := help
SHELL         := /bin/bash

TF_LOCAL  := environments/local
TF_PROD   := environments/prod
MODULES   := modules/networking modules/security-iam modules/storage-state modules/app-runtime

# LocalStack endpoint used by verify script
export AWS_DEFAULT_REGION  ?= us-east-1
export AWS_ACCESS_KEY_ID   ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export LOCALSTACK_ENDPOINT ?= http://localhost:4566

##@ LocalStack

.PHONY: localstack-up
localstack-up: ## Start LocalStack
	docker compose up -d localstack
	@echo "Waiting for LocalStack to be healthy..."
	@until curl -sf http://localhost:4566/_localstack/health | grep -q '"s3": "available"'; do \
		sleep 2; \
	done
	@echo "LocalStack is ready."

.PHONY: localstack-down
localstack-down: ## Stop and remove LocalStack containers
	docker compose down -v

##@ Terraform – Local

.PHONY: local-init
local-init: ## terraform init for local environment
	terraform -chdir=$(TF_LOCAL) init -reconfigure

.PHONY: local-plan
local-plan: ## terraform plan for local environment
	terraform -chdir=$(TF_LOCAL) plan -out=$(TF_LOCAL)/tfplan

.PHONY: local-apply
local-apply: ## terraform apply for local environment (auto-approve)
	terraform -chdir=$(TF_LOCAL) apply -auto-approve

.PHONY: local-destroy
local-destroy: ## terraform destroy for local environment (auto-approve)
	terraform -chdir=$(TF_LOCAL) destroy -auto-approve

##@ Terraform – Prod

.PHONY: prod-init
prod-init: ## terraform init for prod environment
	terraform -chdir=$(TF_PROD) init

.PHONY: prod-plan
prod-plan: ## terraform plan for prod environment
	terraform -chdir=$(TF_PROD) plan -out=$(TF_PROD)/tfplan

##@ Quality Gates

.PHONY: fmt
fmt: ## Format all HCL files in-place
	terraform fmt -recursive .

.PHONY: fmt-check
fmt-check: ## Check formatting without writing
	terraform fmt -check -recursive .

.PHONY: validate
validate: ## Validate all Terraform configurations
	@for dir in $(TF_LOCAL) $(MODULES); do \
		echo "→ validating $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false -no-color > /dev/null; \
		terraform -chdir=$$dir validate; \
	done

.PHONY: lint
lint: ## Run tflint on all modules and environments
	@for dir in $(TF_LOCAL) $(MODULES); do \
		echo "→ tflint $$dir"; \
		tflint --chdir=$$dir; \
	done

.PHONY: scan
scan: ## Run checkov static analysis
	checkov -d . --config-file .checkov.yaml

.PHONY: verify
verify: ## Run end-to-end local verification script
	bash scripts/verify-local.sh

##@ Housekeeping

.PHONY: clean
clean: ## Remove cached Terraform artifacts
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "tfplan" -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true

.PHONY: help
help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} \
	/^[a-zA-Z_-]+:.*##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
	/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)
