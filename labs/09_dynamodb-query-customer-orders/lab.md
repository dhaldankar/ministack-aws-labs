---
id: dynamodb-query-customer-orders
title: Query orders for one customer
summary: Configure a composite key, load order fixtures, and query one customer's orders.
categories: [DynamoDB, Terraform]
---

## Create the table
Duration: 5:00

Your objective is to configure a composite key schema, load fixture data, and query orders for one customer using a sort key range.

Start or resume the exercise:

```bash
lab_dir=$(lab start dynamodb-query-customer-orders) && cd "$lab_dir"
terraform init
```

Open `main.tf` and complete the two placeholders:

- Set `hash_key` to `customer_id`
- Set `range_key` to `order_id`
- Add `attribute` blocks for both keys (type `S`)

Apply the table:

```bash
terraform plan
terraform apply
table=$(terraform output -raw table)
aws dynamodb describe-table --table-name "$table" --query 'Table.KeySchema'
```

## Load fixtures and query one customer
Duration: 10:00

Load the order fixtures for both customers:

```bash
aws dynamodb batch-write-item --request-items file://fixtures.json
```

Query all orders for `customer_id = "alice"`:

```bash
aws dynamodb query \
  --table-name "$table" \
  --key-condition-expression "customer_id = :cid" \
  --expression-attribute-values '{":cid":{"S":"alice"}}'
```

Add a sort-key range to narrow results to orders starting with `"ord-2"`:

```bash
aws dynamodb query \
  --table-name "$table" \
  --key-condition-expression "customer_id = :cid AND begins_with(order_id, :prefix)" \
  --expression-attribute-values '{":cid":{"S":"alice"},":prefix":{"S":"ord-2"}}'
lab check dynamodb-query-customer-orders
```

## Clean up
Duration: 3:00

```bash
terraform destroy
terraform state list
```
