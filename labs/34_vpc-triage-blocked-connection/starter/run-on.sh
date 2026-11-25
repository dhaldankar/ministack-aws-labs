#!/usr/bin/env bash
set -euo pipefail

: "${TF_VAR_lab_aws_account_id:?Source the AWS sandbox environment first}"
instance=${1:?Supply an instance ID}
command=${2:?Supply the command to run}
for attempt in {1..36}; do
  ping=$(aws ssm describe-instance-information --filters "Key=InstanceIds,Values=$instance" \
    --query 'InstanceInformationList[0].PingStatus' --output text)
  [[ "$ping" == Online ]] && break
  sleep 5
done
if [[ "$ping" != Online ]]; then
  echo "SSM never reported $instance online." >&2
  exit 1
fi
input=$(jq -nc --arg cmd "$command" '{commands:[$cmd],executionTimeout:["100"]}')
id=$(aws ssm send-command --instance-ids "$instance" --document-name AWS-RunShellScript \
  --timeout-seconds 120 --parameters "$input" --query Command.CommandId --output text)
for attempt in {1..55}; do
  if result=$(aws ssm get-command-invocation --command-id "$id" --instance-id "$instance" 2>&1); then
    case $(jq -r .Status <<<"$result") in
      Success) jq -r .StandardOutputContent <<<"$result"; exit 0 ;;
      Pending|InProgress|Delayed) ;;
      *) jq -r '.Status, .StandardOutputContent, .StandardErrorContent' <<<"$result" >&2; exit 1 ;;
    esac
  elif [[ "$result" != *InvocationDoesNotExist* ]]; then
    echo "$result" >&2
    exit 1
  fi
  sleep 3
done
echo "Timed out waiting for SSM command $id." >&2
exit 1
