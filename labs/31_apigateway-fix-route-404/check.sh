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
if [[ ${1:-} == baseline ]]; then
  jq -e 'any(.Items[]; .RouteKey == "POST /orders/{id}")' <<<"$routes" >/dev/null
  [[ $(get /orders/123) == 404 ]]
  printf '%s\n' "$api" > baseline.api
  echo "GET /orders/123 returned 404 while the route was configured for POST."
  exit 0
fi
[[ $(cat baseline.api) == "$api" ]]
jq -e 'any(.Items[]; .RouteKey == "GET /orders/{id}")' <<<"$routes" >/dev/null
[[ $(get /orders/123) == 200 ]]
jq -e '. == {id:"123",item:"widget",qty:5}' "$tmp/body" >/dev/null
[[ $(get /orders/999) == 404 ]]
jq -e '. == {error:"not found",id:"999"}' "$tmp/body" >/dev/null
[[ $(get /missing) == 404 ]]
jq -e '.id == null' "$tmp/body" >/dev/null
echo "Verified the configured HTTP route and response."
