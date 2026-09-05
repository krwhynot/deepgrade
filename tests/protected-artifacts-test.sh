#!/usr/bin/env bash
# Tests for .github/protected-artifacts.sh.
#
# The rule it enforces lived in prose for three releases (LEDGER-HEADER.md,
# plan-workspace.md) and nothing checked it. A check that is never shown to
# refuse is prose with an exit code, so every mutation class gets a falsifying
# case, and the scope boundary (evidence/ is NOT protected) gets one too — a
# check that fails on the wrong files gets switched off the first time it bites.
#
# Same scratch-clone discipline as release-preflight-test.sh: the script under
# test is copied in and committed, and every violation is committed too, so the
# ci modes have real ranges to diff.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0; FAIL=0
pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== Protected artifacts tests ==="

[ -f "$ROOT/.github/protected-artifacts.sh" ] || { fail "script exists at .github/protected-artifacts.sh"; echo "Results: 0 passed, 1 failed"; exit 1; }

SCRATCH=$(mktemp -d)
trap 'cd "$ROOT"; rm -rf "$SCRATCH"' EXIT
git clone -q --local --no-hardlinks "$ROOT" "$SCRATCH/repo"
cd "$SCRATCH/repo"
git config user.email test@test && git config user.name test
git checkout -q -B main

mkdir -p .github
cp "$ROOT/.github/protected-artifacts.sh" .github/protected-artifacts.sh
git add -A && git commit -qm "test: stage script under test"
BASE=$(git rev-parse HEAD)

SNAP=$(git ls-files 'docs/plans/*/snapshots/*' | grep -v HASHES | head -1)
CR=$(git ls-files 'docs/plans/*/changes/CR-*.md' | head -1)
EV=$(git ls-files 'docs/plans/*/evidence/*.json' | head -1)
[ -n "$SNAP" ] && [ -n "$CR" ] && [ -n "$EV" ] || { fail "fixtures: need one snapshot, one CR and one evidence record in the tree"; echo "Results: $PASS passed, $((FAIL+1)) failed"; exit 1; }
CRDIR=$(dirname "$CR")

run_local()    { bash .github/protected-artifacts.sh local "$@" >/dev/null 2>&1; }
run_ci_push()  { GITHUB_EVENT_NAME=push PUSH_BEFORE_SHA="$1" GITHUB_SHA="$2" bash .github/protected-artifacts.sh ci >/dev/null 2>&1; }
reset()        { git reset -q --hard "$BASE"; git clean -qfd; }

# --- control -----------------------------------------------------------------
run_local && pass "control: clean tree passes (staged)" || fail "control: clean tree passes (staged)"
run_local --worktree && pass "control: clean tree passes (worktree)" || fail "control: clean tree passes (worktree)"

# --- each mutation class, local staged ---------------------------------------
echo "tampered" >> "$SNAP"; git add -- "$SNAP"
run_local; [ $? -eq 1 ] && pass "M: modified snapshot refused" || fail "M: modified snapshot refused"
reset

echo "tampered" >> "$CR"; git add -- "$CR"
run_local; [ $? -eq 1 ] && pass "M: modified change record refused" || fail "M: modified change record refused"
reset

git rm -q -- "$CR"
run_local; [ $? -eq 1 ] && pass "D: deleted change record refused" || fail "D: deleted change record refused"
reset

git mv "$CR" "$CRDIR/CR-renamed.md"
run_local; [ $? -eq 1 ] && pass "R: renamed change record refused" || fail "R: renamed change record refused"
reset

git rm -q -- "$CR"; ln -s /dev/null "$CR"; git add -- "$CR"
run_local; [ $? -eq 1 ] && pass "T: retyped change record refused" || fail "T: retyped change record refused"
reset

