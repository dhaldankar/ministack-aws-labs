#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
table=$(jq -er '.table.value | strings | select(length > 0)' <<< "$outputs")

scratch=$(mktemp -d)
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Run the learner's script and capture output
if ! bash broken-query.sh > "$scratch/result.json" 2> "$scratch/err.txt"; then
  err=$(cat "$scratch/err.txt")
  if echo "$err" | grep -qi "ValidationException\|KeyConditionExpression"; then
    echo "broken-query.sh still uses a non-key attribute. Fix the key condition and expression values." >&2
    cat "$scratch/err.txt" >&2
    exit 1
  fi
  echo "broken-query.sh returned an unexpected error:" >&2
  cat "$scratch/err.txt" >&2
  exit 1
fi

items=$(jq '.Items' "$scratch/result.json")
count=$(jq 'length' <<< "$items")
[[ $count -ge 1 ]] \
  || { echo "Fixed query returned no items. Check the partition key value." >&2; exit 1; }
echo "PASS  Fixed query returned $count item(s)"

# All returned items must belong to the same customer partition
customer=$(jq -er '.[0].customer_id.S' <<< "$items")
all_same=$(jq -er --arg cid "$customer" 'map(.customer_id.S) | map(. == $cid) | all' <<< "$items")
[[ $all_same == "true" ]] \
  || { echo "Query returned items from multiple partitions — the partition key condition may be missing." >&2; exit 1; }
echo "PASS  All returned items belong to customer_id=$customer"

# Probe a second partition to confirm query changes correctly
other_customer="bob"
[[ $customer == "bob" ]] && other_customer="alice"
other_items=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb query \
  --table-name "$table" \
  --key-condition-expression "customer_id = :cid" \
  --expression-attribute-values "{\":cid\":{\"S\":\"$other_customer\"}}" \
  --query 'Items' --output json)
other_count=$(jq 'length' <<< "$other_items")
[[ $other_count -ge 1 ]] \
  || { echo "Could not verify $other_customer partition. Load fixtures or re-apply Terraform." >&2; exit 1; }
echo "PASS  Partition switch: $other_customer has $other_count item(s)"
