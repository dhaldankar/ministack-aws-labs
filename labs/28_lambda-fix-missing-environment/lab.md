---
id: lambda-fix-missing-environment
title: "Diagnose a missing Lambda environment variable"
summary: "Find the runtime configuration the function needs and verify its DynamoDB-backed response."
categories: [Lambda, Troubleshoot]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start lambda-fix-missing-environment) && cd "$lab_dir"
terraform init
terraform apply
```

## Observe the initial invocation
Duration: 7:00

```bash
lab check lambda-fix-missing-environment baseline
```

Compare the error with the environment lookup in `handler.py`. The table already contains order `fixture-001`.

## Configure the function
Duration: 8:00

Add an `environment` block to `aws_lambda_function.function` in `main.tf`. Map `TABLE_NAME` to `aws_dynamodb_table.orders.name`.


```bash
terraform apply
```

## Verify
Duration: 2:00

```bash
lab check lambda-fix-missing-environment
```

The checker invokes with a fresh correlation ID and finds the DynamoDB result and related log line.


## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
