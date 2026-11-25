---
id: sqs-first-message
title: Send, receive, and delete an SQS message
summary: Send a job message, receive it, and delete it using its receipt handle. Confirm it does not reappear.
categories: [SQS, Terraform]
---

## Prepare the queue
Duration: 3:00

Your objective is to send a message, receive it, and use the receipt handle to delete it permanently.

Start or resume the exercise:

```bash
lab_dir=$(lab start sqs-first-message) && cd "$lab_dir"
terraform init
terraform plan
terraform apply
queue_url=$(terraform output -raw queue_url)
```

## Send and receive a message
Duration: 7:00

Send the sample job:

```bash
aws sqs send-message \
  --queue-url "$queue_url" \
  --message-body file://job.json
```

Receive it. Note both the `MessageId` and the `ReceiptHandle` — they serve different purposes:

```bash
aws sqs receive-message \
  --queue-url "$queue_url" \
  --max-number-of-messages 1
```

The `MessageId` identifies the message in the queue. The `ReceiptHandle` is a temporary token that lets you delete or extend visibility — it changes on each receive.

Delete the message using its receipt handle:

```bash
aws sqs delete-message \
  --queue-url "$queue_url" \
  --receipt-handle "RECEIPT_HANDLE_HERE"
lab check sqs-first-message
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```
