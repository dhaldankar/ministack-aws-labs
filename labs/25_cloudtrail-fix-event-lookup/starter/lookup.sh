#!/usr/bin/env bash
set -euo pipefail

aws cloudtrail lookup-events --region us-west-2 \
  --start-time "$(cat change-time.txt)" \
  --lookup-attributes "AttributeKey=ResourceName,AttributeValue=$(terraform output -raw bucket)"
