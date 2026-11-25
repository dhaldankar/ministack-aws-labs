#!/usr/bin/env bash
set -euo pipefail

aws cloudtrail lookup-events --region us-east-1 \
  --start-time "$(cat change-time.txt)" \
  --lookup-attributes "AttributeKey=ResourceName,AttributeValue=$(terraform output -raw bucket)"
