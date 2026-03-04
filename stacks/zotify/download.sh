#!/bin/bash
set -euo pipefail

OUTPUT_DIR="/podcasts"
LIMIT="${1:-${EPISODE_LIMIT:-1}}"
LOG="/var/log/zotify.log"

echo "[$(date)] Starting download (limit: $LIMIT)" >> "$LOG"

# Start zotify in background with rate limiting between episodes
zotify "$SPOTIFY_SHOW_URL" \
  --root-podcast-path "$OUTPUT_DIR" \
  --skip-existing true \
  --bulk-wait-time 5 &
ZOTIFY_PID=$!

trap 'kill $ZOTIFY_PID 2>/dev/null; wait $ZOTIFY_PID 2>/dev/null' EXIT

COUNT=0
while true; do
  # Wait up to 120s for a file to be fully written and closed
  # inotifywait CLOSE_WRITE only fires after the file is complete — no partial files
  FILE=$(inotifywait -r -e close_write --format '%w%f' --timeout 120 "$OUTPUT_DIR" 2>/dev/null) || {
    # Timeout or error — if zotify exited (all done or crashed), stop waiting
    kill -0 "$ZOTIFY_PID" 2>/dev/null || break
    continue
  }

  # Only count audio files, ignore metadata/artwork
  case "$FILE" in
    *.ogg|*.mp3|*.m4a|*.mp4)
      COUNT=$((COUNT + 1))
      echo "[$(date)] [$COUNT/$LIMIT] $(basename "$FILE")" >> "$LOG"
      if [ "$COUNT" -ge "$LIMIT" ]; then
        echo "[$(date)] Limit reached, stopping zotify" >> "$LOG"
        kill "$ZOTIFY_PID" 2>/dev/null || true
        break
      fi
      ;;
  esac
done

# After killing zotify, a file may have been mid-download — remove it
# so it doesn't get skipped forever on the next run
sleep 2
find "$OUTPUT_DIR" -maxdepth 2 -type f \
  \( -name '*.ogg' -o -name '*.mp3' -o -name '*.m4a' -o -name '*.mp4' \
     -o -name '*.part' -o -name '*.tmp' \) \
  -newermt '-10 seconds' -print -delete 2>/dev/null | while IFS= read -r f; do
    echo "[$(date)] Removed partial: $(basename "$f")" >> "$LOG"
done

trap - EXIT
wait "$ZOTIFY_PID" 2>/dev/null || true

echo "[$(date)] Session complete: $COUNT episode(s) downloaded" >> "$LOG"
