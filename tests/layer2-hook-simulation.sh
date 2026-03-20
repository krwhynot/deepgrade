#!/usr/bin/env bash
# ===========================================================================
# DeepGrade Plugin — Layer 2: Hook Simulation Tests
# ===========================================================================
# Tests that the plugin's safety hooks (defined inline in plugin.json)
# correctly block or allow operations when given canned JSON payloads.
#
# Each hook is a bash one-liner embedded in plugin.json.  We extract them
# with jq and feed test JSON via stdin, then assert on exit code / stderr.
#
# Exit 0 = all tests pass.  Exit 1 = at least one failure.
# ===========================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_JSON="$SCRIPT_DIR/../.claude-plugin/plugin.json"
PASS=0
FAIL=0

# ------------------------------------------------------------------
# Cleanup trap — remove all temp files created during tests
# ------------------------------------------------------------------
cleanup() {
  rm -f /tmp/dg-baseline-test-session-* /tmp/dg-test-test-session-* /tmp/dg-build-test-session-*
  # Also remove the dummy migration file used by Test 1
  rm -f /tmp/_dg_layer2_dummy_migration.sql
}
trap cleanup EXIT

# ------------------------------------------------------------------
# Verify prerequisites
# ------------------------------------------------------------------
if [ ! -f "$PLUGIN_JSON" ]; then
  echo "FATAL: plugin.json not found at $PLUGIN_JSON" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "FATAL: jq is required for Layer 2 tests. Install with: winget install jqlang.jq" >&2
  exit 1
fi

# ------------------------------------------------------------------
# Extract hook commands from plugin.json
# ------------------------------------------------------------------
# PreToolUse hooks (index 0 = Write|Edit matcher, index 1 = Bash matcher)
HOOK_PRE_WRITE=$(jq -r '.hooks.PreToolUse[0].hooks[0].command' "$PLUGIN_JSON")
HOOK_PRE_BASH=$(jq -r '.hooks.PreToolUse[1].hooks[0].command' "$PLUGIN_JSON")

# PostToolUse hooks (index 0 = Write|Edit matcher, index 1 = Bash matcher)
HOOK_POST_WRITE=$(jq -r '.hooks.PostToolUse[0].hooks[0].command' "$PLUGIN_JSON")
HOOK_POST_BASH=$(jq -r '.hooks.PostToolUse[1].hooks[0].command' "$PLUGIN_JSON")

# Quick sanity: make sure we actually got something
for varname in HOOK_PRE_WRITE HOOK_PRE_BASH HOOK_POST_WRITE HOOK_POST_BASH; do
  val="${!varname}"
  if [ -z "$val" ] || [ "$val" = "null" ]; then
    echo "FATAL: Failed to extract hook command for $varname" >&2
    exit 1
  fi
done

# ------------------------------------------------------------------
# Test helpers
# ------------------------------------------------------------------
run_hook() {
  # $1 = hook command string
  # $2 = JSON payload (piped via stdin)
  # Captures exit code, stdout, stderr
  local hook_cmd="$1"
  local payload="$2"

  # We run in a subshell to isolate set -e
  HOOK_STDOUT=""
  HOOK_STDERR=""
  HOOK_EXIT=0

  # Use temp files for stdout/stderr capture
  local tmp_out tmp_err
  tmp_out=$(mktemp)
  tmp_err=$(mktemp)

  set +e
  echo "$payload" | eval "$hook_cmd" >"$tmp_out" 2>"$tmp_err"
  HOOK_EXIT=$?
  set -e

  HOOK_STDOUT=$(cat "$tmp_out")
  HOOK_STDERR=$(cat "$tmp_err")
  rm -f "$tmp_out" "$tmp_err"
}

assert_pass() {
  local test_name="$1"
  PASS=$((PASS + 1))
  echo "  [PASS] $test_name"
}

assert_fail() {
  local test_name="$1"
  local reason="$2"
  FAIL=$((FAIL + 1))
  echo "  [FAIL] $test_name — $reason"
}

# assert_exit <test_name> <expected_exit>
assert_exit() {
  local name="$1"
  local expected="$2"
  if [ "$HOOK_EXIT" -eq "$expected" ]; then
    return 0
  else
    return 1
  fi
}

# assert_stderr_contains <substring>
assert_stderr_contains() {
  local substring="$1"
  if echo "$HOOK_STDERR" | grep -qi "$substring"; then
    return 0
  else
    return 1
  fi
}

# assert_stderr_empty
assert_stderr_empty() {
  if [ -z "$HOOK_STDERR" ]; then
    return 0
  else
    return 1
  fi
}

