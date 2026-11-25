#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
table=$(jq -er '.table.value | strings | select(length > 0)' <<< "$outputs")

# Consistent read must find order-100
item=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb get-item --table-name "$table" --consistent-read \
  --key '{"order_id":{"S":"order-100"}}' \
  --query 'Item' --output json)
[[ $item != "null" && -n $item ]] \
  || { echo "order-100 not found. Run put-item with order.json first." >&2; exit 1; }

order_status=$(echo "$item" | jq -er '.status.S')
[[ $order_status == "pending" ]] \
  || { echo "Expected status 'pending', got '$order_status'." >&2; exit 1; }
echo "PASS  order-100 found with status=$order_status"

# Control key must return no item
missing=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb get-item --table-name "$table" --consistent-read \
  --key '{"order_id":{"S":"order-missing"}}' \
  --query 'Item' --output json)
[[ $missing == "null" ]] \
  || { echo "Expected no item for order-missing, but got a result." >&2; exit 1; }
echo "PASS  order-missing returns no item (empty response)"
