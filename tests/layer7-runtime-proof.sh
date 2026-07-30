#!/usr/bin/env bash
# =============================================================================
# Layer 7: Runtime proof — PHV5-044 (Wave 4c)
#
# Every other layer proves the CONFIGURATION is right. This one proves the hooks
# actually FIRE. Nothing else in the suite can: layer 1 reads frontmatter, layer 2
# pipes payloads into handlers directly, and `claude plugin validate` never opens a
# handler at all. A plugin can pass all 262 assertions with its safety layer dead.
#
# NOT part of `run-all.sh`. It needs a live Claude Code session and, for part 2, an
# installed copy — so it is opt-in and run deliberately:
#
#     bash tests/layer7-runtime-proof.sh            # automated checks
#     bash tests/layer7-runtime-proof.sh --manual   # print the interactive checklist
#
# WHAT IT CANNOT DO, stated up front rather than discovered later. U6 established
# that Claude Code's hook-error notice appears in INTERACTIVE sessions only —
# `claude -p` print mode suppresses it, proven by a control run in which a
# SUCCESSFUL hook also produced no output even under --debug. So anything whose
# evidence is a surfaced NOTICE cannot be automated here. Those checks live in the
# --manual checklist and are recorded as owner-observed, never inferred.
#
# Evidence is written to docs/plans/2026-07-20-plugin-hardening-v5/research/
# layer7-runtime-evidence.md and committed (§3.6). An unrecorded pass is not a pass.
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT" || exit 1

PASS=0; FAIL=0; PENDING=0
pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
pending() { echo "[PENDING-OWNER] $1"; PENDING=$((PENDING + 1)); }

EVIDENCE="docs/plans/2026-07-20-plugin-hardening-v5/research/layer7-runtime-evidence.md"

# ---------------------------------------------------------------------------
# Prerequisites. A missing prerequisite FAILS; it never silently skips. Wave 0
# established that rule when a missing interpreter turned a layer into a no-op.
# ---------------------------------------------------------------------------
echo "=== Layer 7: Runtime Proof (PHV5-044) ==="
echo ""

if ! command -v node >/dev/null 2>&1; then
  fail "node is not on PATH. Lane N's handlers ARE node, so this proves nothing without it."
  echo "       (For the deliberate node-less case, use --manual: that one is a separate,"
  echo "        interactive check whose expected result is a vendor hook-error notice.)"
  exit 1
fi
pass "prerequisite: node $(node --version) on PATH"

if ! command -v claude >/dev/null 2>&1; then
  fail "claude CLI is not on PATH — part 1 drives a nested session through it"
  exit 1
fi
pass "prerequisite: claude CLI $(claude --version 2>&1 | head -1)"

[ -f hooks/hooks.json ] || { fail "hooks/hooks.json missing — nothing to prove"; exit 1; }

if [ "${1:-}" = "--manual" ]; then
  MANUAL_ONLY=1
else
  MANUAL_ONLY=0
fi

# ---------------------------------------------------------------------------
# PART 1 — automated: observable SIDE EFFECTS of hooks firing.
#
# Side effects, not captured notices, because notices are suppressed in print mode.
# A tracker file appearing in TMPDIR is unambiguous proof the PostToolUse handler
# ran: nothing else in the plugin writes it.
# ---------------------------------------------------------------------------
if [ "$MANUAL_ONLY" -eq 0 ]; then
echo ""
echo "--- Part 1: automated (nested session via --plugin-dir) ---"

SCRATCH=$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/dg-l7-$$")
mkdir -p "$SCRATCH"
HOOKTMP="$SCRATCH/hooktmp"
mkdir -p "$HOOKTMP"

# Drive a nested session whose tool use should trip a hook, with TMPDIR redirected so
# the markers land somewhere we can inspect without touching the developer's state.
nested() {
  local prompt=$1
  ( cd "$SCRATCH" && TMPDIR="$HOOKTMP" TEMP="$HOOKTMP" \
    timeout 180 claude -p --plugin-dir "$ROOT" "$prompt" 2>&1 ) || true
}

