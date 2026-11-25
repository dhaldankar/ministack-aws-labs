#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
run=${1:?Supply a run ID}
queue=$(terraform output -raw source_url)
for type in healthy poison; do
  body=$(jq -c --arg id "$run-$type" '.job_id = $id' "$type.json")
  aws_lab sqs send-message --queue-url "$queue" --message-body "$body" >/dev/null
done
