#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
type=${1:-OrderCreated}
id=${2:-manual-$(date +%s)}
entries=$(jq -nc --arg bus "$(terraform output -raw bus)" --arg type "$type" --arg id "$id" \
  '[{EventBusName:$bus,Source:"lab.orders",DetailType:$type,Detail:({order_id:$id}|tojson)}]')
aws_lab events put-events --entries "$entries" | jq -e 'select(.FailedEntryCount == 0)'