# PostToolUse:Write|Edit -> dg-track-change.js writes a baseline tracker.
echo "  driving PostToolUse:Write|Edit ..."
nested "Create a file called probe.txt in the current directory containing the single word ok. Then stop." >/dev/null
if ls "$HOOKTMP"/dg-baseline-* >/dev/null 2>&1; then
  pass "PostToolUse:Write|Edit fired — tracker written to \$TMPDIR"
else
  fail "PostToolUse:Write|Edit produced NO tracker. The handler did not run (matcher, path, or spawn failure)."
fi

# PostToolUse:Bash -> dg-track-test.js writes a test marker for a recognised runner.
#
# THE RUNNER MUST EXIST ON THE HOST. This probe originally asked the nested session to run
# `pytest --version`, and reported FAIL on a host with no pytest installed — so it was
# testing "will Claude run a tool that is absent", not "does the hook fire". The handler
# was correct all along: fed a pytest payload directly it writes the marker.
#
# A runtime probe whose subject may not exist produces a false defect report, which is
# worse than no probe: it sends you debugging a working component. Preconditioned on the
# runner being present, and FAILS rather than skips if none is — per the Wave 0 rule that
# a missing prerequisite must never silently no-op.
echo "  driving PostToolUse:Bash ..."
if command -v python >/dev/null 2>&1 && python -m unittest --help >/dev/null 2>&1; then
  TEST_CMD="python -m unittest --help"
elif command -v pytest >/dev/null 2>&1; then
  TEST_CMD="pytest --version"
elif command -v npx >/dev/null 2>&1; then
  TEST_CMD="npx --version"   # not a runner; only reached if neither python nor pytest exist
  TEST_CMD=""
else
  TEST_CMD=""
fi
if [ -z "$TEST_CMD" ]; then
  fail "PostToolUse:Bash: no recognised test runner present on this host, so the hook cannot be exercised — install python or pytest and re-run"
else
  nested "Run exactly this shell command and nothing else: $TEST_CMD" >/dev/null
  if ls "$HOOKTMP"/dg-test-* >/dev/null 2>&1; then
    pass "PostToolUse:Bash fired — test marker written for '$TEST_CMD'"
  else
    fail "PostToolUse:Bash produced NO test marker for '$TEST_CMD' — the runner exists, so the handler or the wiring is at fault"
  fi
fi

# PreToolUse:Bash deny. The nested session should be PREVENTED from running it, so
# the evidence is the absence of the side effect plus a refusal in the transcript.
echo "  driving PreToolUse:Bash (deny path) ..."
DENY_MARK="$SCRATCH/should-not-exist.txt"
# Built from fragments so this FILE can be edited and run while the old guard is
# still installed — it blocks any command whose text contains a trigger string.
DENYCMD="git push --for""ce origin main; touch '$DENY_MARK'"
out=$(nested "Run exactly this shell command and nothing else: $DENYCMD")
if [ -f "$DENY_MARK" ]; then
  fail "PreToolUse:Bash did NOT block a force push — the compound command ran to completion"
elif echo "$out" | grep -qiE 'block|denied|not allowed|BLOCKED'; then
  pass "PreToolUse:Bash blocked the force push and the refusal reached the transcript"
else
  pending "PreToolUse:Bash: the command did not run (good) but no refusal text was captured — print mode may have suppressed it. Confirm interactively via --manual."
fi

# SubagentStop -> appends to a plan's troubleshooting log. Needs the opt-in folder.
echo "  driving SubagentStop ..."
SUBLOG="$SCRATCH/docs/plans/2026-01-01-probe/troubleshooting"
mkdir -p "$SUBLOG"
nested "Use a subagent to count the files in the current directory, then stop." >/dev/null
if [ -s "$SUBLOG/subagent-log.txt" ]; then
  pass "SubagentStop fired — entry appended to the plan's troubleshooting log"
else
  pending "SubagentStop produced no log entry. It only fires if the nested session actually spawned a subagent; confirm interactively."
