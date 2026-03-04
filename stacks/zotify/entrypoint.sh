#!/bin/bash
set -euo pipefail

printenv | grep -E '^(SPOTIFY_|EPISODE_|TZ|PATH)' > /etc/environment
echo "${CRON_SCHEDULE} /usr/local/bin/download.sh >> /var/log/zotify.log 2>&1" | crontab -

echo "[$(date)] Cron scheduled: ${CRON_SCHEDULE}" > /var/log/zotify.log
cron -f
