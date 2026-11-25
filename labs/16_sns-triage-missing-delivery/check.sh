#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
topic=$(terraform output -raw topic_arn)
tag="probe-$(date +%s)-$$"
publish() {
  local status=$1
  local body
  body=$(jq -nc --arg id "$tag-$status" --arg status "$status" '{order_id:$id,status:$status}')
  aws_lab sns publish --topic-arn "$topic" --subject OrderCreated --message "$body" \
    --message-attributes "{\"status\":{\"DataType\":\"String\",\"StringValue\":\"$status\"}}" >/dev/null
}

# Short visibility keeps unrelated learner messages available for future reads.
observe() {
  local queue=$1 expected=$2 deadline=$((SECONDS + 12)) batch message body id
  local seen='[]'
  while (( SECONDS < deadline )); do
    batch=$(aws_lab sqs receive-message --queue-url "$queue" --max-number-of-messages 10 --wait-time-seconds 2 --visibility-timeout 3)
    while IFS= read -r message; do
      body=$(jq -c '.Body | fromjson?' <<<"$message")
      id=$(jq -r '(.Message | fromjson?) | .order_id // empty' <<<"$body")
      [[ "$id" == "$tag-"* ]] || continue
      jq -e ".Type == \"Notification\" and .TopicArn == \"$topic\" and .Subject == \"OrderCreated\" and ((.Message | fromjson) as \$m | \$m.order_id == (\"$tag-\" + \$m.status))" <<<"$body" >/dev/null
      seen=$(jq -c --arg id "$id" '. + [$id] | unique | sort' <<<"$seen")
      aws_lab sqs delete-message --queue-url "$queue" --receipt-handle "$(jq -r .ReceiptHandle <<<"$message")" >/dev/null
    done < <(jq -c '.Messages[]?' <<<"$batch")
  done
  if [[ "$seen" != "$expected" ]]; then
    printf 'Queue %s expected %s, observed %s\n' "$queue" "$expected" "$seen" >&2
    return 1
  fi
}

billing=$(terraform output -raw billing_subscription)
filter=$(aws_lab sns get-subscription-attributes --subscription-arn "$billing" | jq -c '.Attributes.FilterPolicy | fromjson')
publish paid
publish cancelled
observe "$(terraform output -raw audit_url)" "[\"$tag-cancelled\",\"$tag-paid\"]"
if [[ ${1:-} == baseline && true == true ]]; then
  jq -e '. == {state:["paid"]}' <<<"$filter" >/dev/null
  observe "$(terraform output -raw billing_url)" '[]'
  printf '%s\n' "$billing" > baseline.subscription
  echo "Observed delivery to audit only with filter $filter"
  exit 0
fi
jq -e '. == {status:["paid"]}' <<<"$filter" >/dev/null
[[ $(cat baseline.subscription) == "$billing" ]]
observe "$(terraform output -raw billing_url)" "[\"$tag-paid\"]"
echo "Verified SNS notification envelope and expected queue deliveries."
