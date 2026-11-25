#!/usr/bin/env bash
set -euo pipefail
source "${LAB_SOURCE_DIR:?}/../../scripts/sandbox.sh"
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json

bucket=$(terraform output -raw bucket)
since=$(cat change-time.txt)
trail=$(terraform output -raw trail)
aws cloudtrail get-trail-status --name "$trail" | jq -e '.IsLogging == true' >/dev/null
aws cloudtrail get-event-selectors --trail-name "$trail" |
  jq -e 'any(.EventSelectors[]?; .ReadWriteType == "WriteOnly" and .IncludeManagementEvents and (.DataResources | length == 0))' >/dev/null
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
declare -A inspected=()
for attempt in {1..30}; do
  keys=$(aws s3api list-objects-v2 --bucket "$bucket" --prefix "AWSLogs/$LAB_AWS_ACCOUNT_ID/CloudTrail/us-east-1/")
  while IFS= read -r key; do
    [[ ${inspected["$key"]:-} ]] && continue
    aws s3api get-object --bucket "$bucket" --key "$key" "$tmp/log.json.gz" >/dev/null
    gzip -dc "$tmp/log.json.gz" > "$tmp/log.json"
    if event=$(jq -ec --arg bucket "$bucket" --arg start "$since" \
      'first(.Records[]? | select(.eventName == "PutBucketTagging" and .awsRegion == "us-east-1" and .requestParameters.bucketName == $bucket and .eventTime >= $start and (.userIdentity.arn | type == "string")) |
  {eventName,eventTime,awsRegion,actor:.userIdentity.arn,requestParameters})' "$tmp/log.json"); then
      echo "Delivered record in s3://$bucket/$key"
      printf '%s\n' "$event" | tee event.json
      exit 0
    fi
    inspected["$key"]=1
  done < <(jq -r '.Contents[]?.Key | select(endswith(".json.gz"))' <<<"$keys")
  sleep 20
done
echo "The trail has not delivered the recorded bucket change yet. Retry after delivery." >&2
exit 1
