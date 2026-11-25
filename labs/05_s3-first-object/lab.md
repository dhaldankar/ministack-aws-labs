---
id: s3-first-object
title: Upload and retrieve an S3 object
summary: Upload two files under different prefixes and retrieve one by its full key.
categories: [S3, Terraform]
---

## Prepare the bucket
Duration: 4:00

Your objective is to upload two files with the same filename under different prefixes and confirm that S3 identifies them by their full key.

Start or resume the exercise:

```bash
lab_dir=$(lab start s3-first-object) && cd "$lab_dir"
terraform init
terraform plan
terraform apply
bucket=$(terraform output -raw bucket)
```

The two fixture files have the same filename but different contents. S3 identifies an object by its complete key, including its prefix.

## Upload and inspect objects
Duration: 7:00

Upload `north/message.txt` and `south/message.txt` to the corresponding keys in your bucket. List only the `north/` prefix and retrieve `north/message.txt` to a local file. Use `aws s3api put-object`, `list-objects-v2 --prefix`, and `get-object`; use `--body` to specify each local input file.

```bash
aws s3api put-object --bucket "$bucket" --key north/message.txt --body north/message.txt
aws s3api put-object --bucket "$bucket" --key south/message.txt --body south/message.txt
aws s3api list-objects-v2 --bucket "$bucket" --prefix north/
aws s3api get-object --bucket "$bucket" --key north/message.txt retrieved.txt
cat retrieved.txt
lab check s3-first-object
```

The checker compares both objects with the supplied fixtures and checks the prefix listing. What happens when you list `south/` instead?

## Clean up
Duration: 4:00

```bash
aws s3api delete-object --bucket "$bucket" --key north/message.txt
aws s3api delete-object --bucket "$bucket" --key south/message.txt
terraform destroy
terraform state list
```
