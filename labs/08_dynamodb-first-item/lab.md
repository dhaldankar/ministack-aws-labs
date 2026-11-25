---
id: dynamodb-first-item
title: Store and retrieve a DynamoDB item
summary: Inspect a table key, write an order, and compare reads for present and absent keys.
categories: [DynamoDB, Terraform]
---

## Create the table
Duration: 4:00

Your objective is to identify the partition key, write an item, and explain the difference between a hit and a miss.

Start or resume the exercise:

```bash
lab_dir=$(lab start dynamodb-first-item) && cd "$lab_dir"
terraform init
terraform plan
terraform apply
table=$(terraform output -raw table)
aws dynamodb describe-table --table-name "$table" --query 'Table.KeySchema'
```

Identify the partition key in the response. Open `order.json` and compare its attribute types with the table schema.

## Write and read an order
Duration: 7:00

```bash
aws dynamodb put-item --table-name "$table" --item file://order.json
aws dynamodb get-item --table-name "$table" --consistent-read --key '{"order_id":{"S":"order-100"}}'
aws dynamodb get-item --table-name "$table" --consistent-read --key '{"order_id":{"S":"order-missing"}}'
lab check dynamodb-first-item
```

Compare the responses. An absent item has no `Item` field.

## Clean up
Duration: 4:00

```bash
terraform destroy
terraform state list
```
