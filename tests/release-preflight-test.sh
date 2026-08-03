#!/usr/bin/env bash
# Tests for .github/release.sh preflight (`check` subcommand).
#
# The 5.0.0 release shipped tagged and pushed with no breaking-change section, no
# migration note, and an unpinned catalog — every one a missing PREFLIGHT, not a
# missing capability. So the preflight is what gets tested: it must pass on a
# clean released tree, and refuse each synthetic violation.
#
# Everything runs in a scratch clone. Two non-obvious rules, learned from this
# file's own first draft failing:
#   - The clone holds committed state only, so the working-tree release.sh is
#     copied in and COMMITTED before anything runs — otherwise the clone tests
#     whatever the last commit held, not the code under test.
#   - Each violation is COMMITTED in the clone. A sed-edited tracked file leaves
#     the tree dirty, and the dirty-tree error would fire on every case, letting
#     a preflight that checked nothing but cleanliness pass four of five tests.

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0; FAIL=0
pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=== Release preflight tests ==="

if [ ! -f "$ROOT/.github/release.sh" ]; then
  fail "release script exists at .github/release.sh"
  echo "Results: $PASS passed, 1 failed"
  exit 1
fi

SCRATCH=$(mktemp -d)
trap 'cd "$ROOT"; rm -rf "$SCRATCH"' EXIT
git clone -q --local --no-hardlinks "$ROOT" "$SCRATCH/repo"
cd "$SCRATCH/repo"
git config user.email test@test && git config user.name test

# The code under test, not whatever was last committed.
mkdir -p .github
cp "$ROOT/.github/release.sh" .github/release.sh
git add -A && git commit -qm "test: stage release.sh under test"
BASE=$(git rev-parse HEAD)

# --- Control: a clean released tree must pass --------------------------------
# If preflight cannot pass on the state that just shipped cleanly, it will be
# bypassed on release day, and a bypassed preflight is the 5.0.0 process again.
if bash .github/release.sh check >/dev/null 2>&1; then
  pass "preflight passes on a clean released tree (control)"
else
  fail "preflight fails on a clean released tree — it would be bypassed on release day"
  bash .github/release.sh check 2>&1 | sed 's/^/         /' | head -8
fi

violation() {  # violation <label> <expected-substring>  (violation already committed)
  local label="$1" expect="$2" out rc
  out=$(bash .github/release.sh check 2>&1); rc=$?
  if [ $rc -ne 0 ] && printf '%s' "$out" | grep -qiE "$expect"; then
    pass "$label"
  else
    fail "$label — expected refusal mentioning '$expect' (rc=$rc)"
    printf '%s\n' "$out" | sed 's/^/         /' | head -6
  fi
  # reset --hard restores tracked files only; clean removes the untracked ones
  # (V4's stray file survived the reset in this file's first draft and dirtied
  # every later case).
  git reset -q --hard "$BASE"
  git clean -qfd
}

# V1: versions drift across the quartet — the F20A failure, pre-commit.
sed -i 's/^Current: v6\.0\.0/Current: v5.9.9/' README.md
git commit -qam "v1"
violation "V1: root README version drift refused" "version|drift"

# V1b: a PLUGIN's README drifts — the split's per-plugin quartet loop must
# refuse this on its own; the root README is clean in this case.
sed -i 's/^Current: v6\.0\.0/Current: v5.9.9/' plugins/deepgrade/README.md
git commit -qam "v1b"
violation "V1b: plugin README version drift refused" "version|drift"

# V2: a manifest disagrees — the lockstep rule, load-bearing at four manifests.
sed -i 's/"version": "6.0.0"/"version": "6.1.0"/' plugins/deepgrade-guard/.claude-plugin/plugin.json
git commit -qam "v2"
violation "V2: manifest out of lockstep refused" "lockstep|version"

# V3: CHANGELOG has no entry for the manifest version — how 5.0.0 shipped
# without its breaking-change section.
sed -i 's/^## 6\.0\.0/## 6.0.0-moved/' CHANGELOG.md
git commit -qam "v3"
violation "V3: missing CHANGELOG entry refused" "changelog"

# V4: dirty tree — the one violation that must stay UNcommitted.
echo "stray" > stray.txt
violation "V4: dirty tree refused" "clean|dirty|uncommitted"

# V5: catalog pin naming a different release than the manifests. Legitimate
# mid-release (pin updates after the tag), so check must SURFACE it — warn or
# refuse — but silence is the forgotten-pin failure mode.
sed -i 's/"ref": "v6.0.0"/"ref": "v5.0.1"/' .claude-plugin/marketplace.json
git commit -qam "v5"
# Capture, then grep the variable. Piping check into grep under pipefail returns
# check's own exit status even when grep matches, which turned a correctly
# surfaced warning into a reported silence in this file's first draft.
v5_out=$(bash .github/release.sh check 2>&1 || true)
if printf '%s' "$v5_out" | grep -qi "pin"; then
  pass "V5: stale catalog pin surfaced"
else
  fail "V5: stale catalog pin passed silently — the forgotten-pin failure mode"
  printf '%s\n' "$v5_out" | sed 's/^/         /' | head -6
fi
git reset -q --hard "$BASE"
git clean -qfd

# --- run --dry-run must change nothing ---------------------------------------
before=$(git rev-parse HEAD; git status --porcelain)
bash .github/release.sh run 9.9.9 --dry-run >/dev/null 2>&1
after=$(git rev-parse HEAD; git status --porcelain)
if [ "$before" = "$after" ]; then
  pass "run --dry-run leaves the tree untouched"
else
  fail "run --dry-run modified the tree"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
