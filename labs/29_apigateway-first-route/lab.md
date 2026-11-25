---
id: apigateway-first-route
title: "Make your first HTTP API request"
summary: "Compare the deployed method and path with an HTTP request to a Lambda-backed route."
categories: [API Gateway, Lambda, First use]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start apigateway-first-route) && cd "$lab_dir"
terraform init
terraform apply
```

## Inspect and call the route
Duration: 8:00

```bash
api=$(terraform output -raw api_id)
aws apigatewayv2 get-routes --api-id "$api" --query 'Items[*].RouteKey'
curl -i "$(bash api-url.sh)/health"
```

Find the status, response headers, and JSON returned by the Lambda handler. Try `/missing` and compare the response.

## Verify
Duration: 2:00

```bash
lab check apigateway-first-route
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