# ------------------------------------------------------------------
# Banner
# ------------------------------------------------------------------
echo "=== DeepGrade Plugin: Layer 2 — Hook Simulation Tests ==="
echo ""
echo "Plugin: $PLUGIN_JSON"
echo ""

# ==================================================================
# Migration Guard (PreToolUse Write|Edit)
# ==================================================================
echo "--- Migration Guard ---"

# Test 1: SHOULD BLOCK — editing existing migration file
# The hook checks [ ! -f "$F" ] && exit 0, so the file must exist.
# Create a dummy file to simulate an existing migration.
DUMMY_MIG="/tmp/_dg_layer2_dummy_migration.sql"
mkdir -p "$(dirname "$DUMMY_MIG")"
echo "-- dummy" > "$DUMMY_MIG"

# The hook extracts file_path from tool_input, then checks if the path
# contains /migrations/ or /Migrations/ and ends in .sql, and the file exists.
# We need to pass a path that: (a) contains /migrations/, (b) ends .sql, (c) exists on disk.
# We'll use a path that actually exists — our dummy file won't match because
# it's in /tmp, not under */migrations/*.  So we create a temp migrations dir.
TEST_MIG_DIR=$(mktemp -d)
mkdir -p "$TEST_MIG_DIR/src/migrations"
echo "-- existing migration" > "$TEST_MIG_DIR/src/migrations/20240101_init.sql"

# We need to run the hook from a context where the file path resolves.
# The hook converts backslashes to forward slashes and checks -f on the path.
# We pass the full absolute path.
MIG_FILE="$TEST_MIG_DIR/src/migrations/20240101_init.sql"

run_hook "$HOOK_PRE_WRITE" "{\"tool_input\": {\"file_path\": \"$MIG_FILE\"}}"
if [ "$HOOK_EXIT" -eq 2 ] && assert_stderr_contains "MIGRATION GUARD"; then
  assert_pass "Blocks editing existing migration file (exit 2)"
else
  assert_fail "Blocks editing existing migration file (exit 2)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 2: SHOULD ALLOW — editing non-migration file
run_hook "$HOOK_PRE_WRITE" '{"tool_input": {"file_path": "src/models/User.cs"}}'
if [ "$HOOK_EXIT" -eq 0 ] && assert_stderr_empty; then
  assert_pass "Allows editing non-migration file (exit 0)"
else
  assert_fail "Allows editing non-migration file (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 3: SHOULD ALLOW — editing migration file that doesn't exist yet (new migration)
# The guard checks [ ! -f "$F" ] && exit 0, so non-existent files pass through.
run_hook "$HOOK_PRE_WRITE" '{"tool_input": {"file_path": "src/migrations/20260319_new.sql"}}'
if [ "$HOOK_EXIT" -eq 0 ]; then
  assert_pass "Allows new migration file that does not exist (exit 0)"
else
  assert_fail "Allows new migration file that does not exist (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Clean up temp migration dir
rm -rf "$TEST_MIG_DIR"
echo ""

# ==================================================================
# Git Guard (PreToolUse Bash)
# ==================================================================
echo "--- Git Guard ---"

# Test 4: SHOULD BLOCK — force push
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "git push --force origin main"}}'
if [ "$HOOK_EXIT" -eq 2 ] && assert_stderr_contains "BLOCKED"; then
  assert_pass "Blocks force push (exit 2)"
else
  assert_fail "Blocks force push (exit 2)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 5: SHOULD BLOCK — hard reset
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "git reset --hard HEAD~1"}}'
if [ "$HOOK_EXIT" -eq 2 ] && assert_stderr_contains "WARNING"; then
  assert_pass "Blocks hard reset (exit 2)"
else
  assert_fail "Blocks hard reset (exit 2)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 6: SHOULD ALLOW — normal git push
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "git push origin main"}}'
if [ "$HOOK_EXIT" -eq 0 ]; then
  assert_pass "Allows normal push (exit 0)"
else
  assert_fail "Allows normal push (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 7: SHOULD ALLOW — soft reset
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "git reset --soft HEAD~1"}}'
if [ "$HOOK_EXIT" -eq 0 ]; then
  assert_pass "Allows soft reset (exit 0)"
else
  assert_fail "Allows soft reset (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

echo ""

# ==================================================================
# DB Deploy Guard (PreToolUse Bash — same hook as git guard)
# ==================================================================
echo "--- DB Deploy Guard ---"

# Test 8: SHOULD BLOCK — supabase db push (no --dry-run)
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "supabase db push"}}'
if [ "$HOOK_EXIT" -eq 2 ] && assert_stderr_contains "BLOCKED"; then
  assert_pass "Blocks supabase db push without --dry-run (exit 2)"
