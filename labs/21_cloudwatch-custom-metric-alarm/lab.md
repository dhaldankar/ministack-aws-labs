---
id: cloudwatch-custom-metric-alarm
title: "Configure a custom metric alarm"
summary: "Publish backlog data and verify that the alarm evaluates the intended time series."
categories: [CloudWatch, Configure]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start cloudwatch-custom-metric-alarm) && cd "$lab_dir"
terraform init
terraform apply
```

## Compare the threshold with a datapoint
Duration: 7:00

```bash
bash publish.sh 25
aws cloudwatch describe-alarms --alarm-names "$(terraform output -raw alarm)" \
  --query 'MetricAlarms[0].{State:StateValue,Threshold:Threshold,Dimensions:Dimensions}'
```

The starter uses a threshold of 100. Predict the state after one 60-second period containing a value of 25.

## Update the alarm
Duration: 7:00

In `main.tf`, set the threshold to 10. Apply and run the checker, which publishes a new datapoint and waits for ALARM.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check cloudwatch-custom-metric-alarm
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.

Published metric datapoints age out on their own.
