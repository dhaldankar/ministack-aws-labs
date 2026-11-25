#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

outputs=$(terraform output -json)
queue_url=$(jq -er '.queue_url.value | strings | select(length > 0)' <<< "$outputs")

scratch=$(mktemp -d)
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Send a fresh probe message
probe_id="check-probe-$$"
send_result=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  sqs send-message --queue-url "$queue_url" \
  --message-body "{\"job_id\":\"$probe_id\",\"task\":\"probe\"}" \
  --output json)
message_id=$(jq -er '.MessageId' <<< "$send_result")
echo "PASS  Probe sent with MessageId=$message_id"

# Receive the probe
sleep 1
recv=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  sqs receive-message --queue-url "$queue_url" \
  --max-number-of-messages 10 \
  --attribute-names All --output json)
probe_msg=$(echo "$recv" | jq --arg id "$probe_id" '.Messages[] | select(.Body | fromjson | .job_id == $id)')
[[ -n $probe_msg ]] \
  || { echo "Probe message $probe_id not found in queue." >&2; exit 1; }
receipt=$(echo "$probe_msg" | jq -er '.ReceiptHandle')
echo "PASS  Probe received with receipt handle"

# Delete it
aws --endpoint-url "$endpoint" --no-cli-pager \
  sqs delete-message --queue-url "$queue_url" --receipt-handle "$receipt"
echo "PASS  Probe deleted with receipt handle"

# Wait past a minimal visibility window and confirm it does not reappear
sleep 2
reappeared=$(aws --endpoint-url "$endpoint" --no-cli-pager \
  sqs receive-message --queue-url "$queue_url" \
  --max-number-of-messages 10 --output json)
still_there=$(echo "$reappeared" | jq --arg id "$probe_id" \
  '[.Messages // [] | .[] | select(.Body | fromjson | .job_id == $id)] | length')
[[ $still_there -eq 0 ]] \
  || { echo "Probe $probe_id reappeared after deletion." >&2; exit 1; }
echo "PASS  Deleted probe did not reappear after visibility window"
