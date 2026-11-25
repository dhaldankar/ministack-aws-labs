---
id: vpc-first-network
title: "Read a VPC network layout"
summary: "Inspect routes and security group scope in a dedicated VPC."
categories: [VPC, AWS Sandbox, First use]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start vpc-first-network) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Inspect the network
Duration: 12:00

Inspect the subnet ranges and trace each association to its route table.

```bash
vpc=$(terraform output -raw vpc)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" \
  --query 'Subnets[].[SubnetId,CidrBlock,AvailabilityZone]' --output table
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" \
  --query 'RouteTables[].{Table:RouteTableId,Associations:Associations[*].SubnetId,Routes:Routes}'
```

Identify the VPC-local route shared by both tables and the route that makes the public subnet public.

## Verify
Duration: 2:00

```bash
lab check vpc-first-network
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
