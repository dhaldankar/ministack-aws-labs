#!/usr/bin/env bash
set -euo pipefail

endpoint=${AWS_ENDPOINT_URL:?Open the playground terminal before running this check}
caller=$(aws --endpoint-url "$endpoint" sts get-caller-identity --no-cli-pager --query Arn --output text)
[[ $caller == arn:* ]] || { echo 'Expected a caller ARN.' >&2; exit 1; }
echo 'PASS  AWS CLI can reach MiniStack and identify the caller'

bucket=$(terraform output -raw bucket)
aws --endpoint-url "$endpoint" s3api head-bucket --bucket "$bucket" --no-cli-pager
echo "PASS  Terraform bucket $bucket is reachable"
