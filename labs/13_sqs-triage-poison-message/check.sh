#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
queue=$(terraform output -raw source_url)
target=$(terraform output -raw dlq_arn)
dlq=$(terraform output -raw dlq_url)
tag="probe-$(date +%s%N)"
policy=$(aws_lab sqs get-queue-attributes --queue-url "$queue" --attribute-names RedrivePolicy)
if [[ ${1:-} == baseline ]]; then
  jq -e '.Attributes.RedrivePolicy == null' <<<"$policy" >/dev/null
  bash seed.sh "$tag"
  for attempt in {1..6}; do
    run=$(bash consumer.sh)
    if grep -F "retry $tag-poison" <<<"$run"; then
      printf '%s\n' "$queue" > baseline.queue
      exit 0
    fi
    sleep 4
  done
  echo "The consumer did not report the seeded poison job." >&2
  exit 1
fi
[[ $(cat baseline.queue) == "$queue" ]]
jq -e --arg arn "$target" '.Attributes.RedrivePolicy | fromjson |
  .deadLetterTargetArn == $arn and (.maxReceiveCount | tonumber) == 2' <<<"$policy" >/dev/null
bash seed.sh "$tag"
healthy=false
moved=false
for attempt in {1..12}; do
  run=$(bash consumer.sh)
  if grep -F "completed $tag-healthy" <<<"$run"; then healthy=true; fi
  batch=$(aws_lab sqs receive-message --queue-url "$dlq" --max-number-of-messages 10 --wait-time-seconds 2 --visibility-timeout 3)
  while IFS= read -r message; do
    body=$(jq -r .Body <<<"$message")
    if jq -e --arg id "$tag-poison" '.job_id == $id and (.amount == null)' <<<"$body" >/dev/null; then
      moved=true
      aws_lab sqs delete-message --queue-url "$dlq" --receipt-handle "$(jq -r .ReceiptHandle <<<"$message")" >/dev/null
    fi
  done < <(jq -c '.Messages[]?' <<<"$batch")
  if $healthy && $moved; then
    echo "The healthy job completed and the poison job reached $target."
    exit 0
  fi
  sleep 4
done
echo "Expected one completed job and one dead-letter delivery." >&2
exit 1
