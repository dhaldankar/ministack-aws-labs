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

north_expected="Hello from the northern region."
south_expected="Hello from the southern region."

aws --endpoint-url "$endpoint" --no-cli-pager s3api get-object \
  --bucket "$bucket" --key north/message.txt "$scratch/north.txt" > /dev/null
north_actual=$(cat "$scratch/north.txt")
[[ $north_actual == *"$north_expected"* ]] \
  || { echo "north/message.txt content does not match the fixture." >&2
       echo "Got: $north_actual" >&2; exit 1; }
echo "PASS  north/message.txt content matches fixture"

aws --endpoint-url "$endpoint" --no-cli-pager s3api get-object \
  --bucket "$bucket" --key south/message.txt "$scratch/south.txt" > /dev/null
south_actual=$(cat "$scratch/south.txt")
[[ $south_actual == *"$south_expected"* ]] \
  || { echo "south/message.txt content does not match the fixture." >&2
       echo "Got: $south_actual" >&2; exit 1; }
echo "PASS  south/message.txt content matches fixture"

listing=$(aws --endpoint-url "$endpoint" --no-cli-pager s3api list-objects-v2 \
  --bucket "$bucket" --prefix north/ --query 'Contents[].Key' --output json)
echo "$listing" | jq -e 'map(select(. == "north/message.txt")) | length > 0' > /dev/null \
  || { echo "north/ prefix listing does not include north/message.txt." >&2
       echo "Got: $listing" >&2; exit 1; }
south_in_north=$(echo "$listing" | jq 'map(select(startswith("south/"))) | length')
[[ $south_in_north -eq 0 ]] \
  || { echo "north/ listing unexpectedly includes south/ objects." >&2; exit 1; }
echo "PASS  north/ prefix listing returns only north/message.txt"
