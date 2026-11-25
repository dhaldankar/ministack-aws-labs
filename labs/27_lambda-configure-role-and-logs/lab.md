---
id: lambda-configure-role-and-logs
title: "Configure a function environment and role"
summary: "Find the runtime configuration the function needs and verify its DynamoDB-backed response."
categories: [Lambda, Configure]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start lambda-configure-role-and-logs) && cd "$lab_dir"
terraform init
terraform apply
```

## Observe the initial invocation
Duration: 7:00

```bash
bash invoke.sh '{"order_id":"fixture-001"}' response.json
cat response.json
aws logs filter-log-events --log-group-name "$(terraform output -raw log_group)" \
  --query 'events[*].message'
```

Compare the error with the environment lookup in `handler.py`. The table already contains order `fixture-001`.

## Configure the function
Duration: 8:00

Add an `environment` block to `aws_lambda_function.function` in `main.tf`. Map `TABLE_NAME` to `aws_dynamodb_table.orders.name`.
 Add an Allow statement to the execution role's existing policy for `dynamodb:GetItem` on `aws_dynamodb_table.orders.arn`.

```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check lambda-configure-role-and-logs
```

The checker invokes with a fresh correlation ID and finds the DynamoDB result and related log line.


## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
