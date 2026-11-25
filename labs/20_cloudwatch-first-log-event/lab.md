---
id: cloudwatch-first-log-event
title: "Find a log event by request ID"
summary: "Write a structured log line and retrieve it from the orders stream."
categories: [CloudWatch, First use]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start cloudwatch-first-log-event) && cd "$lab_dir"
terraform init
terraform apply
```

## Write and find a request
Duration: 8:00

```bash
group=$(terraform output -raw group)
aws logs describe-log-streams --log-group-name "$group" --log-stream-name-prefix orders
# Create the stream once if it was absent.
aws logs create-log-stream --log-group-name "$group" --log-stream-name orders
jq -c --arg id "request-$(date +%s%N)" '.request_id = $id' event-template.json > log-event.json
events=$(jq -nc --argjson ts "$(date +%s%3N)" --arg msg "$(cat log-event.json)" \
  '[{timestamp:$ts,message:$msg}]')
aws logs put-log-events --log-group-name "$group" --log-stream-name orders --log-events "$events"
aws logs filter-log-events --log-group-name "$group" \
  --filter-pattern "\"$(jq -r .request_id log-event.json)\""
```

Compare the group, stream, timestamp, and message. Try the same search with a different request ID.

## Verify
Duration: 2:00

```bash
lab check cloudwatch-first-log-event
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
