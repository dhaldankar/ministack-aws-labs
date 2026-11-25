#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
role_name=$(jq -er '.role_name.value | strings | select(length > 0)' <<< "$outputs")
role_arn=$(jq -er '.role_arn.value | strings | select(length > 0)' <<< "$outputs")

caller=$(aws --endpoint-url "$endpoint" sts get-caller-identity --no-cli-pager --query Arn --output text)
[[ $caller == arn:* ]] || { echo 'Expected a caller ARN.' >&2; exit 1; }
echo "PASS  STS caller identity: $caller"

role=$(aws --endpoint-url "$endpoint" iam get-role --role-name "$role_name" \
  --query 'Role.AssumeRolePolicyDocument' --output json --no-cli-pager)
[[ -n $role ]] || { echo 'Could not retrieve role trust policy.' >&2; exit 1; }
echo "PASS  Role trust policy retrieved for $role_name"

policy=$(aws --endpoint-url "$endpoint" iam get-role-policy \
  --role-name "$role_name" --policy-name lab-inline-policy \
  --query 'PolicyDocument' --output json --no-cli-pager)
inline_action=$(jq -er '.Statement[0].Action[0]' <<< "$policy")
[[ $inline_action == "s3:GetObject" ]] || { echo "Expected s3:GetObject in inline policy, got: $inline_action" >&2; exit 1; }
echo "PASS  Inline policy contains s3:GetObject"

[[ -f answers.txt ]] || { echo 'answers.txt not found. Save your answers before running the checker.' >&2; exit 1; }
echo "PASS  answers.txt present"
echo ""
echo "Role ARN:      $role_arn"
echo "Caller ARN:    $caller"
