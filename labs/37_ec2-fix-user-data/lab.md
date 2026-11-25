---
id: ec2-fix-user-data
title: "Repair a failed EC2 bootstrap"
summary: "Compare EC2 status checks with a real HTTP request from inside the instance."
categories: [EC2, AWS Sandbox, Troubleshoot]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start ec2-fix-user-data) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Inspect instance and application status
Duration: 10:00

```bash
instance=$(terraform output -raw app_id)
aws ec2 describe-instances --instance-ids "$instance" \
  --query 'Reservations[0].Instances[0].{Image:ImageId,State:State.Name,Groups:SecurityGroups[*].GroupId,IMDS:MetadataOptions.HttpTokens}'
aws ec2 describe-instance-status --instance-ids "$instance"
```

A healthy instance can still fail to serve requests. Capture the seeded failure and inspect cloud-init output through Systems Manager.

```bash
lab check ec2-fix-user-data baseline
bash run-on.sh "$instance" 'tail -45 /var/log/cloud-init-output.log'
```

In `user-data.sh`, correct the service name given to `systemctl`. Apply to replace the instance and rerun bootstrap.

```bash
terraform apply
```


## Verify
Duration: 2:00

```bash
lab check ec2-fix-user-data
```

## Clean up
Duration: 3:00

```bash
instance=$(terraform output -raw app_id)
terraform destroy
aws ec2 wait instance-terminated --instance-ids "$instance"
terraform state list
```

Confirm that the state list is empty. The waiter verifies deletion of the service resource.
