#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
tag="probe-$(date +%s)-$$"
queue=$(terraform output -raw queue_url)

# Short visibility keeps unrelated learner messages available for future reads.
observe() {
  local queue=$1 expected=$2 deadline=$((SECONDS + 12)) batch message body id
  local seen='[]'
  while (( SECONDS < deadline )); do
    batch=$(aws_lab sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --wait-time-seconds 2 --visibility-timeout 3)
    while IFS= read -r message; do
      body=$(jq -c '.Body | fromjson?' <<<"$message")
      id=$(jq -r '.detail | .order_id // empty' <<<"$body")
      [[ "$id" == "$tag-"* ]] || continue
      jq -e ".source == \"lab.orders\" and (.[\"detail-type\"] == \"OrderCreated\" or .[\"detail-type\"] == \"OrderCancelled\")" <<<"$body" >/dev/null
      seen=$(jq -c --arg id "$id" '. + [$id] | unique | sort' <<<"$seen")
      aws_lab sqs delete-message --queue-url "$queue" --receipt-handle "$(jq -r .ReceiptHandle <<<"$message")" >/dev/null
    done < <(jq -c '.Messages[]?' <<<"$batch")
  done
  if [[ "$seen" != "$expected" ]]; then
    printf 'Queue %s expected %s, observed %s\n' "$queue" "$expected" "$seen" >&2
    return 1
  fi
}

bash publish.sh OrderCreated "$tag-created" >/dev/null
bash publish.sh OrderCancelled "$tag-cancelled" >/dev/null
if [[ ${1:-} == baseline && true == true ]]; then
  observe "$queue" '[]'
  terraform output -raw rule_arn > baseline.rule
  echo "No probe arrived under the seeded pattern."
  exit 0
fi
[[ $(cat baseline.rule) == "$(terraform output -raw rule_arn)" ]]
observe "$queue" "[\"$tag-created\"]"
echo "The target received OrderCreated and excluded OrderCancelled."
