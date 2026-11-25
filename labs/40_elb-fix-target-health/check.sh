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

instance=$(terraform output -raw app_id)
dns=$(terraform output -raw alb_dns)
app_group=$(terraform output -raw app_target_group)
if [[ ${1:-} == baseline ]]; then
  bash run-on.sh "$instance" 'cloud-init status --wait && curl -fsS http://127.0.0.1:8080/health' | grep -Fx healthy
  wait_target "$app_group" unhealthy Target.ResponseCodeMismatch
  printf '%s\n' "$app_group" > baseline.target
  exit 0
fi
[[ $(cat baseline.target) == "$app_group" ]]
wait_target "$app_group" healthy
bash probe.sh / | grep -Fx 'orders backend'
echo "Verified ALB target health and HTTP routing."
