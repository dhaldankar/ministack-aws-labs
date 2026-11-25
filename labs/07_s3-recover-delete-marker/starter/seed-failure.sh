#!/usr/bin/env bash
# This script seeds a delete marker after terraform apply to simulate an accidental deletion.
# The lab check.sh independently verifies the final state.
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}
outputs=$(terraform output -json)
bucket=$(jq -er '.bucket.value' <<< "$outputs")

# Place a delete marker to simulate accidental deletion
aws --endpoint-url "$endpoint" --no-cli-pager \
  s3api delete-object --bucket "$bucket" --key report.txt > /dev/null
echo "Delete marker seeded on report.txt in bucket $bucket"
