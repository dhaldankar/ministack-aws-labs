#!/usr/bin/env bash
set -euo pipefail
source "${LAB_SOURCE_DIR:?}/../../scripts/sandbox.sh"
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json

instance=$(terraform output -raw app_id)
aws ec2 wait instance-status-ok --instance-ids "$instance"
aws ec2 describe-instances --instance-ids "$instance" |
  jq -e --arg ami "$(terraform output -raw ami)" --arg group "$(terraform output -raw app_sg)" '
    .Reservations[0].Instances[0] |
    .ImageId == $ami and .State.Name == "running" and .MetadataOptions.HttpTokens == "required" and any(.SecurityGroups[]; .GroupId == $group)' >/dev/null

bash run-on.sh "$instance" 'cloud-init status --wait && systemctl is-active lab-http.service && curl -fsS --max-time 5 http://127.0.0.1:8080/' |
  grep -Fx 'orders web server'
echo "Verified the running instance and the HTTP response."
