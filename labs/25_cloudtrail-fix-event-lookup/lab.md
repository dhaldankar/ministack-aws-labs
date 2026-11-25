---
id: cloudtrail-fix-event-lookup
title: "Find an event missing from a lookup"
summary: "Find the lab bucket's management event and inspect its actor and request."
categories: [CloudTrail, AWS Sandbox, Troubleshoot]
---

## Start your workspace
Duration: 4:00

This exercise uses a disposable AWS account in `us-east-1`. Start in a fresh Bash shell, configure temporary AWS credentials or an AWS CLI profile for the sandbox, and export `LAB_AWS_ACCOUNT_ID` with its 12-digit account ID. For resources with hourly charges, finish the cleanup in the same session.

```bash
lab_dir=$(lab start cloudtrail-fix-event-lookup) && cd "$lab_dir"
source "$(lab sandbox)" &&
terraform init && terraform apply
```

## Record a bucket change
Duration: 6:00

```bash
bash tag-bucket.sh
bash lookup.sh
lab check cloudtrail-fix-event-lookup baseline
```

Compare the Region in `lookup.sh` with the bucket's provider Region in `main.tf`. Set the lookup Region to match and run it again.

## Verify
Duration: 2:00

```bash
lab check cloudtrail-fix-event-lookup
```

Inspect `event.json` for the actor ARN, API call, time, and request parameters.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
