---
id: cloudwatch-fix-alarm-dimensions
title: "Repair an alarm that watches the wrong dimension"
summary: "Publish backlog data and verify that the alarm evaluates the intended time series."
categories: [CloudWatch, Troubleshoot]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start cloudwatch-fix-alarm-dimensions) && cd "$lab_dir"
terraform init
terraform apply
```

## Observe missing metric data
Duration: 7:00

```bash
lab check cloudwatch-fix-alarm-dimensions baseline
```

Inspect `baseline.alarm.json` and `publish.sh`. A metric's namespace, name, and complete dimension set identify its time series.

## Update the alarm
Duration: 7:00

In `main.tf`, set the Queue dimension to the value used by the publisher. Apply and run the checker, which publishes a new datapoint and waits for ALARM.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check cloudwatch-fix-alarm-dimensions
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.

Published metric datapoints age out on their own.
