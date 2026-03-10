#!/usr/bin/with-contenv bash

echo "[beet-auto-import] $(date) - Scanning for completed downloads..."

# Scan music-related download directories (not audiobooks/ebooks)
# Soulseek: everything is music, scan root
# Usenet/Torrents: only scan music category subdirs, plus root for uncategorized
SCAN_DIRS="/downloads/soulseek /downloads/usenet/music /downloads/usenet/lidarr /downloads/torrents/music /downloads/torrents/lidarr"

for dir in $SCAN_DIRS; do
    if [ -d "$dir" ]; then
        find "$dir" -mindepth 1 -maxdepth 1 -type d -mmin +30 2>/dev/null | while read -r album_dir; do
            # Skip directories with no audio files
            if [ -z "$(find "$album_dir" -name '*.flac' -o -name '*.mp3' -o -name '*.ogg' -o -name '*.m4a' 2>/dev/null | head -1)" ]; then
                continue
            fi
            echo "[beet-auto-import] Importing: $album_dir"
            beet import -q "$album_dir" 2>&1
        done

        # Clean up directories with no audio files remaining (only leftover .nfo, .jpg, etc.)
        find "$dir" -mindepth 1 -maxdepth 1 -type d -mmin +30 2>/dev/null | while read -r album_dir; do
            if [ -z "$(find "$album_dir" -name '*.flac' -o -name '*.mp3' -o -name '*.ogg' -o -name '*.m4a' 2>/dev/null | head -1)" ]; then
                echo "[beet-auto-import] Cleaning up: $album_dir"
                rm -rf "$album_dir"
            fi
        done
    fi
done

# Clean up singleton audio files (loose .flac/.mp3 not in album dirs)
for dir in $SCAN_DIRS; do
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 1 -type f \( -name '*.flac' -o -name '*.mp3' -o -name '*.ogg' -o -name '*.m4a' \) -mmin +30 2>/dev/null | while read -r file; do
            echo "[beet-auto-import] Importing singleton: $file"
            beet import -q -s "$file" 2>&1
        done
    fi
done

echo "[beet-auto-import] $(date) - Scan complete."
