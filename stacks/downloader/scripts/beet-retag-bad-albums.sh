#!/bin/bash
# Re-import improperly named albums through beets to fix tags and naming.
# Run INSIDE the beets container: docker exec -it beets bash /config/custom-scripts/beet-retag-bad-albums.sh [--dry-run]
#
# Prerequisites:
#   1. Run fix-music-library.sh first to fix nested/duplicate artist dirs
#   2. Lidarr should be stopped or paused to avoid conflicts during retag
#
# What this does:
#   - Finds album dirs that don't match "(YYYY) Album Title" convention
#   - Re-imports them through beets (interactive, so you can confirm matches)
#   - Beets writes proper tags and moves files to correct paths
#
# After running:
#   - Start Lidarr and trigger "Refresh & Scan" on all artists

MUSIC_DIR="/music"
DRY_RUN=false
LOG_FILE="/config/retag.log"

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE - no changes will be made ==="
    echo ""
fi

count=0
retag_count=0

echo "Scanning for improperly named album directories..."
echo "$(date) - Retag scan started" >> "$LOG_FILE"

while IFS= read -r album_dir; do
    artist=$(basename "$(dirname "$album_dir")")
    album=$(basename "$album_dir")

    # Skip special directories
    [[ "$album" == "Non-Album" ]] && continue

    # Skip properly named: "(YYYY) Album Title"
    [[ "$album" =~ ^\([0-9]{4}\)\  ]] && continue

    count=$((count + 1))

    # Check if directory actually has audio files
    has_audio=$(find "$album_dir" -maxdepth 2 -type f \( -name '*.flac' -o -name '*.mp3' -o -name '*.ogg' -o -name '*.m4a' -o -name '*.opus' \) 2>/dev/null | head -1)

    if [[ -z "$has_audio" ]]; then
        echo "SKIP (no audio): $artist/$album"
        continue
    fi

    echo ""
    echo "=== [$count] $artist/$album ==="

    if $DRY_RUN; then
        echo "  [dry-run] Would run: beet import \"$album_dir\""
    else
        # Quiet import - auto-accept strong matches, keep as-is otherwise
        beet import -q "$album_dir" 2>&1 | tee -a "$LOG_FILE"
        retag_count=$((retag_count + 1))
    fi

done < <(find "$MUSIC_DIR" -mindepth 2 -maxdepth 2 -type d | sort)

echo ""
echo "=== Summary ==="
echo "Found: $count improperly named directories"
if ! $DRY_RUN; then
    echo "Processed: $retag_count directories"
fi
echo "$(date) - Retag scan complete. Found=$count Processed=$retag_count" >> "$LOG_FILE"

# Clean up empty directories left behind after moves
if ! $DRY_RUN; then
    echo ""
    echo "Cleaning up empty directories..."
    find "$MUSIC_DIR" -mindepth 2 -type d -empty -delete 2>/dev/null
fi
