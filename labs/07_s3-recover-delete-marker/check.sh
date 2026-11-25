#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
bucket=$(jq -er '.bucket.value | strings | select(length > 0)' <<< "$outputs")
expected_content=$(jq -er '.original_content.value | strings | select(length > 0)' <<< "$outputs")

scratch=$(mktemp -d)
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Normal read must succeed after marker removal
if ! aws --endpoint-url "$endpoint" --no-cli-pager \
    s3api get-object --bucket "$bucket" --key report.txt "$scratch/report.txt" > /dev/null 2>&1; then
  echo "Normal read of report.txt failed. The delete marker may still be present." >&2
  echo "List versions and remove the DeleteMarker entry by its version ID." >&2
  exit 1
fi
actual_content=$(cat "$scratch/report.txt")
[[ $actual_content == "$expected_content" ]] \
  || { echo "Content after recovery does not match the original." >&2
       echo "Expected: $expected_content" >&2
       echo "Got:      $actual_content" >&2; exit 1; }
echo "PASS  Normal read of report.txt succeeds and content matches original"

# Confirm no current delete marker
versions_json=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  s3api list-object-versions --bucket "$bucket" --prefix report.txt --output json)
delete_markers=$(echo "$versions_json" | jq '[.DeleteMarkers // [] | .[] | select(.IsLatest==true)] | length')
[[ $delete_markers -eq 0 ]] \
  || { echo "A current delete marker still exists on report.txt." >&2; exit 1; }
echo "PASS  No current delete marker on report.txt"

# Confirm original data version still exists
data_versions=$(echo "$versions_json" | jq '[.Versions // [] | .[]] | length')
[[ $data_versions -ge 1 ]] \
  || { echo "No data versions found for report.txt after recovery." >&2; exit 1; }
echo "PASS  Original data version still present"
