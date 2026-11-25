---
id: cloudtrail-management-trail
title: "Deliver management events to S3"
summary: "Find the lab bucket's management event and inspect its actor and request."
categories: [CloudTrail, AWS Sandbox, Configure]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start cloudtrail-management-trail) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Enable and scope the trail
Duration: 8:00

In `main.tf`, enable logging and add an `event_selector` to the trail with `read_write_type = "WriteOnly"` and `include_management_events = true`. Leave data-event resources unset. The supplied bucket policy permits delivery from the lab trail.

```bash
terraform apply
trail=$(terraform output -raw trail)
aws cloudtrail get-event-selectors --trail-name "$trail"
aws cloudtrail get-trail-status --name "$trail"
bash tag-bucket.sh
```

CloudTrail delivery to S3 can take several minutes.

## Verify
Duration: 2:00

```bash
lab check cloudtrail-management-trail
```

Inspect `event.json` for the actor ARN, API call, time, and request parameters.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
