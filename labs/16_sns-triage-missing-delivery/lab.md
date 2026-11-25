---
id: sns-triage-missing-delivery
title: "Diagnose a missing SNS delivery"
summary: "Compare order notifications across audit and billing subscriptions."
categories: [SNS, SQS, Troubleshoot]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start sns-triage-missing-delivery) && cd "$lab_dir"
terraform init
terraform apply
```

## Diagnose the missing delivery
Duration: 12:00

```bash
lab check sns-triage-missing-delivery baseline
```

The fresh paid probe reached audit. Billing received no probe in the observation window. Inspect the subscription's filter alongside the publisher's message attribute.

```bash
sub=$(terraform output -raw billing_subscription)
aws sns get-subscription-attributes --subscription-arn "$sub" |
  jq '.Attributes.FilterPolicy | fromjson'
aws sns publish --topic-arn "$(terraform output -raw topic_arn)" \
  --message file://order.json \
  --message-attributes '{"status":{"DataType":"String","StringValue":"paid"}}'
```

In `main.tf`, make billing accept `paid` on the publisher's `status` attribute. Leave audit subscribed to every order. Predict what happens to a cancelled order and apply your change.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check sns-triage-missing-delivery
```

The checker publishes fresh messages and checks the decoded envelope in each expected destination.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
