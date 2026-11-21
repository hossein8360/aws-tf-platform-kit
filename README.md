# aws-tf-platform-kit

A production-grade, modular Terraform repository for provisioning a hardened, multi-tier AWS platform. Supports 100% free local development and integration testing against [LocalStack Community](https://localstack.cloud/).

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS / LocalStack                        │
│                                                             │
│  ┌────────────┐   ┌────────────┐   ┌────────────────────┐  │
│  │ networking │   │security-iam│   │   storage-state    │  │
│  │            │   │            │   │                    │  │
│  │  VPC + IGW │   │ IAM roles  │   │  S3 + DynamoDB     │  │
│  │  Subnets   │   │ policies   │   │  (TF state backend)│  │
│  │  NACLs     │   │ KMS key    │   │                    │  │
│  │  Flow Logs │   │            │   └────────────────────┘  │
│  └────────────┘   └────────────┘                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   app-runtime                       │   │
│  │                                                     │   │
│  │   Lambda (Python 3.12)  +  SQS  +  EventBridge     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Modules

| Module | Purpose |
|---|---|
| `networking` | VPC, public/private subnets, IGW, NAT, NACLs, VPC Flow Logs |
| `security-iam` | IAM roles, least-privilege policies, KMS CMK |
| `storage-state` | S3 state bucket (versioned, encrypted, MFA-delete), DynamoDB lock table |
| `app-runtime` | Lambda function, SQS queue (DLQ), EventBridge scheduled rule |

## Prerequisites

| Tool | Version |
|---|---|
| Terraform | >= 1.6.0 |
| Docker + Docker Compose | >= 24 |
| Python | >= 3.10 |
| checkov | >= 3 |
| tflint | >= 0.50 |
| AWS CLI | >= 2 (for prod) |

## Quick Start — Local (LocalStack)

```bash
# Start LocalStack
make localstack-up

# Initialise and apply the local environment
make local-init
make local-apply

# Verify all resources
make verify

# Tear down
make local-destroy
make localstack-down
```

## Quick Start — Production

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## CI / CD

- **GitHub Actions**: `.github/workflows/terraform.yml` — lint → validate → checkov → plan on every PR; apply on `main`.
- **GitLab CI**: `.gitlab-ci.yml` — equivalent pipeline for GitLab.

## Makefile Targets

```
make help            Show all targets
make localstack-up   Start LocalStack via Docker Compose
make localstack-down Stop LocalStack
make local-init      terraform init (local env)
make local-plan      terraform plan  (local env)
make local-apply     terraform apply (local env, auto-approve)
make local-destroy   terraform destroy (local env, auto-approve)
make fmt             terraform fmt -recursive
make validate        terraform validate (all envs)
make lint            tflint --recursive
make scan            checkov -d . --config-file .checkov.yaml
make verify          Run scripts/verify-local.sh
make clean           Remove .terraform dirs and cached plans
```

## Security Posture

- **Encryption at rest**: KMS CMK for S3, SQS, Lambda env vars; AES-256 DynamoDB.
- **Encryption in transit**: HTTPS-only S3 bucket policy; TLS enforced on SQS.
- **Least privilege**: scoped IAM roles per service; no wildcard `*` actions in production policies.
- **Network isolation**: private subnets for compute; NACLs restrict cross-tier traffic; VPC Flow Logs to S3.
- **State hardening**: versioning + MFA-delete on state bucket; DynamoDB lock with TTL.
- **Static analysis**: every PR blocked on `checkov` and `tflint` with zero high/critical findings.

## Repository Layout

```
aws-tf-platform-kit/
├── Makefile
├── docker-compose.yml
├── .gitignore
├── .tflint.hcl
├── .checkov.yaml
├── README.md
├── docs/images/
├── scripts/verify-local.sh
├── modules/
│   ├── networking/
│   ├── security-iam/
│   ├── storage-state/
│   └── app-runtime/
├── environments/
│   ├── local/
│   └── prod/
├── .github/workflows/terraform.yml
└── .gitlab-ci.yml
```

## License

MIT
