#!/usr/bin/env bash
set -euo pipefail
source "${LAB_SOURCE_DIR:?}/../../scripts/sandbox.sh"
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json

app=$(terraform output -raw app_id)
ip=$(terraform output -raw app_ip)
client=$(terraform output -raw probe_id)
aws ec2 wait instance-status-ok --instance-ids "$app"
if [[ ${1:-} == baseline ]]; then
  bash run-on.sh "$client" "code=0; curl -fsS --connect-timeout 4 --max-time 5 http://$ip:8080/ || code=\$?; test \"\$code\" -eq 28"
  printf '%s\n' "$app" > baseline.instance
  echo "The probe timed out reaching the private app on port 8080."
  exit 0
fi
[[ $(cat baseline.instance) == "$app" ]]
bash run-on.sh "$client" "curl --retry 6 --retry-all-errors --retry-delay 3 -fsS --connect-timeout 4 http://$ip:8080/" |
  grep -Fx 'private orders web server'
