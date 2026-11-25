#!/usr/bin/env bash
# This query uses a non-key attribute as its key condition.
# Fix the expression and attribute values to use the correct partition key.
set -uo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}
table=$(terraform output -raw table)

aws --endpoint-url "$endpoint" --no-cli-pager \
  dynamodb query \
  --table-name "$table" \
  --key-condition-expression "status = :s" \
  --expression-attribute-values '{":s":{"S":"pending"}}'
