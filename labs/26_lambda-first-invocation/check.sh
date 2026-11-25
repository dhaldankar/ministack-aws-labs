#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
bash invoke.sh file://valid.json "$tmp/body" | jq -e '.StatusCode == 200 and (.FunctionError | not)' >/dev/null
jq -e '. == {processed:"ORD-001"}' "$tmp/body" >/dev/null
bash invoke.sh file://invalid.json "$tmp/body" | jq -e '.StatusCode == 200 and (.FunctionError | not)' >/dev/null
jq -e '. == {error:"order_id is required"}' "$tmp/body" >/dev/null
echo "Valid input was processed and missing input returned a handled error."
