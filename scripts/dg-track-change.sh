#!/bin/bash
# Three Pillars: Change Tracker (PostToolUse: Write|Edit)
# Counts file changes per session. Pure bash for core logic.
# Optional: env var drift + barrel sync (python3, skipped if unavailable).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"$//')
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"$//')
[ -z "$SESSION_ID" ] && SESSION_ID="default"

[ -z "$FILE_PATH" ] && exit 0

TRACKER="/tmp/tp-baseline-${SESSION_ID}"
THRESHOLD=${TP_CHANGE_THRESHOLD:-15}

# ---- Core: Update baseline tracker ----

if [ ! -f "$TRACKER" ]; then
  echo '{"session_changes":1,"total_changes_since_audit":1}' > "$TRACKER"
else
  # Increment counters using sed
  CURRENT=$(grep -o '"session_changes":[0-9]*' "$TRACKER" 2>/dev/null | head -1 | sed 's/"session_changes"://')
  TOTAL=$(grep -o '"total_changes_since_audit":[0-9]*' "$TRACKER" 2>/dev/null | head -1 | sed 's/"total_changes_since_audit"://')
  [ -z "$CURRENT" ] && CURRENT=0
  [ -z "$TOTAL" ] && TOTAL=0
  NEW_CURRENT=$((CURRENT + 1))
  NEW_TOTAL=$((TOTAL + 1))
  echo "{\"session_changes\":${NEW_CURRENT},\"total_changes_since_audit\":${NEW_TOTAL}}" > "$TRACKER"
fi

# Check threshold
TOTAL=$(grep -o '"total_changes_since_audit":[0-9]*' "$TRACKER" 2>/dev/null | head -1 | sed 's/"total_changes_since_audit"://')
if [ "${TOTAL:-0}" -ge "$THRESHOLD" ] 2>/dev/null; then
  echo "[Three Pillars] $TOTAL files changed since last audit. Consider /tp:codebase-delta." >&2
  exit 2
fi

exit 0
