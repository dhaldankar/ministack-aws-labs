---
id: eventbridge-fix-event-pattern
title: "Repair a rule that misses order events"
summary: "Match an order event and compare SQS delivery with an excluded control event."
categories: [EventBridge, SQS, Troubleshoot]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start eventbridge-fix-event-pattern) && cd "$lab_dir"
terraform init
terraform apply
```

## Reproduce the missing delivery
Duration: 7:00

```bash
bus=$(terraform output -raw bus)
aws events describe-rule --event-bus-name "$bus" --name order-events |
  jq '.EventPattern | fromjson'
lab check eventbridge-fix-event-pattern baseline
```

Compare the rule's detail type with the publisher's default in `publish.sh`. A successful PutEvents response confirms that the bus accepted the event. The queue probe measures delivery.

## Match an order creation
Duration: 6:00

Edit `main.tf` so the rule matches source `lab.orders` and detail type `OrderCreated`. Keep the SQS target and queue policy in place.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check eventbridge-fix-event-pattern
```

The checker publishes a new creation and cancellation. It looks for their unique order IDs over a bounded window.

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
