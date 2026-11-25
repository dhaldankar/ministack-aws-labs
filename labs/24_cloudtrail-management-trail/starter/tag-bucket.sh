#!/usr/bin/env bash
set -euo pipefail

bucket=$(terraform output -raw bucket)
date -u +%Y-%m-%dT%H:%M:%SZ > change-time.txt
aws s3api put-bucket-tagging --bucket "$bucket" \
  --tagging 'TagSet=[{Key=Lab,Value=cloudtrail}]'
