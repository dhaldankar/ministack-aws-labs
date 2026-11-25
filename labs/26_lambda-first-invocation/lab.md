---
id: lambda-first-invocation
title: "Deploy and invoke a function"
summary: "Invoke a Python function and compare successful and handled-error responses."
categories: [Lambda, First use]
---

## Start your workspace
Duration: 4:00

```bash
lab_dir=$(lab start lambda-first-invocation) && cd "$lab_dir"
terraform init
terraform apply
```

## Invoke the function
Duration: 9:00

```bash
bash invoke.sh file://valid.json valid-response.json
cat valid-response.json
bash invoke.sh file://invalid.json invalid-response.json
cat invalid-response.json
```

Compare the invocation metadata with each response body. The handler returns a JSON error for missing input. Try changing the order ID and predict the response. Restore the original fixture before running the checker.

## Verify
Duration: 2:00

```bash
lab check lambda-first-invocation
```

## Clean up
Duration: 2:00

```bash
terraform destroy
terraform state list
```

Confirm that the state list is empty.
