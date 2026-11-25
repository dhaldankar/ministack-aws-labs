#!/usr/bin/env bash
set -euo pipefail
source "${LAB_SOURCE_DIR:?}/../../scripts/sandbox.sh"
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json

wait_target() {
  local group=$1 state=$2 reason=${3:-} health
  for attempt in {1..36}; do
    health=$(aws elbv2 describe-target-health --target-group-arn "$group")
    if jq -e --arg state "$state" --arg reason "$reason" '
      .TargetHealthDescriptions | length == 1 and
      .[0].TargetHealth.State == $state and ($reason == "" or .[0].TargetHealth.Reason == $reason)' <<<"$health" >/dev/null; then
      jq '.TargetHealthDescriptions[0].TargetHealth' <<<"$health"
      return 0
    fi
    sleep 5
  done
  printf 'Target did not reach %s: %s\n' "$state" "$health" >&2
  return 1
}

instance=$(terraform output -raw orders_id)
dns=$(terraform output -raw alb_dns)
orders_group=$(terraform output -raw orders_target_group)
status_group=$(terraform output -raw status_target_group)

wait_target "$orders_group" healthy
wait_target "$status_group" healthy
bash probe.sh /orders | grep -Fx 'orders backend'
bash probe.sh /status | grep -Fx 'status backend'
bash run-on.sh "$instance" "code=\$(curl -sS --max-time 8 -o /tmp/lab-unmatched -w '%{http_code}' http://$dns/unknown); test \"\$code\" = 404 && cat /tmp/lab-unmatched" |
  grep -Fx 'unmatched path'
echo "Verified ALB target health and HTTP routing."