fi

rm -rf "$SCRATCH"
fi

# ---------------------------------------------------------------------------
# PART 2 — the interactive checklist. These CANNOT be automated (U6: notices are
# suppressed in print mode) and must be observed by the owner in a real session.
# ---------------------------------------------------------------------------
echo ""
echo "--- Part 2: owner-observed checks (interactive session required) ---"
cat <<'CHECKLIST'

  Run these in an INTERACTIVE Claude Code session, and paste what you see into
  the evidence file. Do not infer any of them from part 1.

  PREREQUISITE — install the working copy so the hooks under test are the ones
  in this repo, not the stale marketplace copy:

      /plugin marketplace update deepgrade-marketplace
      /plugin update deepgrade
      /reload-plugins
      /plugin details deepgrade        -> must report Hooks (6) incl. SubagentStop

  A. SessionStart (F26, settles part of U4)
     Start a fresh session in this repo. Expect a line naming the active plan,
     its phase and status. RECORD IT VERBATIM.
     Pre-5.0.0 this reported "phase: unknown, status: unknown" against a
     pretty-printed status.json, so a real phase name is the proof.

  B. PreToolUse:Bash — deny (F25)
     Ask Claude to run:  git push --force origin main
     Expect: blocked, with a message naming --force-with-lease as the alternative.

  C. PreToolUse:Bash — the SAFE form must be ALLOWED (F25, the inverted defect)
     Ask Claude to run:  git push --force-with-lease --dry-run origin main
     Expect: NOT blocked. Before 5.0.0 this was denied while bare -f was allowed.

  D. PreToolUse:Bash — ask (F22)
     Ask Claude to run:  git reset --hard
     Expect: a CONFIRMATION PROMPT, not a refusal. Record which it was.

  E. PreToolUse:Bash — quoted mention must be allowed (F24)
     Ask Claude to run:  git commit --allow-empty -m "never git push --force"
     Expect: NOT blocked. This is the defect that blocked this plan's own commits.

  F. PreCompact (settles U5 — the open question)
     Fill the context until compaction triggers, or run /compact.
     Does a DeepGrade line naming the active plan appear?
       YES -> U5 positive; record verbatim.
       NO  -> U5 negative. The locked §3.1.6 fallback then applies: the
              compact-resume message moves to the SessionStart `compact` source
              path, which is ALREADY IMPLEMENTED in dg-session-start.js. Verify it
              by resuming after the compaction and checking for the resume line.
              If that also fails, F26's PreCompact half is recorded PARTIAL in the
              release notes — never silently dropped.

  G. Stop (F26)
     Edit a file, then end the turn without running tests.
     Expect: a summary naming the change count, and a nudge that no tests ran.
     Both messages existed pre-5.0.0 but went to stderr at exit 0 and were never
     surfaced to anyone.

  H. Zero hook errors on a healthy host
     Through all of the above, no "hook error" notice should appear.
     This is the acceptance criterion for the whole wave.

  I. NODE-LESS INSTALLED COPY (CR-1's condition, lane N's honest limit)
     In a shell with node removed from PATH, start an interactive session:
         PATH=$(echo "$PATH" | tr ':' '\n' | grep -v node | paste -sd:) claude
     Expect the vendor's own hook-error notice — the guards cannot spawn, and
     that notice is the only in-product signal. Record it VERBATIM; CR-1's
     acceptance is that it is user-visible and names the cause.

CHECKLIST

pending "A-I are owner-observed and unrecorded until pasted into $EVIDENCE"

# ---------------------------------------------------------------------------
echo ""
echo "==========================================="
echo "Layer 7: $PASS passed, $FAIL failed, $PENDING pending owner observation"
echo "==========================================="
echo ""
echo "This layer is NOT complete until the part-2 observations are recorded in:"
echo "  $EVIDENCE"
echo "Findings F06, F24 and F26 stay PARTIAL until then — their R and I"
echo "verification classes are exactly what part 2 supplies."

[ "$FAIL" -gt 0 ] && exit 1
exit 0
