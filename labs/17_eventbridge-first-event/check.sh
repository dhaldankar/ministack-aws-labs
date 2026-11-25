#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
bus=$(terraform output -raw event_bus_name)
queue=$(terraform output -raw queue_url)
id="probe-$(date +%s%N)"
entries=$(jq -c --arg bus "$bus" --arg id "$id" \
  '.[0].EventBusName = $bus | .[0].Detail |= (fromjson | .orderId = $id | tojson)' sample-event.json)
result=$(aws_lab events put-events --entries "$entries")
event_id=$(jq -er 'select(.FailedEntryCount == 0) | .Entries[0].EventId' <<<"$result")
for attempt in {1..8}; do
  batch=$(aws_lab sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --wait-time-seconds 2 --visibility-timeout 3)
  if message=$(jq -ec --arg id "$id" 'first(.Messages[]? | select((.Body | fromjson?).detail.orderId == $id))' <<<"$batch"); then
    jq -e --arg event "$event_id" --arg id "$id" '.Body | fromjson |
      .id == $event and .source == "com.example.orders" and ."detail-type" == "order.placed" and .detail.orderId == $id' <<<"$message" >/dev/null
    aws_lab sqs delete-message --queue-url "$queue" --receipt-handle "$(jq -r .ReceiptHandle <<<"$message")" >/dev/null
    echo "Found event $event_id and order $id in the target queue."
    exit 0
  fi
done
echo "The published event did not reach the SQS target." >&2
exit 1
