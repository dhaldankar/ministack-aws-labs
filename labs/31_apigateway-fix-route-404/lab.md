---
id: apigateway-fix-route-404
title: "Diagnose an HTTP API route mismatch"
summary: "Compare the deployed method and path with an HTTP request to a Lambda-backed route."
categories: [API Gateway, Lambda, Troubleshoot]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start apigateway-fix-route-404) && cd "$lab_dir"
terraform init
terraform apply
```

## Inspect and call the route
Duration: 8:00

```bash
api=$(terraform output -raw api_id)
aws apigatewayv2 get-routes --api-id "$api" --query 'Items[*].RouteKey'
curl -i "$(bash api-url.sh)/orders/123"
lab check apigateway-fix-route-404 baseline
```

The initial request returns 404 at the gateway. Edit the route in `main.tf` to match `GET /orders/{id}`. The starter deploys a stage named `v1`. Verify that the URL includes this stage, then apply and compare two responses.

```bash
terraform apply
curl -i "$(bash api-url.sh)/orders/123"
curl -i "$(bash api-url.sh)/orders/999"
```

Both requests should reach the handler. The second returns a 404 with the unknown order ID in the body.

## Verify
Duration: 2:00

```bash
lab check apigateway-fix-route-404
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
