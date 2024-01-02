#!/bin/bash

# Import ENV variables with configuration for database
source /etc/cron.d/env.sh

# Check for any database type currently used required variables
type_database_check() {
    [[ ! -n "$HOST" ]] && echo "[ENV] Missing variable: HOST" && exit 1
    [[ ! -n "$USER" ]] && echo "[ENV] Missing variable: USER" && exit 1
    [[ ! -n "$PASSWORD" ]] && echo "[ENV] Missing variable: PASSWORD" && exit 1
    [[ ! -n "$DATABASE" ]] && echo "[ENV] Missing variable: DATABASE" && exit 1
}

# Check for filesystem backup type required variables
type_filesystem_check() {
    [[ ! -n "$FILESYSTEM_DIR" ]] && echo "[ENV] Missing variable: FILESYSTEM_DIR" && exit 1
}

# Check for filesystem backup target required variables
target_filesystem_check() {
    [[ ! -n "$TARGET_DIR" ]] && echo "[ENV] Missing variable: TARGET_DIR" && exit 1
}

# Check for AWS s3 backup target required variables
target_aws_s3_check() {
    [[ ! -n "$AWS_ACCESS_KEY_ID" ]] && echo "[ENV] Missing variable: AWS_ACCESS_KEY_ID" && exit 1
    [[ ! -n "$AWS_SECRET_ACCESS_KEY" ]] && echo "[ENV] Missing variable: AWS_SECRET_ACCESS_KEY" && exit 1
    [[ ! -n "$AWS_REGION" ]] && echo "[ENV] Missing variable: AWS_REGION" && exit 1
    [[ ! -n "$BUCKET_NAME" ]] && echo "[ENV] Missing variable: BUCKET_NAME" && exit 1
}

# Required
[[ ! -n "$TYPE" ]] && echo "[ENV] Missing variable: TYPE" && exit 1
[[ ! -n "$CRON_RULE" ]] && echo "[ENV] Missing variable: CRON_RULE" && exit 1
[[ ! -n "$KEEP_DAYS" ]] && echo "[ENV] Missing variable: KEEP_DAYS" && exit 1

# Optional defaults
[[ ! -n "$TARGET_TYPE" ]] && export TARGET_TYPE=FILESYSTEM
[[ ! -n "$PORT" ]] && export PORT=5432
[[ ! -n "$LOG_DIR" ]] && [[ -n "$DEBUG_LOGGING" ]] && export LOG_DIR=.

case "$TYPE" in
    MONGO)
        type_database_check
        ;;
    POSTGRE)
        type_database_check
        ;;
    MYSQL)
        type_database_check
        ;;
    FILESYSTEM)
        type_filesystem_check
        ;;
    *)
        echo "[ENV] Unsupported backup type"
        exit 1
esac

case "$TARGET_TYPE" in
    FILESYSTEM)
        target_filesystem_check
        ;;
    AWS_S3)
        target_aws_s3_check
        ;;
    *)
        echo "[ENV] Unsupported target type"
        exit 1
esac
