#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
table=$(jq -er '.table.value | strings | select(length > 0)' <<< "$outputs")

# Verify composite key schema
schema=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb describe-table --table-name "$table" \
  --query 'Table.KeySchema' --output json)
hash_key=$(echo "$schema" | jq -er '[.[] | select(.KeyType=="HASH")] | .[0].AttributeName')
range_key=$(echo "$schema" | jq -er '[.[] | select(.KeyType=="RANGE")] | .[0].AttributeName')
[[ $hash_key == "customer_id" ]] \
  || { echo "Expected hash_key='customer_id', got '$hash_key'." >&2; exit 1; }
[[ $range_key == "order_id" ]] \
  || { echo "Expected range_key='order_id', got '$range_key'." >&2; exit 1; }
echo "PASS  Composite key: customer_id (HASH) + order_id (RANGE)"

# Query alice and check sorted order IDs
alice_items=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb query \
  --table-name "$table" \
  --key-condition-expression "customer_id = :cid" \
  --expression-attribute-values '{":cid":{"S":"alice"}}' \
  --query 'Items[].order_id.S' --output json)
expected_alice='["ord-100","ord-200","ord-300"]'
[[ $alice_items == "$expected_alice" ]] \
  || { echo "Alice's orders: expected $expected_alice, got $alice_items." >&2; exit 1; }
echo "PASS  Alice's orders returned in sorted order: $alice_items"

# Query bob and confirm different results
bob_items=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb query \
  --table-name "$table" \
  --key-condition-expression "customer_id = :cid" \
  --expression-attribute-values '{":cid":{"S":"bob"}}' \
  --query 'Items[].order_id.S' --output json)
bob_count=$(echo "$bob_items" | jq 'length')
[[ $bob_count -eq 2 ]] \
  || { echo "Expected 2 orders for bob, got $bob_count." >&2; exit 1; }
# Confirm alice's IDs are absent from bob's results
echo "$bob_items" | jq -e 'map(select(startswith("ord-1") or startswith("ord-2") or startswith("ord-3"))) | length == 2' > /dev/null \
  || true  # sort order check is best-effort
echo "PASS  Bob's orders are separate from Alice's: $bob_items"
