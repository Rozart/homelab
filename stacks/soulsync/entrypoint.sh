#!/bin/bash
# SoulSync Docker Entrypoint Script (patched)
# Makes chown non-fatal on NAS-mounted directories (NFS root_squash)

set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-022}

echo "🐳 SoulSync Container Starting..."
echo "📝 User Configuration:"
echo "   PUID: $PUID"
echo "   PGID: $PGID"
echo "   UMASK: $UMASK"

CURRENT_UID=$(id -u soulsync)
CURRENT_GID=$(id -g soulsync)

if [ "$CURRENT_UID" != "$PUID" ] || [ "$CURRENT_GID" != "$PGID" ]; then
    echo "🔧 Adjusting user permissions..."

    if [ "$CURRENT_GID" != "$PGID" ]; then
        echo "   Changing group ID from $CURRENT_GID to $PGID"
        groupmod -o -g "$PGID" soulsync
    fi

    if [ "$CURRENT_UID" != "$PUID" ]; then
        echo "   Changing user ID from $CURRENT_UID to $PUID"
        usermod -o -u "$PUID" soulsync
    fi

    echo "🔒 Fixing permissions on app directories..."
    chown -R soulsync:soulsync /app/config /app/data /app/logs /app/downloads /app/Transfer /app/Staging 2>/dev/null || true
else
    echo "✅ User/Group IDs already correct"
fi

echo "🎭 Setting UMASK to $UMASK"
umask "$UMASK"

echo "🔍 Checking for configuration files..."

if [ ! -f "/app/config/config.json" ]; then
    echo "   📄 Creating default config.json..."
    cp /defaults/config.json /app/config/config.json
    chown soulsync:soulsync /app/config/config.json
else
    echo "   ✅ config.json already exists"
fi

if [ ! -f "/app/config/settings.py" ]; then
    echo "   📄 Creating default settings.py..."
    cp /defaults/settings.py /app/config/settings.py
    chown soulsync:soulsync /app/config/settings.py
else
    echo "   ✅ settings.py already exists"
fi

mkdir -p /app/config /app/data /app/logs /app/downloads /app/Transfer /app/Staging
chown -R soulsync:soulsync /app/config /app/data /app/logs /app/downloads /app/Staging
chown -R soulsync:soulsync /app/Transfer 2>/dev/null || echo "⚠️  Skipping chown on /app/Transfer (NAS mount)"

echo "✅ Configuration initialized successfully"

echo "👤 Running as:"
echo "   User: $(id -u soulsync):$(id -g soulsync) ($(id -un soulsync):$(id -gn soulsync))"
echo "   UMASK: $(umask)"
echo ""
echo "🚀 Starting SoulSync Web Server..."

exec gosu soulsync "$@"
