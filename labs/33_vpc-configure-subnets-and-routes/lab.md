---
id: vpc-configure-subnets-and-routes
title: "Build public and private subnets"
summary: "Inspect routes and security group scope in a dedicated VPC."
categories: [VPC, AWS Sandbox, Configure]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start vpc-configure-subnets-and-routes) && cd "$lab_dir"
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

In `main.tf`, set the public IPv4 route to `0.0.0.0/0` through the supplied internet gateway, associate the private subnet with the isolated route table, and permit TCP 8080 from the client security group to the app group.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check vpc-configure-subnets-and-routes
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
