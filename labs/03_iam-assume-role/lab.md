---
id: iam-assume-role
title: Assume a role and use temporary credentials
summary: Grant read access to one S3 object, assume a role, and confirm the assumed identity differs from the original caller.
categories: [IAM, S3, STS, Terraform]
---

## Start your workspace
Duration: 3:00

Your objective is to give a role read access to one S3 object, assume that role in a subshell, and verify the resulting identity.

Start or resume the exercise:

```bash
lab_dir=$(lab start iam-assume-role) && cd "$lab_dir"
```

Confirm MiniStack and the tools are available:

```bash
curl -fsS --retry 10 --retry-all-errors --max-time 5 "$AWS_ENDPOINT_URL/_ministack/health" | jq -r .auth
terraform version
aws --version
```

## Provision the baseline
Duration: 5:00

```bash
terraform init
terraform plan
terraform apply
```

Terraform creates a bucket with two objects, an assumable role, and a trust relationship that permits assumption. The partial permission statement is printed as `policy_object_arn`:

```bash
terraform output
```

Note the `policy_object_arn` value — it identifies the object the role should be allowed to read.

## Grant one read permission
Duration: 5:00

Open `role-policy.tf` and complete the empty `Action` and `Resource` values:

```hcl
resource "aws_iam_role_policy" "read_target" {
  name = "read-target"
  role = aws_iam_role.lab.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = []
      Resource = []
    }]
  })
}
```

Use `s3:GetObject` as the action and the `policy_object_arn` Terraform output as the resource. Apply the change:

```bash
terraform fmt
terraform plan
terraform apply
```

## Assume the role and compare identities
Duration: 7:00

Record the starting caller ARN:

```bash
aws sts get-caller-identity --query Arn --output text
```

Assume the role in a subshell, using the credentials from STS:

```bash
creds=$(aws sts assume-role \
  --role-arn "$(terraform output -raw role_arn)" \
  --role-session-name lab-session \
  --query 'Credentials' --output json)

(
  export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r .AccessKeyId)
  export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | jq -r .SecretAccessKey)
  export AWS_SESSION_TOKEN=$(echo "$creds" | jq -r .SessionToken)
  echo "--- inside subshell ---"
  aws sts get-caller-identity
  aws s3api get-object \
    --bucket "$(terraform output -raw bucket)" \
    --key "$(terraform output -raw target_key)" \
    /tmp/assumed-read.txt && cat /tmp/assumed-read.txt
  echo "--- leaving subshell ---"
)

echo "--- back to original caller ---"
aws sts get-caller-identity
lab check iam-assume-role
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Review and approve the destroy plan. The state list should be empty afterwards.
