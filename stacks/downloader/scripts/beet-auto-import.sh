#!/usr/bin/with-contenv bash

echo "[beet-auto-import] $(date) - Scanning for completed downloads..."

for dir in /downloads/soulseek /downloads/usenet; do
    if [ -d "$dir" ]; then
        find "$dir" -mindepth 1 -maxdepth 1 -type d -mmin +30 2>/dev/null | while read -r album_dir; do
            # Skip directories with no audio files
            if [ -z "$(find "$album_dir" -name '*.flac' -o -name '*.mp3' -o -name '*.ogg' -o -name '*.m4a' 2>/dev/null | head -1)" ]; then
                continue
            fi
            echo "[beet-auto-import] Importing: $album_dir"
            beet import -q "$album_dir" 2>&1
        done
    fi
done

echo "[beet-auto-import] $(date) - Scan complete."
