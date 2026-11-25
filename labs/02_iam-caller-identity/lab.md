---
id: iam-caller-identity
title: Identify an AWS caller
summary: Use STS to inspect your active identity and examine an IAM role trust and permissions policy.
categories: [IAM, STS, Terraform]
---

## Start your workspace
Duration: 3:00

Your objective is to identify the active caller, inspect a sample IAM role, and explain which policy document controls who can assume it.

Start or resume the exercise:

```bash
lab_dir=$(lab start iam-caller-identity) && cd "$lab_dir"
```

Confirm MiniStack and the tools are available:

```bash
curl -fsS --retry 10 --retry-all-errors --max-time 5 "$AWS_ENDPOINT_URL/_ministack/health" | jq -r .auth
aws --version
```

The health check should print `enabled`.

## Provision the sample role
Duration: 4:00

```bash
terraform init
terraform plan
terraform apply
```

Review the plan. Terraform creates one IAM role with a trust policy and an inline permissions policy.

```bash
role_arn=$(terraform output -raw role_arn)
echo "$role_arn"
```

## Identify the caller and inspect the role
Duration: 5:00

Call STS to identify the active principal:

```bash
aws sts get-caller-identity
```

Retrieve the role and read its trust policy:

```bash
aws iam get-role --role-name "$(terraform output -raw role_name)" \
  --query 'Role.AssumeRolePolicyDocument'
```

Retrieve the inline policy attached to the role:

```bash
aws iam get-role-policy \
  --role-name "$(terraform output -raw role_name)" \
  --policy-name lab-inline-policy \
  --query 'PolicyDocument'
```

Answer these questions before running the checker:

- Which document controls **who can assume** the role?
- Which document controls **what the role can do** after it is assumed?
- What is the allowed IAM action in the inline policy?

Save your answers in `answers.txt`:

```bash
cat > answers.txt <<'EOF'
trust_policy_controls: AssumeRolePolicyDocument
permissions_policy_controls: PolicyDocument in get-role-policy
inline_action: s3:GetObject
EOF
```

```bash
lab check iam-caller-identity
```

## Clean up
Duration: 3:00

```bash
terraform destroy
terraform state list
```

Review the destroy plan before approving it. The state list should be empty afterwards.
