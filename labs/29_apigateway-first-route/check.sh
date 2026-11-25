#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
base=$(bash api-url.sh)
api=$(terraform output -raw api_id)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
get() { curl -sS --max-time 10 -o "$tmp/body" -w '%{http_code}' "$base$1"; }
routes=$(aws_lab apigatewayv2 get-routes --api-id "$api")

jq -e 'any(.Items[]; .RouteKey == "GET /health")' <<<"$routes" >/dev/null
[[ $(get /health) == 200 ]]
jq -e '. == {status:"ok",service:"orders"}' "$tmp/body" >/dev/null

echo "Verified the configured HTTP route and response."
