#!/bin/bash

# Import ENV variables with configuration for database
source /etc/cron.d/env.sh

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Trying to upload file to AWS S3"

# S3 bucket details
OBJECT_KEY="$1"  # This is the full path in S3 including the object name

# Upload the file to S3 bucket
aws s3 cp "$1" "s3://$BUCKET_NAME/$OBJECT_KEY"

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Successfully finished uploading file to AWS S3"
