#!/usr/bin/env bash
set -euo pipefail

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}
if ! curl -fsS --max-time 5 "$endpoint/_ministack/health" | jq -e '.auth == "enabled"' > /dev/null; then
    echo "MiniStack is unavailable or IAM enforcement is disabled at $endpoint." >&2
    exit 1
fi

outputs=$(terraform output -json)
bucket=$(jq -er '.bucket.value | strings | select(length > 0)' <<< "$outputs")
target_key=$(jq -er '.target_key.value | strings | select(length > 0)' <<< "$outputs")
control_key=$(jq -er '.control_key.value | strings | select(length > 0)' <<< "$outputs")
role_arn=$(jq -er '.role_arn.value | strings | select(length > 0)' <<< "$outputs")
role_name=$(jq -er '.role_name.value | strings | select(length > 0)' <<< "$outputs")

scratch=$(mktemp -d)
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

lab_aws() {
    local ak=$1 sk=$2 st=$3
    shift 3
    env -i PATH="$PATH" \
        AWS_ACCESS_KEY_ID="$ak" AWS_SECRET_ACCESS_KEY="$sk" AWS_SESSION_TOKEN="$st" \
        AWS_CONFIG_FILE="$scratch/config" AWS_SHARED_CREDENTIALS_FILE=/dev/null \
        AWS_EC2_METADATA_DISABLED=true \
        AWS_REQUEST_CHECKSUM_CALCULATION=when_required \
        AWS_RESPONSE_CHECKSUM_VALIDATION=when_required \
        aws --endpoint-url "$endpoint" --region us-east-1 --output json --no-cli-pager "$@"
}

printf '[default]\ns3 =\n    addressing_style = path\n' > "$scratch/config"

# Check role policy has s3:GetObject scoped to target object
policy=$(aws --endpoint-url "$endpoint" iam get-role-policy \
  --role-name "$role_name" --policy-name read-target \
  --query 'PolicyDocument' --output json --no-cli-pager 2>/dev/null) \
  || { echo "Role policy 'read-target' not found. Complete role-policy.tf and apply." >&2; exit 1; }

action=$(jq -er '.Statement[0].Action[0] // .Statement[0].Action' <<< "$policy" | head -1)
resource=$(jq -er '.Statement[0].Resource[0] // .Statement[0].Resource' <<< "$policy" | head -1)
[[ $action == "s3:GetObject" ]] || { echo "Expected s3:GetObject in role policy, got: $action" >&2; exit 1; }
echo "PASS  Role policy contains s3:GetObject"
[[ $resource == *"$bucket"* && $resource == *"$target_key"* ]] \
  || { echo "Role policy resource $resource does not match the target object ARN." >&2; exit 1; }
echo "PASS  Role policy resource scoped to target object"

# Assume the role and test access
creds=$(aws --endpoint-url "$endpoint" sts assume-role \
  --role-arn "$role_arn" --role-session-name "lab-check-$$" \
  --query 'Credentials' --output json --no-cli-pager)
ak=$(jq -er '.AccessKeyId' <<< "$creds")
sk=$(jq -er '.SecretAccessKey' <<< "$creds")
st=$(jq -er '.SessionToken' <<< "$creds")

# Should succeed for target
lab_aws "$ak" "$sk" "$st" s3api get-object \
  --bucket "$bucket" --key "$target_key" "$scratch/out.txt" > /dev/null
content=$(cat "$scratch/out.txt")
[[ $content == "this is the allowed object for the assume-role lab" ]] \
  || { echo "Downloaded content does not match the seeded object." >&2; exit 1; }
echo "PASS  Assumed role can read target object"

# Should fail for control
if lab_aws "$ak" "$sk" "$st" s3api get-object \
    --bucket "$bucket" --key "$control_key" "$scratch/ctrl.txt" > /dev/null 2>&1; then
  echo "Expected AccessDenied for restricted object." >&2
  exit 1
fi
echo "PASS  Assumed role cannot read control object (AccessDenied)"

# Confirm original caller is not the assumed role
original=$(aws --endpoint-url "$endpoint" sts get-caller-identity --query Arn --output text --no-cli-pager)
assumed_prefix="arn:aws:sts"
[[ $original != *"assumed-role"* ]] \
  || echo "Warning: original caller appears to already be an assumed role."
echo "PASS  Original caller ARN: $original"
echo "PASS  Assumed role ARN:     arn:aws:sts::000000000000:assumed-role/$(basename "$role_arn")/lab-check-$$"
