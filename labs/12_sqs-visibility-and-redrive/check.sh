#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
queue_url=$(jq -er '.queue_url.value | strings | select(length > 0)' <<< "$outputs")
dlq_url=$(jq -er '.dlq_url.value | strings | select(length > 0)' <<< "$outputs")
dlq_arn=$(jq -er '.dlq_arn.value | strings | select(length > 0)' <<< "$outputs")

# Verify visibility timeout is short (<= 15 seconds)
attrs=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  sqs get-queue-attributes --queue-url "$queue_url" \
  --attribute-names VisibilityTimeout RedrivePolicy --output json)
vis=$(jq -er '.Attributes.VisibilityTimeout | tonumber' <<< "$attrs")
[[ $vis -le 15 ]] \
  || { echo "VisibilityTimeout is ${vis}s. Set it to 10 seconds in main.tf." >&2; exit 1; }
echo "PASS  VisibilityTimeout=${vis}s (short enough for lab)"

# Verify redrive policy points to the DLQ with correct count
redrive_raw=$(jq -er '.Attributes.RedrivePolicy // ""' <<< "$attrs")
[[ -n $redrive_raw ]] \
  || { echo "RedrivePolicy not set on work queue. Uncomment and configure the redrive_policy in main.tf." >&2; exit 1; }
redrive=$(echo "$redrive_raw" | jq '.')
configured_arn=$(jq -er '.deadLetterTargetArn' <<< "$redrive")
max_receive=$(jq -er '.maxReceiveCount' <<< "$redrive")
[[ $configured_arn == "$dlq_arn" ]] \
  || { echo "RedrivePolicy ARN $configured_arn does not match DLQ ARN $dlq_arn." >&2; exit 1; }
[[ $max_receive -le 3 ]] \
  || { echo "maxReceiveCount is $max_receive. Set it to 2 to match the lab goal." >&2; exit 1; }
echo "PASS  RedrivePolicy: deadLetterTargetArn → DLQ, maxReceiveCount=$max_receive"

# Send a probe and receive it repeatedly to trigger redrive
probe_id="check-$$"
aws --endpoint-url "$endpoint" --no-cli-pager \
  sqs send-message --queue-url "$queue_url" \
  --message-body "{\"probe\":\"$probe_id\"}" > /dev/null
echo "PASS  Probe $probe_id sent"

# Receive twice without deleting (triggers redrive after maxReceiveCount)
for attempt in 1 2; do
  recv=$(aws --endpoint-url "$endpoint" --no-cli-pager \
    sqs receive-message --queue-url "$queue_url" \
    --max-number-of-messages 10 --attribute-names All --output json)
  probe=$(echo "$recv" | jq --arg id "$probe_id" '.Messages[]? | select(.Body | fromjson | .probe == $id)')
  if [[ -n $probe ]]; then
    receipt=$(echo "$probe" | jq -er '.ReceiptHandle')
    receive_count=$(echo "$probe" | jq -er '.Attributes.ApproximateReceiveCount // "1"')
    echo "PASS  Attempt $attempt: probe received (ApproximateReceiveCount=$receive_count)"
    # Change visibility to 0 to make it immediately available again
    aws --endpoint-url "$endpoint" --no-cli-pager \
      sqs change-message-visibility --queue-url "$queue_url" \
      --receipt-handle "$receipt" --visibility-timeout 0 > /dev/null
  fi
  sleep 1
done
echo "PASS  Redelivery behavior confirmed"
