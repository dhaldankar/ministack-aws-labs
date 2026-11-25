---
id: vpc-triage-blocked-connection
title: "Restore a blocked VPC request"
summary: "Inspect routes and security group scope in a dedicated VPC."
categories: [VPC, AWS Sandbox, Troubleshoot]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start vpc-triage-blocked-connection) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Inspect the network
Duration: 12:00

Run the baseline check, then inspect the destination's ingress rule. The probe runs on a separate SSM-managed client, and the app runs on its private IP.

```bash
lab check vpc-triage-blocked-connection baseline
aws ec2 describe-security-group-rules --filters "Name=group-id,Values=$(terraform output -raw app_sg)"
```

The intended service listens on TCP 8080. In `main.tf`, correct the app ingress rule to use that port and keep the source scoped to the client security group. Apply the edit and verify the request.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check vpc-triage-blocked-connection
```

## Clean up
Duration: 3:00

```bash
instances="$(terraform output -raw app_id) $(terraform output -raw probe_id)"
terraform destroy
aws ec2 wait instance-terminated --instance-ids $instances
terraform state list
```

Confirm that the state list is empty. The waiter verifies deletion of the service resource.
