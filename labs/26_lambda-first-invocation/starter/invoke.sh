#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
aws_lab lambda invoke --function-name "$(terraform output -raw function)" \
  --cli-binary-format raw-in-base64-out --payload "$1" "$2"
