#!/bin/bash

# Import ENV variables with configuration
source /etc/cron.d/env.sh

echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Starting filesystem worker"

# Create timestamp which will be shared across files
FILE_TIMESTAMP=$(date +\%Y-\%m-\%d_\%H-\%M-\%S)

# Name of backup archive will be in the format fs_{YEAR}-{MONTH}-{DAY}_{HOURS}-{MINUTES}-{SECONDS}.tar.gz
BACKUP_FILE_NAME="fs_$FILE_TIMESTAMP.tar.gz"

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Backup file name: $BACKUP_FILE_NAME"

# Create TAR archive from filesystem directory and compress it using gzip
tar -czf "$BACKUP_FILE_NAME" "$FILESYSTEM_DIR"

# Calculate the size of the compressed archive in bytes
ARCHIVE_SIZE_BYTES=$(stat -c %s "$BACKUP_FILE_NAME")

# Convert bytes to human-readable format
HUMAN_READABLE_SIZE=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$ARCHIVE_SIZE_BYTES")
[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Compression finished, compressed file size is $HUMAN_READABLE_SIZE"

if [[ "$ARCHIVE_SIZE_BYTES" -gt 0 ]]; then
    case "$TARGET_TYPE" in
        FILESYSTEM)
            cp "$BACKUP_FILE_NAME" "$TARGET_DIR/$BACKUP_FILE_NAME"
            ;;
        AWS_S3)
            bash /scripts/utils/s3-upload.sh "$BACKUP_FILE_NAME"
            ;;
    esac

    # Ping heartbeat
    bash /scripts/utils/heartbeat.sh

    # Delete old files
    bash /scripts/utils/cleanup.sh
else
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Archive file size is zero - probably corrupted file"
fi

# Delete temp file
rm "$BACKUP_FILE_NAME"
