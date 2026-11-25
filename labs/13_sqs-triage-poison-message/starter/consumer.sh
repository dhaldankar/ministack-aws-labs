#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
queue=$(terraform output -raw source_url)
batch=$(aws_lab sqs receive-message --queue-url "$queue" --wait-time-seconds 2 \
  --max-number-of-messages 10 --message-system-attribute-names ApproximateReceiveCount)
while IFS= read -r message; do
  body=$(jq -r .Body <<<"$message")
  job=$(jq -er .job_id <<<"$body")
  count=$(jq -er .Attributes.ApproximateReceiveCount <<<"$message")
  if jq -e '.amount | type == "number"' <<<"$body" >/dev/null; then
    aws_lab sqs delete-message --queue-url "$queue" --receipt-handle "$(jq -r .ReceiptHandle <<<"$message")" >/dev/null
    printf 'completed %s (receive count %s)\n' "$job" "$count"
  else
    printf 'retry %s (receive count %s): missing amount\n' "$job" "$count"
  fi
done < <(jq -c '.Messages[]?' <<<"$batch")
