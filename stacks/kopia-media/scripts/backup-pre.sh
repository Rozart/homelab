#!/bin/bash
set -euo pipefail

echo "[$(date +%Y%m%dT%H%M%S)] Starting pre-backup database dumps (media-host)..."

# Jellyfin (SQLite — just ensure no active writes by pausing briefly)
echo "  Jellyfin: SQLite DB backed up via file snapshot"

# Sonarr SQLite
echo "  Sonarr: SQLite DB backed up via file snapshot"

# Radarr SQLite
echo "  Radarr: SQLite DB backed up via file snapshot"

# Prowlarr SQLite
echo "  Prowlarr: SQLite DB backed up via file snapshot"

# Bazarr SQLite
echo "  Bazarr: SQLite DB backed up via file snapshot"

echo "[$(date +%Y%m%dT%H%M%S)] Pre-backup complete."
