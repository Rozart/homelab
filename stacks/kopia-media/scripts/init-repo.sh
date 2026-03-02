#!/bin/bash
set -euo pipefail

CONFIG_FILE="${KOPIA_CONFIG_PATH:-/app/config/repository.config}"

# Connect to existing repository (created by docker-host Kopia)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Connecting to existing Kopia repository..."
    kopia repository connect filesystem --path=/backup-repo
else
    echo "Reconnecting to Kopia repository..."
    kopia repository connect filesystem --path=/backup-repo
fi

# Exclusions for media-host stacks
kopia policy set /stacks \
  --add-ignore "kopia-media/" \
  --add-ignore "*/appdata/cache/" \
  --add-ignore "*/appdata/logs/"

# Schedule: daily at 04:00 (offset from docker-host at 03:00)
kopia policy set /stacks \
  --snapshot-interval=24h \
  --snapshot-time=04:00 \
  --before-snapshot-root-action="/scripts/backup-pre.sh" \
  --after-snapshot-root-action="/scripts/backup-post.sh"

echo "Kopia media-host connected and policies applied."
