#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
bucket=$(jq -er '.bucket.value | strings | select(length > 0)' <<< "$outputs")

scratch=$(mktemp -d)
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Check versioning is enabled
versioning=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  s3api get-bucket-versioning --bucket "$bucket" \
  --query 'Status' --output text)
[[ $versioning == "Enabled" ]] \
  || { echo "Versioning is '$versioning' on bucket $bucket. Enable it in main.tf and apply." >&2; exit 1; }
echo "PASS  Bucket versioning is Enabled"

# Check both versions of document.txt exist
versions_json=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  s3api list-object-versions --bucket "$bucket" --prefix document.txt --output json)
version_count=$(echo "$versions_json" | jq '.Versions | length')
[[ $version_count -ge 2 ]] \
  || { echo "Expected at least 2 versions of document.txt, found $version_count." >&2; exit 1; }
echo "PASS  At least 2 versions of document.txt found"

# Check current version is second.txt content
latest_version=$(echo "$versions_json" | jq -er '[.Versions[] | select(.IsLatest==true)] | .[0].VersionId')
aws --endpoint-url "$endpoint" --no-cli-pager \
  s3api get-object --bucket "$bucket" --key document.txt "$scratch/current.txt" > /dev/null
current_content=$(cat "$scratch/current.txt")
[[ $current_content == *"second version"* ]] \
  || { echo "Current version of document.txt should be the second revision." >&2
       echo "Got: $current_content" >&2; exit 1; }
echo "PASS  Current read returns second revision"

# Check older version is first.txt content
older_version=$(echo "$versions_json" | jq -er '[.Versions[] | select(.IsLatest==false)] | .[0].VersionId')
aws --endpoint-url "$endpoint" --no-cli-pager \
  s3api get-object --bucket "$bucket" --key document.txt \
  --version-id "$older_version" "$scratch/earlier.txt" > /dev/null
earlier_content=$(cat "$scratch/earlier.txt")
[[ $earlier_content == *"first version"* ]] \
  || { echo "Earlier version of document.txt should be the first revision." >&2
       echo "Got: $earlier_content" >&2; exit 1; }
echo "PASS  Earlier version retrieved by version ID returns first revision"