else
  assert_fail "Blocks supabase db push without --dry-run (exit 2)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 9: SHOULD ALLOW — supabase db push --dry-run
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "supabase db push --dry-run"}}'
if [ "$HOOK_EXIT" -eq 0 ]; then
  assert_pass "Allows supabase db push --dry-run (exit 0)"
else
  assert_fail "Allows supabase db push --dry-run (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 10: SHOULD ALLOW — supabase db push --local
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "supabase db push --local"}}'
if [ "$HOOK_EXIT" -eq 0 ]; then
  assert_pass "Allows supabase db push --local (exit 0)"
else
  assert_fail "Allows supabase db push --local (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 11: SHOULD BLOCK — prisma migrate deploy
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "prisma migrate deploy"}}'
if [ "$HOOK_EXIT" -eq 2 ]; then
  assert_pass "Blocks prisma migrate deploy (exit 2)"
else
  assert_fail "Blocks prisma migrate deploy (exit 2)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

# Test 12: SHOULD ALLOW — rails db:migrate with RAILS_ENV=test
run_hook "$HOOK_PRE_BASH" '{"tool_input": {"command": "RAILS_ENV=test rails db:migrate"}}'
if [ "$HOOK_EXIT" -eq 0 ]; then
  assert_pass "Allows rails db:migrate with RAILS_ENV=test (exit 0)"
else
  assert_fail "Allows rails db:migrate with RAILS_ENV=test (exit 0)" "exit=$HOOK_EXIT stderr='$HOOK_STDERR'"
fi

echo ""

# ==================================================================
# Change Tracker (PostToolUse Write|Edit)
# ==================================================================
echo "--- Change Tracker ---"

# Test 13: SHOULD INCREMENT — track a file change
SESSION="test-session-123"
TRACKER_FILE="/tmp/dg-baseline-$SESSION"
rm -f "$TRACKER_FILE"

run_hook "$HOOK_POST_WRITE" "{\"session_id\": \"$SESSION\"}"

if [ -f "$TRACKER_FILE" ]; then
  COUNT_1=$(jq -r '.session_changes' "$TRACKER_FILE" 2>/dev/null)
  if [ "$COUNT_1" = "1" ]; then
    # Run again — should increment to 2
    run_hook "$HOOK_POST_WRITE" "{\"session_id\": \"$SESSION\"}"
    COUNT_2=$(jq -r '.session_changes' "$TRACKER_FILE" 2>/dev/null)
    if [ "$COUNT_2" = "2" ]; then
      assert_pass "Increments session change count (1 -> 2)"
    else
      assert_fail "Increments session change count (1 -> 2)" "second run: session_changes=$COUNT_2 (expected 2)"
    fi
  else
    assert_fail "Increments session change count (1 -> 2)" "first run: session_changes=$COUNT_1 (expected 1)"
  fi
else
  assert_fail "Increments session change count (1 -> 2)" "tracker file not created at $TRACKER_FILE"
fi

echo ""

# ==================================================================
# Test/Build Tracker (PostToolUse Bash)
# ==================================================================
echo "--- Test/Build Tracker ---"

# Test 14: SHOULD TRACK — npm test
SESSION_TEST="test-session-456"
rm -f "/tmp/dg-test-$SESSION_TEST"

run_hook "$HOOK_POST_BASH" "{\"tool_input\": {\"command\": \"npm test\"}, \"session_id\": \"$SESSION_TEST\"}"
if [ -f "/tmp/dg-test-$SESSION_TEST" ]; then
  assert_pass "Tracks npm test invocation"
else
  assert_fail "Tracks npm test invocation" "tracker file /tmp/dg-test-$SESSION_TEST not created"
fi

# Test 15: SHOULD NOT TRACK — ls command
SESSION_LS="test-session-789"
rm -f "/tmp/dg-test-$SESSION_LS"

run_hook "$HOOK_POST_BASH" "{\"tool_input\": {\"command\": \"ls -la\"}, \"session_id\": \"$SESSION_LS\"}"
if [ ! -f "/tmp/dg-test-$SESSION_LS" ]; then
  assert_pass "Ignores non-test commands (ls -la)"
else
  assert_fail "Ignores non-test commands (ls -la)" "tracker file /tmp/dg-test-$SESSION_LS was unexpectedly created"
fi

echo ""

# ==================================================================
# Summary
# ==================================================================
TOTAL=$((PASS + FAIL))
echo "=== Results: $PASS passed, $FAIL failed (of $TOTAL tests) ==="

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
