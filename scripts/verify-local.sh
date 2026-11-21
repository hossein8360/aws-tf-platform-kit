#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"

# Use native aws CLI if available, otherwise fall back to amazon/aws-cli in Docker.
awslocal() {
  if command -v aws > /dev/null 2>&1; then
    aws --endpoint-url="${ENDPOINT}" --region "${REGION}" --output text "$@"
  else
    docker run --rm --network host \
      -e AWS_ACCESS_KEY_ID=test \
      -e AWS_SECRET_ACCESS_KEY=test \
      -e AWS_DEFAULT_REGION="${REGION}" \
      amazon/aws-cli --endpoint-url="${ENDPOINT}" --output text "$@"
  fi
}

pass=0
fail=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "${cmd}" > /dev/null 2>&1; then
    printf '  [PASS] %s\n' "${name}"
    (( pass++ )) || true
  else
    printf '  [FAIL] %s\n' "${name}"
    (( fail++ )) || true
  fi
}

section() {
  printf '\n── %s ──\n' "${1}"
}

section "LocalStack connectivity"
check "health endpoint" "curl -sf ${ENDPOINT}/_localstack/health"

section "S3 — state bucket"
STATE_BUCKET=$(awslocal s3api list-buckets \
  --query 'Buckets[?contains(Name, `tfstate`)].Name' 2> /dev/null \
  | tr '\t' '\n' | head -1 || true)
check "state bucket exists"  "[[ -n '${STATE_BUCKET}' ]]"
check "versioning enabled" \
  "awslocal s3api get-bucket-versioning --bucket '${STATE_BUCKET}' | grep -q Enabled"

section "DynamoDB — lock table"
check "lock table exists" \
  "awslocal dynamodb describe-table --table-name terraform-state-lock"

section "IAM — Lambda execution role"
check "lambda exec role exists" \
  "awslocal iam get-role --role-name platform-local-lambda-exec"

section "SQS — queues"
check "processor queue exists" \
  "awslocal sqs list-queues | grep -q processor"
check "dead-letter queue exists" \
  "awslocal sqs list-queues | grep -q dlq"

section "Lambda — function"
check "handler function exists" \
  "awslocal lambda list-functions | grep -q platform-handler"

section "EC2 / Networking"
check "VPC exists" \
  "awslocal ec2 describe-vpcs --filters 'Name=tag:Name,Values=platform-local' | grep -q vpc-"

printf '\nResults: %d passed, %d failed\n' "${pass}" "${fail}"
if (( fail > 0 )); then
  exit 1
fi
