#!/bin/bash
# DeepGrade: Git Guard (PreToolUse: Bash)
# Layer 1: Block force push, warn hard reset
# Layer 2: Staging count sanity check
# Layer 3: Build verification before commit
# Pure bash, no dependencies.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"$//')
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"$//')
[ -z "$SESSION_ID" ] && SESSION_ID="default"

[ -z "$COMMAND" ] && exit 0

# ---- LAYER 1: Block dangerous git operations ----

if echo "$COMMAND" | grep -qE 'git\s+push.*--force\b'; then
  echo "BLOCKED: Force push is not allowed. Use --force-with-lease if needed." >&2
  exit 2
fi

if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "WARNING: git reset --hard will discard all uncommitted changes. Are you sure?" >&2
  exit 2
fi

# Only continue checks for git commit or push
echo "$COMMAND" | grep -qE 'git\s+(commit|push)' || exit 0

# ---- LAYER 2: Staging count sanity check ----

if echo "$COMMAND" | grep -qE 'git\s+commit'; then
  STAGED_COUNT=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
  TRACKER="/tmp/dg-baseline-${SESSION_ID}"

  if [ -f "$TRACKER" ] && [ "$STAGED_COUNT" -gt 0 ]; then
    SESSION_EDITS=$(grep -o '"session_changes":[0-9]*' "$TRACKER" 2>/dev/null | head -1 | sed 's/"session_changes"://')
    [ -z "$SESSION_EDITS" ] && SESSION_EDITS=0
    if [ "$SESSION_EDITS" -gt 0 ] 2>/dev/null; then
      THRESHOLD=$((SESSION_EDITS * 2 + 5))
      if [ "$STAGED_COUNT" -gt "$THRESHOLD" ] 2>/dev/null; then
        echo "STAGING CHECK: Edited $SESSION_EDITS files but $STAGED_COUNT staged. Run 'git diff --cached --stat' to review." >&2
        exit 2
      fi
    fi
  fi
fi

# ---- LAYER 3: Build verification ----

BUILD_MARKER="/tmp/dg-build-${SESSION_ID}"
if [ -f "$BUILD_MARKER" ]; then
  if [ "$(find "$BUILD_MARKER" -mmin -120 2>/dev/null)" ]; then
    exit 0
  fi
fi

# Detect build command
BUILD_CMD=""
if [ -f "package.json" ]; then
  grep -q '"build"' package.json && BUILD_CMD="npm run build"
  grep -q '"typecheck"' package.json && [ -z "$BUILD_CMD" ] && BUILD_CMD="npm run typecheck"
fi
[ -z "$BUILD_CMD" ] && ls *.sln 2>/dev/null | head -1 >/dev/null && BUILD_CMD="dotnet build"
[ -z "$BUILD_CMD" ] && [ -f "Cargo.toml" ] && BUILD_CMD="cargo check"
[ -z "$BUILD_CMD" ] && [ -f "go.mod" ] && BUILD_CMD="go vet ./..."

[ -z "$BUILD_CMD" ] && exit 0

echo "BUILD CHECK: No successful build this session. Run '$BUILD_CMD' first." >&2
exit 2
