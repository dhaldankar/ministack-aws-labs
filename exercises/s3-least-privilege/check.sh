#!/usr/bin/env bash
set -euo pipefail

if (( $# > 1 )) || [[ $# == 1 && $1 != --baseline ]]; then
    echo "Usage: $0 [--baseline]" >&2
    exit 2
fi

endpoint=${TF_VAR_ministack_endpoint:-${AWS_ENDPOINT_URL:-http://localhost:4567}}
if ! curl -fsS --max-time 5 "$endpoint/_ministack/health" | jq -e '.auth == "enabled"' >/dev/null; then
    echo "MiniStack is unavailable or IAM enforcement is disabled at $endpoint." >&2
    exit 1
fi

exercise_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
outputs=$(terraform -chdir="$exercise_dir" output -json)
bucket=$(jq -er '.bucket.value | select(type == "string" and length > 0)' <<<"$outputs")
object_key=$(jq -er '.object_key.value | select(type == "string" and length > 0)' <<<"$outputs")
learner=$(jq -er '.learner.value | select(type == "string" and length > 0)' <<<"$outputs")

scratch=$(mktemp -d)
key_id=
secret_key=

lab_aws() {
    local access_key=$1 secret=$2
    shift 2
    env -i PATH="$PATH" \
        AWS_ACCESS_KEY_ID="$access_key" AWS_SECRET_ACCESS_KEY="$secret" \
        AWS_CONFIG_FILE="$scratch/config" AWS_SHARED_CREDENTIALS_FILE=/dev/null \
        AWS_EC2_METADATA_DISABLED=true AWS_REQUEST_CHECKSUM_CALCULATION=when_required \
        AWS_RESPONSE_CHECKSUM_VALIDATION=when_required \
        aws --endpoint-url "$endpoint" --region us-east-1 --output json --no-cli-pager "$@"
}

cleanup() {
    local status=$?
    if [[ -n $key_id ]] && ! lab_aws test test iam delete-access-key \
        --user-name "$learner" --access-key-id "$key_id" >/dev/null; then
        echo "Delete learner key $key_id before destroying the lab." >&2
        status=1
    fi
    rm -rf -- "$scratch"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '[default]\ns3 =\n    addressing_style = path\n' >"$scratch/config"
key=$(lab_aws test test iam create-access-key --user-name "$learner")
key_id=$(jq -er '.AccessKey.AccessKeyId | strings | select(length > 0)' <<<"$key")
secret_key=$(jq -er '.AccessKey.SecretAccessKey | strings | select(length > 0)' <<<"$key")

expect_denied() {
    local action=$1
    shift
    if lab_aws "$key_id" "$secret_key" "$@" >"$scratch/stdout" 2>"$scratch/stderr" ||
        ! grep -Fq '(AccessDenied)' "$scratch/stderr"; then
        printf 'Expected AccessDenied for %s.\n' "$action" >&2
        cat "$scratch/stderr" >&2
        return 1
    fi
    printf 'PASS  %s returned AccessDenied\n' "$action"
}

file=$scratch/welcome.txt
if [[ ${1:-} == --baseline ]]; then
    expect_denied 'Read before attaching the policy' s3api get-object \
        --bucket "$bucket" --key "$object_key" "$file"
    exit 0
fi

lab_aws "$key_id" "$secret_key" s3api get-object \
    --bucket "$bucket" --key "$object_key" "$file" >/dev/null
if ! printf '%s' 'hello from the MiniStack IAM lab' | cmp -s - "$file"; then
    echo 'The downloaded content does not match the provisioned object.' >&2
    exit 1
fi
echo 'PASS  Learner can read welcome.txt'

expect_denied 'Read restricted.txt' s3api get-object \
    --bucket "$bucket" --key restricted.txt "$scratch/restricted.txt"

probe=check-${scratch##*/}.txt
if lab_aws "$key_id" "$secret_key" s3api put-object \
    --bucket "$bucket" --key "$probe" --body "$file" >"$scratch/stdout" 2>"$scratch/stderr"; then
    if ! lab_aws test test s3api delete-object --bucket "$bucket" --key "$probe" >/dev/null; then
        echo "Remove probe object $probe before destroying the lab." >&2
    fi
    echo 'Expected AccessDenied for write to the lab bucket.' >&2
    exit 1
fi
if ! grep -Fq '(AccessDenied)' "$scratch/stderr"; then
    echo 'Expected AccessDenied for write to the lab bucket.' >&2
    cat "$scratch/stderr" >&2
    exit 1
fi
echo 'PASS  Write to the lab bucket returned AccessDenied'
