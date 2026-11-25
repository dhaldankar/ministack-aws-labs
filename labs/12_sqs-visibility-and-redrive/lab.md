---
id: sqs-visibility-and-redrive
title: Configure visibility and a dead-letter queue
summary: Set a short visibility timeout and configure a dead-letter queue with a redrive policy. Observe a message redelivered and then moved.
categories: [SQS, Terraform]
---

## Prepare the queues
Duration: 4:00

Your objective is to set a short visibility timeout on the work queue, configure the dead-letter queue ARN and maximum receive count, and observe a probe redelivered after the timeout.

Start or resume the exercise:

```bash
lab_dir=$(lab start sqs-visibility-and-redrive) && cd "$lab_dir"
terraform init
```

Open `main.tf` and complete the two placeholder values in the `aws_sqs_queue` resource for the work queue:

- Set `visibility_timeout_seconds` to `10`
- Set `redrive_policy` using the `aws_sqs_queue.dlq.arn` and a `maxReceiveCount` of `2`

Apply the configuration:

```bash
terraform plan
terraform apply
queue_url=$(terraform output -raw queue_url)
dlq_url=$(terraform output -raw dlq_url)
```

## Observe redelivery
Duration: 10:00

Send a probe message:

```bash
aws sqs send-message --queue-url "$queue_url" --message-body '{"job":"probe"}'
```

Receive it without deleting it:

```bash
aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages 1 \
  --attribute-names ApproximateReceiveCount
```

Note the `ApproximateReceiveCount`. Wait for the 10-second visibility timeout to expire, then receive again:

```bash
sleep 12
aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages 1 \
  --attribute-names ApproximateReceiveCount
```

The count should now be `2`. After a third receive attempt (or once the redrive count is exceeded), the message moves to the DLQ:

```bash
aws sqs receive-message --queue-url "$queue_url" --max-number-of-messages 1
sleep 12
aws sqs receive-message --queue-url "$dlq_url" --max-number-of-messages 1
lab check sqs-visibility-and-redrive
```

## Clean up
Duration: 2:00

Delete the probe from the DLQ if present, then destroy:

```bash
terraform destroy
terraform state list
```
