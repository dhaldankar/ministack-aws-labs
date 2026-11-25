---
id: ec2-bootstrap-web-server
title: "Bootstrap a web server with user data"
summary: "Compare EC2 status checks with a real HTTP request from inside the instance."
categories: [EC2, AWS Sandbox, Configure]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start ec2-bootstrap-web-server) && cd "$lab_dir"
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

In `user-data.sh`, uncomment the final `systemctl enable --now` line so bootstrap starts the supplied HTTP service. Apply to replace the instance and rerun bootstrap. Systems Manager runs the HTTP probe on the instance itself.

```bash
terraform apply
```


## Verify
Duration: 2:00

```bash
lab check ec2-bootstrap-web-server
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
