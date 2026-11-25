---
id: elb-first-load-balanced-request
title: "Send a request through a load balancer"
summary: "Inspect target health and test traffic through an internal Application Load Balancer."
categories: [Elastic Load Balancing, AWS Sandbox, First use]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start elb-first-load-balanced-request) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Inspect the listener and target
Duration: 8:00

```bash
listener=$(terraform output -raw listener_arn)
aws elbv2 describe-rules --listener-arn "$listener"
group=$(terraform output -raw app_target_group)
aws elbv2 describe-target-health --target-group-arn "$group"
```

Identify the listener's default action and registered target. When the target becomes healthy, send a request to the internal ALB from the supplied instance. Systems Manager runs the command inside the VPC.

```bash
bash probe.sh /
```

## Verify
Duration: 2:00

```bash
lab check elb-first-load-balanced-request
```

## Clean up
Duration: 3:00

```bash
alb=$(terraform output -raw alb_arn)
terraform destroy
aws elbv2 wait load-balancers-deleted --load-balancer-arns "$alb"
terraform state list
```

Confirm that the state list is empty. The waiter verifies deletion of the service resource.
