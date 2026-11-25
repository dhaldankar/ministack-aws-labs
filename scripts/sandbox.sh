# Source this file in a fresh lab shell after configuring temporary credentials.
unset TF_VAR_lab_aws_account_id
if [[ ! ${LAB_AWS_ACCOUNT_ID:-} =~ ^[0-9]{12}$ || $LAB_AWS_ACCOUNT_ID == 000000000000 ]]; then
  echo 'Set LAB_AWS_ACCOUNT_ID to the 12-digit disposable AWS account ID.' >&2
  return 1
fi

# Compose supplies fake credentials and a MiniStack endpoint to every lab shell.
if [[ ${AWS_ACCESS_KEY_ID:-} == test && ${AWS_SECRET_ACCESS_KEY:-} == test ]]; then
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
fi
for lab_endpoint_var in ${!AWS_ENDPOINT_URL@}; do
  unset "$lab_endpoint_var"
done
unset lab_endpoint_var TF_VAR_ministack_endpoint
export AWS_IGNORE_CONFIGURED_ENDPOINT_URLS=true AWS_DEFAULT_REGION=us-east-1 AWS_REGION=us-east-1
export AWS_PAGER="" AWS_DEFAULT_OUTPUT=json
if ! lab_account=$(aws sts get-caller-identity --region us-east-1 --query Account --output text) ||
   [[ "$lab_account" != "$LAB_AWS_ACCOUNT_ID" ]]; then
  echo 'The active AWS credentials must belong to the selected disposable account.' >&2
  unset lab_account
  return 1
fi
unset lab_account
export TF_VAR_lab_aws_account_id=$LAB_AWS_ACCOUNT_ID
