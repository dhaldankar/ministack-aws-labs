#!/usr/bin/env bash
set -euo pipefail
source "${LAB_SOURCE_DIR:?}/../../scripts/sandbox.sh"
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json

bucket=$(terraform output -raw bucket)
since=$(cat change-time.txt)

for attempt in {1..24}; do
  result=$(bash lookup.sh)
  if event=$(jq -ec --arg bucket "$bucket" --arg start "$since" \
    'first(.Events[]?.CloudTrailEvent | fromjson | select(.eventName == "PutBucketTagging" and .awsRegion == "us-east-1" and .requestParameters.bucketName == $bucket and .eventTime >= $start and (.userIdentity.arn | type == "string")) |
  {eventName,eventTime,awsRegion,actor:.userIdentity.arn,requestParameters})' <<<"$result"); then
    printf '%s\n' "$event" | tee event.json
    exit 0
  fi
  sleep 15
done
echo "No matching bucket event appeared. Recheck the Region and retry." >&2
exit 1
