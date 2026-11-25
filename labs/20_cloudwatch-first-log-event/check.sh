#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
group=$(terraform output -raw group)
jq -e '(.request_id | type == "string" and startswith("request-")) and .level == "INFO"' log-event.json >/dev/null
expected=$(jq -cS . log-event.json)
for attempt in {1..8}; do
  if aws_lab logs filter-log-events --log-group-name "$group" --log-stream-names orders |
    jq -e --argjson event "$expected" 'any(.events[]?; (.message | fromjson?) == $event)' >/dev/null; then
    echo "Found $expected in $group / orders."
    exit 0
  fi
  sleep 2
done
echo "The recorded request was not found in the orders stream." >&2
exit 1
