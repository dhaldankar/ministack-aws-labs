---
id: sns-first-publication
title: "Publish to an SNS topic"
summary: "Publish an order and inspect the SNS envelope delivered to SQS."
categories: [SNS, SQS, First use]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start sns-first-publication) && cd "$lab_dir"
terraform init
terraform apply
```

## Publish and inspect
Duration: 8:00

```bash
topic=$(terraform output -raw topic_arn)
queue=$(terraform output -raw audit_url)
aws sns list-subscriptions-by-topic --topic-arn "$topic"
aws sns publish --topic-arn "$topic" --subject OrderCreated --message file://order.json
aws sqs receive-message --queue-url "$queue" --wait-time-seconds 5 |
  jq '.Messages[0].Body | fromjson | {Type,TopicArn,Subject,order:(.Message|fromjson)}'
```

Compare the topic ARN and decoded order with the original values. Try another subject and inspect which field changes.

## Verify
Duration: 2:00

```bash
lab check sns-first-publication
```

The checker publishes fresh messages and checks the decoded envelope in each expected destination.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
