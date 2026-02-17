#!/bin/bash
set -euo pipefail

CONFIG_FILE="${KOPIA_CONFIG_PATH:-/app/config/repository.config}"

# Create repository if it doesn't exist yet
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Initializing new Kopia repository..."
    kopia repository create filesystem --path=/backup-repo
else
    echo "Connecting to existing Kopia repository..."
    kopia repository connect filesystem --path=/backup-repo
fi

# Global retention + compression (idempotent — re-applying is safe)
kopia policy set --global \
  --keep-latest 7 --keep-daily 14 --keep-weekly 8 \
  --keep-monthly 12 --keep-annual 2 \
  --compression=zstd

# Exclusions for /stacks source
kopia policy set /stacks \
  --add-ignore "bentopdf/" \
  --add-ignore "it-tools/" \
  --add-ignore "kopia/" \
  --add-ignore "appdata/" \
  --add-ignore "immich/appdata/thumbs/" \
  --add-ignore "immich/appdata/encoded-video/" \
  --add-ignore "immich/appdata/model-cache/" \
  --add-ignore "immich/appdata/postgres/" \
  --add-ignore "paperless/appdata/redis/" \
  --add-ignore "komodo/appdata/periphery/repos/"

# Schedule: daily at 03:00, with DB dump hooks
kopia policy set /stacks \
  --snapshot-interval=24h \
  --snapshot-time=03:00 \
  --before-snapshot-root-action="/scripts/backup-pre.sh" \
  --after-snapshot-root-action="/scripts/backup-post.sh"

echo "Kopia repository initialized and policies applied."
