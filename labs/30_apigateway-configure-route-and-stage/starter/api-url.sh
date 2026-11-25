#!/usr/bin/env bash
set -euo pipefail
endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}

printf '%s/_aws/execute-api/%s/%s\n' "${endpoint%/}" "$(terraform output -raw api_id)" "$(terraform output -raw stage)"
