#!/bin/bash
# DeepGrade: Stop hook
# 1. Session summary
# 2. Test verification (warn if source changed but no tests ran)
# Pure bash, no dependencies.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"$//')
[ -z "$SESSION_ID" ] && SESSION_ID="default"

TRACKER="/tmp/dg-baseline-${SESSION_ID}"
TEST_MARKER="/tmp/dg-test-${SESSION_ID}"

# ---- Session summary ----

if [ -f "$TRACKER" ]; then
  CHANGES=$(grep -o '"session_changes":[0-9]*' "$TRACKER" 2>/dev/null | head -1 | sed 's/"session_changes"://')

  if [ "${CHANGES:-0}" -gt 0 ] 2>/dev/null; then
    # Check if tests ran
    if [ ! -f "$TEST_MARKER" ]; then
      # Check if project has tests
      HAS_TESTS=false
      if [ -f "package.json" ]; then
        grep -q '"test"' package.json && HAS_TESTS=true
      fi
      [ -f "pytest.ini" ] || [ -f "conftest.py" ] && HAS_TESTS=true

      if [ "$HAS_TESTS" = "true" ]; then
        echo "[DeepGrade] $CHANGES files changed but no tests ran. Run tests before finishing." >&2
        exit 0
      fi
    fi

    echo "[DeepGrade] Session: $CHANGES files changed." >&2
    exit 0
  fi
fi

exit 0
