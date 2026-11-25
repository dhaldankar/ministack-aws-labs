---
id: orientation
title: Orientation
summary: Connect to MiniStack and use Terraform to create and inspect your first S3 bucket.
categories: [Getting started, S3, Terraform]
---

## Start your workspace
Duration: 3:00

In the integrated Bash terminal, start or resume this exercise:

```bash
lab_dir=$(lab start orientation) && cd "$lab_dir"
```

Check the endpoint, Region, and caller:

```bash
printf 'Endpoint %s\nRegion %s\n' "$AWS_ENDPOINT_URL" "$AWS_DEFAULT_REGION"
aws sts get-caller-identity
```

The caller ARN identifies the principal making requests. MiniStack is the local endpoint for this playground.

## Diagnose a connection problem
Duration: 3:00

Make a request to an intentionally misspelled local hostname:

```bash
AWS_MAX_ATTEMPTS=1 aws --endpoint-url http://ministack-typo:4566 sts get-caller-identity
```

Identify the hostname in the error, then run the original command again. The successful result confirms that the CLI and the configured endpoint work.

## Create your first bucket
Duration: 6:00

Open `main.tf` in the Explorer and find the bucket prefix. Initialize Terraform, inspect the plan, and approve the apply.

```bash
terraform init
terraform plan
terraform apply
lab check orientation
```

The checker should confirm both the caller identity and the bucket created by Terraform.

## Clean up
Duration: 3:00

```bash
terraform destroy
terraform state list
```

Review the destroy plan before approving it. The state list should be empty afterwards. Run `lab list` to see the other available exercises.
