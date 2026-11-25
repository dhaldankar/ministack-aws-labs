---
id: s3-object-versioning
title: Keep and retrieve earlier S3 versions
summary: Enable versioning and retrieve an earlier revision by its version ID.
categories: [S3, Terraform]
---

## Enable versioning
Duration: 6:00

Your objective is to enable versioning before any uploads, upload two revisions of the same key, and retrieve the first version by its ID.

Start or resume the exercise:

```bash
lab_dir=$(lab start s3-object-versioning) && cd "$lab_dir"
terraform init
```

Edit the versioning configuration in `main.tf` to enable it. Find the `aws_s3_bucket_versioning` resource and change the `status` from `"Suspended"` to `"Enabled"`. Review and apply the plan before uploading either file.

```bash
terraform plan
terraform apply
bucket=$(terraform output -raw bucket)
aws s3api get-bucket-versioning --bucket "$bucket"
```

## Upload and retrieve versions
Duration: 9:00

Upload `first.txt` and then `second.txt` as `document.txt`. List versions, find the first version ID, and retrieve it explicitly. Compare the current and earlier content.

```bash
aws s3api put-object --bucket "$bucket" --key document.txt --body first.txt
aws s3api put-object --bucket "$bucket" --key document.txt --body second.txt
aws s3api list-object-versions --bucket "$bucket" --prefix document.txt
# Replace VERSION_ID with the first upload's version ID.
aws s3api get-object --bucket "$bucket" --key document.txt --version-id VERSION_ID earlier.txt
cat earlier.txt
lab check s3-object-versioning
```

## Clean up
Duration: 5:00

Delete every version of this lab's `document.txt` using `aws s3api delete-object --version-id VERSION_ID`. Also remove any delete markers shown in `list-object-versions`, then destroy the bucket:

```bash
aws s3api list-object-versions --bucket "$bucket" --prefix document.txt
terraform destroy
terraform state list
```
