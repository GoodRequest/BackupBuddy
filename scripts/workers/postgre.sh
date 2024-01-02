#!/bin/bash

# Import ENV variables with configuration for database
source /etc/cron.d/env.sh

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Starting postgres worker"

# Create timestamp which will be shared across files
FILE_TIMESTAMP=$(date +\%Y-\%m-\%d_\%H-\%M-\%S)

# Name of backup archive will be in format db_{YEAR}-{MONTH}-{DAY}_{HOURS}-{MINUTES}-{SECONDS}.gz
DUMP_FILE_NAME="db_$FILE_TIMESTAMP"

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Dump file name: $DUMP_FILE_NAME"

# Create temporary database dump
pg_dump -h "$HOST" -p "$PORT" -U "$USER" -d "$DATABASE" -f "$DUMP_FILE_NAME" $PG_DUMP_CUSTOM_OPTIONS -O -x -Fc

DUMP_SIZE_BYTES=$(stat -c %s "$DUMP_FILE_NAME")

if [[ "$DUMP_SIZE_BYTES" -gt 0 ]]; then

    # validate dump file
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Validating dump file.."
    
    # check for errors in dump file
    validation_output=$(pg_restore --list "$DUMP_FILE_NAME" 2>&1)
    
    # Check for the word "error" in validation_output
    if [[ $validation_output == *error* ]]; then
        [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Validation failed: $validation_output"
    else
        [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Validation successful: Dump file is valid."
        
        # Save the file size to human readable format
        HUMAN_READABLE_SIZE=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$DUMP_SIZE_BYTES")

        [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Dump finished, compressed file size is $HUMAN_READABLE_SIZE"

            case "$TARGET_TYPE" in
                FILESYSTEM)
                    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Copy archive in filesystem"
                    cp "$DUMP_FILE_NAME" "$TARGET_DIR/$DUMP_FILE_NAME"
                    ;;
                AWS_S3)
                    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Run AWS S3 upload script"
                    bash /scripts/utils/s3-upload.sh "$DUMP_FILE_NAME"
                    ;;
            esac

            # Ping heartbeat
            [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Run Heartbeat script"
            bash /scripts/utils/heartbeat.sh

            # Delete old files
            [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Run Cleanup script"
            bash /scripts/utils/cleanup.sh
    fi
else
    [[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Dump file size is zero - probably corrupted file"
fi

# Delete temporary dump file
rm "$DUMP_FILE_NAME"
[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Temporary dump file deleted"
