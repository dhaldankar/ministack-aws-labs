---
id: elb-fix-target-health
title: "Fix an unhealthy load balancer target"
summary: "Inspect target health and test traffic through an internal Application Load Balancer."
categories: [Elastic Load Balancing, AWS Sandbox, Troubleshoot]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start elb-fix-target-health) && cd "$lab_dir"
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

Capture the baseline and compare the target's health reason with the configured path. The checker also calls the app's working health endpoint over loopback.

```bash
lab check elb-fix-target-health baseline
aws elbv2 describe-target-groups --target-group-arns "$(terraform output -raw app_target_group)" \
  --query 'TargetGroups[0].HealthCheckPath'
```

In `main.tf`, set the target group's health check path to `/health` and apply. An ALB can forward when all registered targets are unhealthy. Check target health and the HTTP response separately.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check elb-fix-target-health
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
