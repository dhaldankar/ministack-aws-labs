#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
wait_for_log() {
  local needle=$1 message
  for attempt in {1..20}; do
    if message=$(aws_lab logs filter-log-events --log-group-name "$(terraform output -raw log_group)" \
      --filter-pattern "\"$needle\"" | jq -er --arg needle "$needle" 'first(.events[]?.message | select(contains($needle)))'); then
      printf '%s\n' "$message"
      return 0
    fi
    sleep 3
  done
  echo "No log entry found for $needle." >&2
  return 1
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
function=$(terraform output -raw function)
probe="lambda-$(date +%s)-$$"
payload=$(jq -nc --arg probe "$probe" '{order_id:"fixture-001",probe:$probe}')
result=$(bash invoke.sh "$payload" "$tmp/body")
if [[ ${1:-} == baseline ]]; then
  jq -e '.FunctionError != null' <<<"$result" >/dev/null
  jq -e '.errorMessage | contains("TABLE_NAME")' "$tmp/body" >/dev/null
  wait_for_log "$probe" | grep -F 'missing TABLE_NAME'
  printf '%s\n' "$function" > baseline.function
  exit 0
fi
[[ $(cat baseline.function) == "$function" ]]
jq -e '.StatusCode == 200 and (.FunctionError | not)' <<<"$result" >/dev/null
jq -e '. == {order_id:"fixture-001",status:"paid"}' "$tmp/body" >/dev/null
table=$(terraform output -raw table)
aws_lab lambda get-function-configuration --function-name "$function" |
  jq -e --arg table "$table" '.Environment.Variables.TABLE_NAME == $table' >/dev/null
role=$(aws_lab lambda get-function-configuration --function-name "$function" | jq -er '.Role | split("/") | last')
arn=$(aws_lab dynamodb describe-table --table-name "$table" | jq -er '.Table.TableArn')
aws_lab iam get-role-policy --role-name "$role" --policy-name function-access |
  jq -e --arg arn "$arn" 'any(.PolicyDocument.Statement[]; .Effect == "Allow" and .Action == ["dynamodb:GetItem"] and .Resource == $arn)' >/dev/null
wait_for_log "$probe" | grep -F 'order=fixture-001 found=True'
