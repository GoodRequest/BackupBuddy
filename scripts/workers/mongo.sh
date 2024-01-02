#!/bin/bash

# Import ENV variables with configuration for database
source /etc/cron.d/env.sh

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Starting mongo worker"

# Create timestamp which will be shared across files
FILE_TIMESTAMP=$(date +\%Y-\%m-\%d_\%H-\%M-\%S)

# Name of backup archive will be in format db_{YEAR}-{MONTH}-{DAY}_{HOURS}-{MINUTES}-{SECONDS}.tar.gz
DUMP_FILE_NAME="db_$FILE_TIMESTAMP.tar.gz"

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Dump file name: $DUMP_FILE_NAME"

# Create database dump with archive option and compress to .tar.gz
mongodump --host="$HOST" --username="$USER" --password="$PASSWORD" --db="$DATABASE" --out=./

# Compress file
tar -czf "$DUMP_FILE_NAME" "$DATABASE"

# Calculate the size of the compressed archive in bytes
ARCHIVE_SIZE_BYTES=$(stat -c %s "$DUMP_FILE_NAME")

# Save the file size to human readable format
HUMAN_READABLE_SIZE=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$ARCHIVE_SIZE_BYTES")
[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Dump finished, compressed file size is $HUMAN_READABLE_SIZE"

if [[ "$ARCHIVE_SIZE_BYTES" -gt 0 ]]; then
    case "$TARGET_TYPE" in
        FILESYSTEM)
            cp "$DUMP_FILE_NAME" "$TARGET_DIR/$DUMP_FILE_NAME"
            ;;
        AWS_S3)
            bash /scripts/utils/s3-upload.sh "$DUMP_FILE_NAME"
            ;;
    esac

    # Ping heartbeat
    bash /scripts/utils/heartbeat.sh

    # Delete old files
    bash /scripts/utils/cleanup.sh
else
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Dump file size is zero - probably corrupted file"
fi

# Delete temporary directory
rm -rf "$DATABASE"

# Delete temp file
rm "$DUMP_FILE_NAME"
