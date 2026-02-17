#!/bin/bash
set -euo pipefail

echo "[$(date +%Y%m%dT%H%M%S)] Starting post-backup cleanup..."

docker exec komodo-db rm -f /data/db/kopia-mongodump.archive.gz 2>/dev/null && \
    echo "  Cleaned up Komodo MongoDB dump" || true

docker exec paperless-db rm -f /var/lib/postgresql/data/kopia-pg_dumpall.sql 2>/dev/null && \
    echo "  Cleaned up Paperless PostgreSQL dump" || true

echo "[$(date +%Y%m%dT%H%M%S)] Post-backup cleanup complete."
