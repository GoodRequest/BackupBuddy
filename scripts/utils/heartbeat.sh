#!/bin/bash

# Import ENV variables with configuration for database
source /etc/cron.d/env.sh

[[ -n "$DEBUG_LOGGING" ]] && echo "[DEBUG] $(date -u +'%Y-%m-%dT%H:%M:%SZ') Heartbeat URL: $HEARTBEAT_URL"

# Ping heartbeat with dump file size info
if [[ -n "$HEARTBEAT_URL" ]]; then
    wget -qO- "$HEARTBEAT_URL" && printf "\n"
fi
