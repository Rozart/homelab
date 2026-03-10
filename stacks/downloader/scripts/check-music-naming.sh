#!/bin/bash
# List album directories that don't follow the naming convention:
#   Artist/(Year) Album Title/
#   Artist/(Year) Album Title/CD 01/  (multi-disc)
# Run with: bash check-music-naming.sh [--verbose]

MUSIC_DIR="/mnt/nas/media/music"
VERBOSE=false

if [[ "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

count=0

find "$MUSIC_DIR" -mindepth 2 -maxdepth 2 -type d | sort | while IFS= read -r album_dir; do
    artist=$(basename "$(dirname "$album_dir")")
    album=$(basename "$album_dir")

    # Skip known special directories
    if [[ "$album" == "Non-Album" ]]; then
        continue
    fi

    # Valid: "(YYYY) Album Title" — year in parentheses followed by space
    if [[ "$album" =~ ^\([0-9]{4}\)\  ]]; then
        continue
    fi

    # Valid multi-disc subdirectory: "CD 01", "CD 02", etc. — handled at depth 3, skip here
    # (these are inside album dirs, not at album level)

    echo "$artist/$album"
    count=$((count + 1))

    if $VERBOSE; then
        if [[ "$album" == "$artist - "* ]]; then
            echo "  ^ has artist prefix, missing year"
        elif [[ "$album" =~ ^[0-9]{4}\  ]]; then
            echo "  ^ year without parentheses"
        elif [[ "$album" =~ ^\([0-9]{4}\)$ ]]; then
            echo "  ^ year only, missing album title"
        else
            echo "  ^ missing (year) prefix"
        fi
    fi
done

echo ""
echo "Total: $count improperly named directories"