# --- worktree mode sees unstaged edits ---------------------------------------
echo "tampered" >> "$SNAP"
run_local --worktree; [ $? -eq 1 ] && pass "worktree: unstaged snapshot edit refused" || fail "worktree: unstaged snapshot edit refused"
run_local && pass "staged: the same unstaged edit is invisible to index mode (by design)" || fail "staged: the same unstaged edit is invisible to index mode (by design)"
reset

# --- the two things that must PASS -------------------------------------------
echo "# CR-999: new record" > "$CRDIR/CR-999.md"; git add -- "$CRDIR/CR-999.md"
run_local && pass "A: new change record allowed" || fail "A: new change record allowed"
reset

echo "{}" > "$EV"; git add -- "$EV"
run_local && pass "scope: evidence/ edit is NOT protected (plan-workspace.md:26 vs :29)" || fail "scope: evidence/ edit is NOT protected"
reset

# --- ci push mode over committed ranges --------------------------------------
echo "tampered" >> "$SNAP"; git commit -qam "tamper"; BAD=$(git rev-parse HEAD)
run_ci_push "$BASE" "$BAD"; [ $? -eq 1 ] && pass "ci push: range containing a snapshot edit refused" || fail "ci push: range containing a snapshot edit refused"
run_ci_push "$BAD" "$BAD" && pass "ci push: empty range passes" || fail "ci push: empty range passes"
reset

echo "# CR-998" > "$CRDIR/CR-998.md"; git add -A; git commit -qm "add CR"; GOOD=$(git rev-parse HEAD)
run_ci_push "$BASE" "$GOOD" && pass "ci push: range adding a record passes" || fail "ci push: range adding a record passes"
reset

run_ci_push 0000000000000000000000000000000000000000 "$BASE"; [ $? -eq 2 ] && pass "ci push: zero before-SHA fails loud (exit 2), not vacuous pass" || fail "ci push: zero before-SHA fails loud"
run_ci_push deadbeefdeadbeefdeadbeefdeadbeefdeadbeef "$BASE"; [ $? -eq 2 ] && pass "ci push: unresolvable before-SHA fails loud (exit 2)" || fail "ci push: unresolvable before-SHA fails loud"

# --- ci dispatch on main: HEAD^..HEAD ----------------------------------------
echo "tampered" >> "$CR"; git commit -qam "tamper"
GITHUB_EVENT_NAME=workflow_dispatch GITHUB_REF_NAME=main bash .github/protected-artifacts.sh ci >/dev/null 2>&1
[ $? -eq 1 ] && pass "ci dispatch on main: HEAD^..HEAD catches the latest commit" || fail "ci dispatch on main: HEAD^..HEAD catches the latest commit"
reset

# --- ci pull_request: three-dot from merge-base -------------------------------
git checkout -q -b feature; echo "# CR-997" > "$CRDIR/CR-997.md"; git add -A; git commit -qm "feature adds a CR"; FEAT=$(git rev-parse HEAD)
git checkout -q main; echo "tampered" >> "$SNAP"; git commit -qam "main tampers after the fork"; MAIN_AFTER=$(git rev-parse HEAD)
GITHUB_EVENT_NAME=pull_request PR_BASE_SHA="$MAIN_AFTER" PR_HEAD_SHA="$FEAT" bash .github/protected-artifacts.sh ci >/dev/null 2>&1
[ $? -eq 0 ] && pass "ci pull_request: base-branch changes after the fork are not the PR's" || fail "ci pull_request: base-branch changes after the fork are not the PR's"
git branch -q -D feature; reset

# --- refusals ----------------------------------------------------------------
GITHUB_EVENT_NAME=schedule bash .github/protected-artifacts.sh ci >/dev/null 2>&1
[ $? -eq 2 ] && pass "ci: unknown event fails loud (exit 2)" || fail "ci: unknown event fails loud"
bash .github/protected-artifacts.sh >/dev/null 2>&1
[ $? -eq 2 ] && pass "no mode: usage error (exit 2)" || fail "no mode: usage error"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
