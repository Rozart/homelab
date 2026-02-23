#!/bin/sh
set -e

BISYNC_CONF="/config/rclone/bisync.conf"

echo "Waiting for initial rclone config..."
while [ ! -f /config/rclone/rclone.conf ]; do
  echo "No rclone.conf found. Run: docker exec -it nextcloud_rclone rclone config"
  sleep 60
done

if [ ! -f "$BISYNC_CONF" ]; then
  echo "No bisync.conf found at $BISYNC_CONF"
  echo "Create it with lines in format: <remote>:<remote-path>|<local-folder>"
  sleep 60
  exit 1
fi

echo "Starting bisync loop"
while true; do
  while IFS='|' read -r remote_path local_folder; do
    # skip empty lines and comments
    case "$remote_path" in ''|' '*|\#*) continue ;; esac

    echo "[$(date)] Syncing $remote_path -> /data/$local_folder"
    rclone bisync "$remote_path" "/data/$local_folder" \
      --conflict-resolve newer \
      --resilient \
      --recover \
      --fix-case \
      --drive-skip-dangling-shortcuts \
      -v || echo "[$(date)] WARNING: bisync failed for $remote_path"
  done < "$BISYNC_CONF"
  echo "[$(date)] Sleeping ${RCLONE_BISYNC_INTERVAL:-15m}..."
  sleep "${RCLONE_BISYNC_INTERVAL:-15m}"
done
