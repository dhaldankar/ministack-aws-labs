---
id: s3-recover-delete-marker
title: Recover an object hidden by a delete marker
summary: Identify a current delete marker, remove it by version ID, and confirm the original content is restored.
categories: [S3, Terraform]
---

## Start your workspace
Duration: 3:00

Your objective is to explain why a normal read fails, find the delete marker, remove it, and restore the original content.

Start or resume the exercise:

```bash
lab_dir=$(lab start s3-recover-delete-marker) && cd "$lab_dir"
terraform init
terraform plan
terraform apply
bucket=$(terraform output -raw bucket)
```

The starter provisions a versioned bucket with a known object and a current delete marker that simulates an accidental deletion.

## Reproduce the failure
Duration: 5:00

Try to read the object as normal and observe the error:

```bash
aws s3api get-object --bucket "$bucket" --key report.txt /tmp/report.txt
```

Expect a `NoSuchKey` error even though the data exists. List all versions to find the delete marker:

```bash
aws s3api list-object-versions --bucket "$bucket" --prefix report.txt
```

Identify the entry with `"Type": "DeleteMarker"` and note its `VersionId`. Compare it with the data version underneath.

## Remove the delete marker
Duration: 5:00

Delete only the delete marker by its version ID:

```bash
aws s3api delete-object \
  --bucket "$bucket" \
  --key report.txt \
  --version-id DELETE_MARKER_VERSION_ID
```

Confirm the normal read now succeeds:

```bash
aws s3api get-object --bucket "$bucket" --key report.txt /tmp/report.txt
cat /tmp/report.txt
lab check s3-recover-delete-marker
```

## Clean up
Duration: 4:00

Remove all remaining object versions before destroying the bucket:

```bash
aws s3api list-object-versions --bucket "$bucket" --prefix report.txt
# Delete each data version by its version ID, then destroy:
terraform destroy
terraform state list
```
