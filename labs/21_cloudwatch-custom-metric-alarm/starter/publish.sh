#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
aws_lab cloudwatch put-metric-data --namespace "$(terraform output -raw namespace)" \
  --metric-name Backlog --value "${1:-25}" --dimensions Name=Queue,Value=orders
