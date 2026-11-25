#!/usr/bin/env bash
set -euo pipefail

instance=$(terraform output -raw orders_id)
dns=$(terraform output -raw alb_dns)
path=${1:-/}
[[ "$path" =~ ^/[a-z]*$ ]] || exit 1
bash run-on.sh "$instance" "curl -fsS --connect-timeout 4 --max-time 8 http://$dns$path"
