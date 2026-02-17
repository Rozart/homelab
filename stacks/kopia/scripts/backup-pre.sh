#!/bin/bash
set -euo pipefail

echo "[$(date +%Y%m%dT%H%M%S)] Starting pre-backup database dumps..."

# Komodo MongoDB
echo "Dumping Komodo MongoDB..."
if docker exec komodo-db mongodump \
    --archive=/data/db/kopia-mongodump.archive.gz \
    --gzip --quiet 2>/dev/null; then
    echo "  Komodo MongoDB dump: OK"
else
    echo "  WARNING: Komodo MongoDB dump failed (container may be stopped)"
fi

# Paperless PostgreSQL
echo "Dumping Paperless PostgreSQL..."
if docker exec paperless-db pg_dumpall \
    -U paperless --clean \
    -f /var/lib/postgresql/data/kopia-pg_dumpall.sql 2>/dev/null; then
    echo "  Paperless PostgreSQL dump: OK"
else
    echo "  WARNING: Paperless PostgreSQL dump failed (container may be stopped)"
fi

echo "[$(date +%Y%m%dT%H%M%S)] Pre-backup database dumps complete."
