---
id: dynamodb-fix-key-condition
title: Repair a DynamoDB query
summary: Reproduce a validation error, correct the key condition expression, and verify the fixed query returns the expected orders.
categories: [DynamoDB, Terraform]
---

## Start your workspace
Duration: 3:00

Your objective is to identify why a query fails, correct the key condition, and verify the fix returns only the expected customer's orders.

Start or resume the exercise:

```bash
lab_dir=$(lab start dynamodb-fix-key-condition) && cd "$lab_dir"
terraform init
terraform plan
terraform apply
table=$(terraform output -raw table)
```

Terraform provisions a populated table and prints the broken query as a hint.

## Reproduce and diagnose the error
Duration: 7:00

Run the failing query from `broken-query.sh`:

```bash
bash broken-query.sh
```

Read the error message carefully. DynamoDB rejects key condition expressions that reference non-key attributes. Inspect the table schema:

```bash
aws dynamodb describe-table --table-name "$table" --query 'Table.KeySchema'
```

Compare the attribute used in `broken-query.sh` with the actual key names. What is wrong?

## Fix the query
Duration: 5:00

Edit `broken-query.sh` and correct:

1. The `--key-condition-expression` to use `customer_id` as the partition key
2. The `--expression-attribute-values` to match the corrected condition

Run the fixed query and confirm it returns Alice's orders, then verify:

```bash
bash broken-query.sh
lab check dynamodb-fix-key-condition
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```
