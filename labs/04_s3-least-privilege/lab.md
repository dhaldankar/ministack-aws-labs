---
id: s3-least-privilege
title: Least-privilege access to S3
summary: Provision a bucket with Terraform, grant one object permission, and verify it with a learner IAM identity.
categories: [IAM, S3, Terraform]
---

## Confirm your local environment
Duration: 3:00

Your objective is to let an IAM user read `welcome.txt` while keeping writes to the bucket denied.

Open the integrated Bash terminal in the VS Code Dev Container, or enter the lab container from your host terminal using the README. Start or resume the exercise, then run the remaining commands from its directory.

```bash
lab_dir=$(lab start s3-least-privilege) && cd "$lab_dir"
```

Check that MiniStack and the tools are available:

```bash
curl -fsS --retry 10 --retry-all-errors --max-time 5 "$AWS_ENDPOINT_URL/_ministack/health" | jq -r .auth
terraform version
aws --version
```

The health check should print `enabled`. If MiniStack is unavailable, check that both Compose services are running before proceeding.

## Provision the baseline
Duration: 5:00

```bash
terraform init
terraform plan
terraform apply
```

Review the plan before approving it. Terraform creates a uniquely named bucket, two sample objects, and a learner IAM user with no grants. The provider points the S3, IAM, and STS calls at MiniStack.

## Observe the default denial
Duration: 2:00

```bash
lab check s3-least-privilege --baseline
```

Expect `PASS  Read before attaching the policy returned AccessDenied`. The checker creates a temporary learner access key, attempts the read with it, and deletes the key afterward. This gives you a baseline before granting any access.

## Grant one object permission
Duration: 5:00

Create `learner-policy.tf` beside `main.tf`. Complete the two empty values so the user can retrieve only the object already provisioned. The object resource is `aws_s3_object.seed`. Use its `arn` attribute for the policy resource.

```hcl
resource "aws_iam_user_policy" "read_welcome" {
  name = "read-welcome"
  user = aws_iam_user.learner.name

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

Which IAM action authorizes the AWS CLI `get-object` operation? Use that single action and the exact object ARN. In the Terraform plan, check that `Resource` looks like `arn:aws:s3:::<your-bucket>/welcome.txt`. A bucket name alone cannot match an object-level permission.

```bash
terraform fmt
terraform plan
terraform apply
```

## Verify the access boundary
Duration: 3:00

```bash
lab check s3-least-privilege
```

Expect three passes. The learner downloads `welcome.txt`, gets `AccessDenied` for `restricted.txt`, and gets `AccessDenied` when attempting to write a new object. The checker also compares the downloaded contents with the seeded text.

If the read fails, check the policy action, the object ARN, and the attached IAM user. If the write succeeds, inspect the policy for broad action patterns or extra grants. In the plan, confirm the policy uses `s3:GetObject` and the ARN of `welcome.txt`.

## Clean up
Duration: 2:00

```bash
terraform destroy
```

Review the destroy plan and approve it. Keep the Terraform state until the destroy completes. To repeat the baseline, remove your `learner-policy.tf` file after cleanup and begin again from provisioning.
