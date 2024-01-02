#!/bin/bash

# Import ENV variables with configuration for database
source /etc/cron.d/env.sh

fs_cleanup() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Checking for old files in filesystem"

    # Remove all backups older than XY days defined by ENV variable KEEP_DAYS
    DELETED_COUNT=$(find "$TARGET_DIR" -mtime +"$KEEP_DAYS" -type f -exec rm -f {} \; | wc -c)

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Filesystem cleanup complete, deleted $DELETED_COUNT files"
}

s3_cleanup() {
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Checking for old files in S3"

    # Calculate the date XY days ago from the current date
    OLD_DATE=$(date -u -d "$KEEP_DAYS days ago" +%Y-%m-%d)

    # List object metadata in the S3 bucket
    OBJECTS=$(aws s3api list-objects --bucket "$BUCKET_NAME" --query "Contents[?LastModified<'$OLD_DATE'].Key" --output text)

    # Initialize a counter for deleted files
    DELETED_COUNT=0

    if [[ -n "$OBJECTS" ]] && [[ "$OBJECTS" != "[]" ]]; then
        # Extract and process object metadata
        for FILE_NAME in $OBJECTS; do
            aws s3 rm "s3://$BUCKET_NAME/$FILE_NAME"
            [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Deleted from S3: $FILE_NAME"
            ((DELETED_COUNT++))
        done
    fi

    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') S3 cleanup complete, deleted $DELETED_COUNT files"
}

# Choose what target we are checking
case "$TARGET_TYPE" in
    FILESYSTEM)
        fs_cleanup
        ;;
    AWS_S3)
        s3_cleanup
        ;;
esac
