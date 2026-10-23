#!/bin/bash

# This script updates your packages & pulls media-server docker container images and recreates them
# It logs the output to a directory ~/media-server/update-logs/
# Create a root cron job -> sudo crontab -e -> 0 3 * * 7 /home/<YOUR_USER>/media-server/update-logs
# Make sure to use your own full absolute path, since the job and script will run as the root user. You can keep sudo in your script for manual runs.

# Variables
LOG_DIR="/home/<YOUR_USER>/media-server/update-logs"
LOGFILE="update-log_$(date +%Y-%m-%d_%H:%M).log"
KEEP_LOGS=5

# Ensure log directory exists, create one if not.
mkdir -p "$LOG_DIR"

# Direct output to log files.
exec > >(tee -a "$LOG_DIR/$LOGFILE") 2>&1

### START UPDATE
echo "=== Update started: $(date) ==="

sudo apt update && sudo apt upgrade -y
sudo docker compose pull
sudo docker compose up --force-recreate --build -d
sudo docker image prune -f

echo "=== Update finished: $(date) ==="

# Clean up old logs: keeps the latest $KEEP_LOGS files and deletes the rest
ls -t "$LOG_DIR"/update-log_*.log 2>/dev/null | tail -n +$((KEEP_LOGS + 1)) | xargs -r rm --

### END