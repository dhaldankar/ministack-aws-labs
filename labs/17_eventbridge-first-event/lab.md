---
id: eventbridge-first-event
title: "Publish and inspect a custom event"
summary: "Send an order event to a custom bus and inspect the envelope routed to SQS."
categories: [EventBridge, SQS, First use]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start eventbridge-first-event) && cd "$lab_dir"
terraform init
terraform apply
```

## Publish an order event
Duration: 8:00

Inspect `sample-event.json` and identify the source, detail type, and JSON-encoded detail. Add the bus name from Terraform and send the event.

```bash
bus=$(terraform output -raw event_bus_name)
aws events list-rules --event-bus-name "$bus"
entries=$(jq -c --arg bus "$bus" '.[0].EventBusName = $bus' sample-event.json)
aws events put-events --entries "$entries"
aws sqs receive-message --queue-url "$(terraform output -raw queue_url)" --wait-time-seconds 5 |
  jq '.Messages[0].Body | fromjson'
```

Compare the response's `EventId` with the envelope's `id`. Find the event source, detail type, and order ID in the envelope. Try changing the order amount and inspect the new payload.

## Verify
Duration: 2:00

```bash
lab check eventbridge-first-event
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
