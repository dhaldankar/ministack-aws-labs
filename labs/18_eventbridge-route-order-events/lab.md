---
id: eventbridge-route-order-events
title: "Route order events with an EventBridge pattern"
summary: "Match an order event and compare SQS delivery with an excluded control event."
categories: [EventBridge, SQS, Configure]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start eventbridge-route-order-events) && cd "$lab_dir"
terraform init
terraform apply
```

## Inspect the existing rule
Duration: 7:00

```bash
bus=$(terraform output -raw bus)
aws events describe-rule --event-bus-name "$bus" --name order-events |
  jq '.EventPattern | fromjson'
bash publish.sh OrderCancelled
aws sqs receive-message --queue-url "$(terraform output -raw queue_url)" --wait-time-seconds 5
```

The source-only rule also delivers cancelled orders. Compare the rule with the order events sent by the publisher.

## Match an order creation
Duration: 6:00

Edit `main.tf` so the rule matches source `lab.orders` and detail type `OrderCreated`. Keep the SQS target and queue policy in place.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check eventbridge-route-order-events
```

The checker publishes a new creation and cancellation. It looks for their unique order IDs over a bounded window.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
