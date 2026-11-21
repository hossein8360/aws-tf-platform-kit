#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="${LOCALSTACK_ENDPOINT:-http://localhost:4566}"
REGION="${AWS_DEFAULT_REGION:-us-east-1}"
AWS_ARGS=(--endpoint-url "${ENDPOINT}" --region "${REGION}" --output text)

pass=0
fail=0

check() {
  local name="$1"
  local cmd="$2"
  if eval "${cmd}" &>/dev/null; then
    echo "  [PASS] ${name}"
    (( pass++ )) || true
  else
    echo "  [FAIL] ${name}"
    (( fail++ )) || true
  fi
}

section() {
  echo ""
  echo "── ${1} ──"
}

section "LocalStack connectivity"
check "health endpoint" "curl -sf ${ENDPOINT}/_localstack/health"

section "S3 — state bucket"
STATE_BUCKET=$(aws s3api list-buckets "${AWS_ARGS[@]}" \
  --query 'Buckets[?contains(Name, `tfstate`)].Name' 2>/dev/null | tr '\t' '\n' | head -1)
check "state bucket exists"      "[[ -n '${STATE_BUCKET}' ]]"
check "versioning enabled"       \
  "aws s3api get-bucket-versioning \"${AWS_ARGS[@]}\" --bucket \"${STATE_BUCKET}\" | grep -q Enabled"

section "DynamoDB — lock table"
check "lock table exists" \
  "aws dynamodb describe-table \"${AWS_ARGS[@]}\" --table-name terraform-state-lock"

section "IAM — Lambda execution role"
check "lambda exec role exists" \
  "aws iam get-role \"${AWS_ARGS[@]}\" --role-name lambda-exec-role"

section "SQS — queues"
check "processor queue exists" \
  "aws sqs list-queues \"${AWS_ARGS[@]}\" | grep -q processor"
check "dead-letter queue exists" \
  "aws sqs list-queues \"${AWS_ARGS[@]}\" | grep -q dlq"

section "Lambda — function"
check "handler function exists" \
  "aws lambda list-functions \"${AWS_ARGS[@]}\" | grep -q platform-handler"

section "EC2 / Networking"
check "VPC exists" \
  "aws ec2 describe-vpcs \"${AWS_ARGS[@]}\" --filters 'Name=tag:Name,Values=platform-vpc' | grep -q vpc-"

echo ""
echo "Results: ${pass} passed, ${fail} failed"
if (( fail > 0 )); then
  exit 1
fi
