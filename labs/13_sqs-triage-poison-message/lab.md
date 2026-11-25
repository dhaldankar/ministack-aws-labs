---
id: sqs-triage-poison-message
title: "Trace a poison message to a dead-letter queue"
summary: "Observe a consumer fail on an incomplete job and verify SQS redrive."
categories: [SQS, Troubleshoot]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start sqs-triage-poison-message) && cd "$lab_dir"
terraform init
terraform apply
```

## Reproduce the failure
Duration: 6:00

```bash
lab check sqs-triage-poison-message baseline
bash consumer.sh
```

Open `consumer.sh` and the two JSON fixtures. The consumer deletes a message after processing a numeric amount. It leaves an incomplete message unacknowledged for SQS to deliver again after four seconds.

## Configure redrive
Duration: 8:00

In `main.tf`, add a `redrive_policy` to the source queue. Set `deadLetterTargetArn` to `aws_sqs_queue.dlq.arn` and `maxReceiveCount` to `2` inside `jsonencode`. Apply and verify with fresh jobs.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check sqs-triage-poison-message
```

The checker drives the supplied consumer and looks for the exact poison job in the dead-letter queue.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
