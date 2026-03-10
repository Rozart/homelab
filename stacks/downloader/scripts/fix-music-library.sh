#!/bin/bash
# Fix duplicate and nested artist directories in the music library
# Run with: bash fix-music-library.sh [--dry-run]

MUSIC_DIR="/mnt/nas/media/music"
DRY_RUN=false

if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE - no changes will be made ==="
    echo ""
fi

run_cmd() {
    if $DRY_RUN; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

echo "=== Step 1: Merge case-duplicate artist folders ==="
echo ""

# Find case-insensitive duplicates (use python for proper unicode lowercasing)
declare -A seen
while IFS= read -r artist_dir; do
    name=$(basename "$artist_dir")
    lower=$(python3 -c "print('$name'.lower())" 2>/dev/null || echo "$name" | tr '[:upper:]' '[:lower:]')

    if [[ -n "${seen[$lower]}" ]]; then
        canonical="${seen[$lower]}"
        echo "Merging: '$name' → '$(basename "$canonical")'"

        find "$artist_dir" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r subdir; do
            target="$canonical/$(basename "$subdir")"
            if [[ -d "$target" ]]; then
                echo "  Duplicate, removing nested: $(basename "$subdir")"
                run_cmd rm -rf "$subdir"
            else
                run_cmd mv "$subdir" "$canonical/"
            fi
        done

        find "$artist_dir" -mindepth 1 -maxdepth 1 -type f | while IFS= read -r file; do
            target="$canonical/$(basename "$file")"
            if [[ -e "$target" ]]; then
                run_cmd rm -f "$file"
            else
                run_cmd mv "$file" "$canonical/"
            fi
        done

        run_cmd rm -rf "$artist_dir" 2>/dev/null
        echo ""
    else
        seen[$lower]="$artist_dir"
    fi
done < <(find "$MUSIC_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

echo "=== Step 2: Fix nested 'Artist/Artist' directories ==="
echo ""

find "$MUSIC_DIR" -mindepth 2 -maxdepth 2 -type d | while IFS= read -r subdir; do
    parent=$(basename "$(dirname "$subdir")")
    child=$(basename "$subdir")

    if [[ "$child" == "$parent" ]]; then
        echo "Unnesting: $parent/$child/"

        find "$subdir" -mindepth 1 -maxdepth 1 | while IFS= read -r item; do
            target="$(dirname "$subdir")/$(basename "$item")"
            if [[ -e "$target" ]]; then
                echo "  Exists at parent, removing nested copy: $(basename "$item")"
                run_cmd rm -rf "$item"
            else
                echo "  Moving up: $(basename "$item")"
                run_cmd mv "$item" "$(dirname "$subdir")/"
            fi
        done

        run_cmd rm -rf "$subdir" 2>/dev/null
        echo ""
    fi
done

echo "=== Step 3: Fix 'Artist/Artist - Album' directories (strip artist prefix) ==="
echo ""

find "$MUSIC_DIR" -mindepth 2 -maxdepth 2 -type d | while IFS= read -r subdir; do
    parent=$(basename "$(dirname "$subdir")")
    child=$(basename "$subdir")

    if [[ "$child" == "$parent - "* ]]; then
        album_name="${child#"$parent - "}"
        new_path="$(dirname "$subdir")/$album_name"

        echo "Renaming: $parent/$child → $parent/$album_name"

        if [[ -e "$new_path" ]]; then
            echo "  Target exists, removing duplicate"
            run_cmd rm -rf "$subdir"
        else
            run_cmd mv "$subdir" "$new_path"
        fi
        echo ""
    fi
done

echo "=== Step 4: Clean up empty directories ==="
if $DRY_RUN; then
    find "$MUSIC_DIR" -mindepth 2 -type d -empty 2>/dev/null | while IFS= read -r d; do
        echo "  [dry-run] Would remove empty dir: $d"
    done
else
    find "$MUSIC_DIR" -mindepth 2 -type d -empty -delete 2>/dev/null
fi

echo ""
echo "=== Done ==="
