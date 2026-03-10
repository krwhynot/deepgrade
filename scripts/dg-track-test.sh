#!/bin/bash
# Three Pillars: Test/Build Tracker (PostToolUse: Bash)
# Detects test and build runs, writes session-isolated markers.
# Pure bash, no dependencies.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"$//')
SESSION_ID=$(echo "$INPUT" | grep -o '"session_id":"[^"]*"' | head -1 | sed 's/"session_id":"//;s/"$//')
[ -z "$SESSION_ID" ] && SESSION_ID="default"

[ -z "$COMMAND" ] && exit 0

# ---- Track test runs ----
IS_TEST=false
echo "$COMMAND" | grep -qE '\b(npm\s+test|npx\s+(jest|vitest)|pnpm\s+test|yarn\s+test)\b' && IS_TEST=true
echo "$COMMAND" | grep -qE '\b(jest|vitest|mocha|ava)\b' && IS_TEST=true
echo "$COMMAND" | grep -qE '\b(pytest|python.*pytest|tox)\b' && IS_TEST=true
echo "$COMMAND" | grep -qE '\b(dotnet\s+test|nunit|xunit)\b' && IS_TEST=true
echo "$COMMAND" | grep -qE '\bcargo\s+test\b' && IS_TEST=true
echo "$COMMAND" | grep -qE '\bgo\s+test\b' && IS_TEST=true

[ "$IS_TEST" = "true" ] && date +%s > "/tmp/tp-test-${SESSION_ID}"

# ---- Track build runs ----
IS_BUILD=false
echo "$COMMAND" | grep -qE '\b(npm\s+run\s+build|pnpm.*build|yarn\s+build)\b' && IS_BUILD=true
echo "$COMMAND" | grep -qE '\b(npx\s+tsc|tsc\b)' && IS_BUILD=true
echo "$COMMAND" | grep -qE '\b(dotnet\s+build|msbuild)\b' && IS_BUILD=true
echo "$COMMAND" | grep -qE '\bcargo\s+(build|check)\b' && IS_BUILD=true
echo "$COMMAND" | grep -qE '\bgo\s+(build|vet)\b' && IS_BUILD=true

[ "$IS_BUILD" = "true" ] && date +%s > "/tmp/tp-build-${SESSION_ID}"

exit 0
