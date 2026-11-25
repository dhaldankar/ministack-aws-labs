---
id: elb-configure-path-routing
title: "Route requests by path"
summary: "Inspect target health and test traffic through an internal Application Load Balancer."
categories: [Elastic Load Balancing, AWS Sandbox, Configure]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start elb-configure-path-routing) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Inspect the listener and target
Duration: 8:00

```bash
listener=$(terraform output -raw listener_arn)
aws elbv2 describe-rules --listener-arn "$listener"
group=$(terraform output -raw orders_target_group)
aws elbv2 describe-target-health --target-group-arn "$group"
```

In `main.tf`, correct the orders listener rule to match `/orders` and configure both target groups to check `/health`. Predict where `/status` and an unmatched path will go. Apply and make both requests from the supplied VPC client.

```bash
terraform apply
bash probe.sh /orders
bash probe.sh /status
```

## Verify
Duration: 2:00

```bash
lab check elb-configure-path-routing
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
