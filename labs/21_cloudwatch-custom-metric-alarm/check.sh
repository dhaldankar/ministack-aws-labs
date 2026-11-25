#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

aws_lab() { aws --endpoint-url "$endpoint" --region us-east-1 --no-cli-pager --output json "$@"; }
alarm=$(terraform output -raw alarm)
describe() { aws_lab cloudwatch describe-alarms --alarm-names "$alarm" | jq -ec '.MetricAlarms[0] // error("Alarm missing")'; }
if [[ ${1:-} == baseline && false == true ]]; then
  bash publish.sh 25
  observed=$(describe)
  jq -e '.Dimensions == [{Name:"Queue",Value:"order"}] and .StateValue == "INSUFFICIENT_DATA"' <<<"$observed" >/dev/null
  printf '%s\n' "$observed" > baseline.alarm.json
  echo "Recorded INSUFFICIENT_DATA for Queue=order after publishing to Queue=orders."
  exit 0
fi

describe | jq -e '.Threshold == 10 and .Dimensions == [{Name:"Queue",Value:"orders"}]' >/dev/null
bash publish.sh 25
for attempt in {1..30}; do
  observed=$(describe)
  if jq -e '.StateValue == "ALARM"' <<<"$observed" >/dev/null; then
    jq '{AlarmName,StateValue,StateReason}' <<<"$observed"
    exit 0
  fi
  sleep 3
done
printf 'Expected ALARM after publishing Backlog=25. Last status: %s\n' "$observed" >&2
exit 1
