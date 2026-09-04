#!/usr/bin/env bash
# =============================================================================
# scoring-sweep.sh — the instrument for plan-centerpiece-alignment.
#
# WHY THIS FILE EXISTS
#
# Two design-gate attempts failed. The second named the cause: "the instrument
# is asserted, not shipped" — a spec claimed a self-tested pattern and an
# inventory derived from it, while neither the pattern nor the test existed
# anywhere a reader could run. Six counting errors were made across those two
# attempts, all the same shape: a number asserted, no instrument shipped, the
# number wrong.
#
# So this file is the pattern. Its output IS the inventory. Nothing in the spec
# counts scoring sites by hand; the spec cites this script's output instead.
#
# CR-002 authorises the inversion.
#
# TWO MODES
#   report   list violations, exit 0. Ships BEFORE the fixes, so the suite stays
#            green while violations still exist. This is what makes the guard
#            safe to build first.
#   enforce  list violations, exit 1 if any. The last commit of the plan flips
#            to this.
#
# SELF-TEST RUNS FIRST, ALWAYS. A sweep whose pattern is unproven produces a
# number nobody can trust — which is the exact failure this replaces. If the
# self-test fails, the script exits 2 and reports NOTHING about the tree.
# =============================================================================

set -uo pipefail
cd "$(dirname "$0")/../../../.." || exit 2   # -> repo root

MODE="${1:-report}"
case "$MODE" in report|enforce|selftest) ;; *)
  echo "usage: scoring-sweep.sh [report|enforce|selftest]"; exit 2 ;;
esac

# --- the pattern -------------------------------------------------------------
#
# Each alternative earns its place from a specific miss made during planning:
#   [0-9]+/(40|5)        digit forms:      "36/40", "3/5"        (error 2)
#   ([A-Z]|\{[a-z_]+\})/(40|5)  placeholder forms: "X/40", "{total}/40"  (error 6)
#   score_history        the phantom status.json field           (error 3)
#   scorecard            the table quick-audit renders
#   \b(GREEN|YELLOW|ORANGE|RED)\b   bands, word-bounded so REQUIRED is safe (error 1)
#   scored [0-9]-[0-9]   "scored 1-5 by Codex"
#   3[0-9]\+/40          "32+/40" thresholds
#
RE='[0-9]+/(40|5)\b|([A-Z]|\{[a-z_]+\})/(40|5)\b|score_history|scorecard|\b(GREEN|YELLOW|ORANGE|RED)\b|scored [0-9]-[0-9]|3[0-9]\+/40'

# --- scope -------------------------------------------------------------------
#
# IN: the live planning-plugin surface plus the methodology document.
# Everything excluded below is excluded for a stated reason, and the reasons are
# themselves self-tested at the bottom of this file.
#
SUBJECTS=(plugins/toque METHODOLOGY.md tests)

is_excluded() {
  local f="$1"
  case "$f" in
    # A different product. The readiness scan grades codebases A+ to F on
    # purpose; it is being split to its own repository. Stripping its bands
    # would break a working feature, not fix an inconsistency.
    */toque-audit/*|*readability-score*|*readiness*) return 0 ;;
    # "BASELINE NOT GREEN" describes suite state, not a plan verdict.
    tests/mutation/*) return 0 ;;
    # Historical records. They describe past releases truthfully in the past
    # tense; rewriting them to satisfy a grep is falsification.
    CHANGELOG.md|docs/specs/*|docs/plans/*) return 0 ;;
    # This file and the guard are the instrument, not defects.
    *scoring-sweep.sh|tests/layer1-repo.sh) return 0 ;;
  esac
  return 1
}

# METHODOLOGY.md is split: section 7 is the plan audit (IN); everything else is
# the readiness product's letter grades (OUT).
#
# The boundaries are DERIVED from the headers, not hardcoded. An earlier version
# pinned them to 1031-1257; removing 21 lines from section 7 shifted section 8
# upward and the fixed range began scanning into it. A line number is a fact
# about a moment, not about a document.
meth_s7_bounds() {
  local a b
  a=$(grep -nE '^## 7\.' METHODOLOGY.md | head -1 | cut -d: -f1)
  b=$(grep -nE '^## 8\.' METHODOLOGY.md | head -1 | cut -d: -f1)
  [ -n "$a" ] && [ -n "$b" ] || { echo "SECTION BOUNDS NOT DERIVABLE" >&2; return 1; }
  echo "$a $((b - 1))"
}

# --- self-test ---------------------------------------------------------------
st_pass=0; st_fail=0
kp() { printf '%s' "$1" | grep -qE "$RE" \
       && st_pass=$((st_pass+1)) \
       || { echo "  SELFTEST FAIL — pattern missed: $1"; st_fail=$((st_fail+1)); }; }
kn() { printf '%s' "$1" | grep -qE "$RE" \
       && { echo "  SELFTEST FAIL — pattern matched: $1"; st_fail=$((st_fail+1)); } \
       || st_pass=$((st_pass+1)); }

selftest() {
  # Known positives — every one is a real line that appeared in this repo.
  kp 'Score: {total}/40 (GREEN)'
  kp 'GAP-1 [Dim 4: Risk, 3/5]: no rollback strategy'
  kp '3. **No score improvement between rounds AND all dimensions >= 3/5**'
  kp '4. **Any dimension at 1/5 or 2/5 persists after Round 2**'
  kp '- Overall score (X/40), reported only'
  kp '1. Overall score (X/40) with color (Green/Yellow/Orange/Red)'
  kp 'status.json keeps a score_history for trend-watching'
  kp '2. The scorecard table (8 dimensions)'
  kp '4. Auditable (would score 32+/40 on the plan-auditor)'
  kp 'Each dimension is scored 1-5 by Codex'
  kp '"audit": {"status": "complete", "score": 36, "rating": "GREEN"}'
  # Known negatives — the traps that produced errors 1 and 5.
  kn 'TESTING METHODOLOGY SELECTION (REQUIRED):'
  kn 'GATE: User confirmation REQUIRED.'
  kn 'HIGH-impact entries MUST always complete steps 3-5'
  kn 'the agent that writes the code must not write the tests'
  kn 'Every subagent has a functional name and a visible report'
  # Exclusion reasoning is testable too, not just asserted in a comment.
  is_excluded "CHANGELOG.md"                              && st_pass=$((st_pass+1)) || { echo "  SELFTEST FAIL — CHANGELOG not excluded"; st_fail=$((st_fail+1)); }
  is_excluded "docs/plans/2026-07-20-plugin-hardening-v5/audit.md" && st_pass=$((st_pass+1)) || { echo "  SELFTEST FAIL — historical plan not excluded"; st_fail=$((st_fail+1)); }
  is_excluded "tests/mutation/wave5-guards.py"            && st_pass=$((st_pass+1)) || { echo "  SELFTEST FAIL — mutation harness not excluded"; st_fail=$((st_fail+1)); }
  is_excluded "plugins/toque/commands/quick-audit.md"     && { echo "  SELFTEST FAIL — a live subject was excluded"; st_fail=$((st_fail+1)); } || st_pass=$((st_pass+1))
  echo "self-test: $st_pass passed, $st_fail failed"
  [ "$st_fail" -eq 0 ]
}

echo "=== scoring-sweep ($MODE) ==="
if ! selftest; then
  echo ""
  echo "PATTERN NOT TRUSTED. Reporting nothing about the tree."
  echo "An unproven instrument produces a number nobody can check, which is the"
  echo "failure this script exists to prevent."
  exit 2
fi
[ "$MODE" = "selftest" ] && exit 0

# --- the sweep ---------------------------------------------------------------
echo ""
total=0; files=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  is_excluded "$f" && continue
  if [ "$f" = "METHODOLOGY.md" ]; then
    read -r METH_S7_START METH_S7_END < <(meth_s7_bounds) || exit 2
    hits=$(sed -n "${METH_S7_START},${METH_S7_END}p" "$f" | grep -cE "$RE")
    [ "$hits" -eq 0 ] && continue
    echo "  $f  (section 7 only, lines $METH_S7_START-$METH_S7_END): $hits"
  else
    hits=$(grep -cE "$RE" "$f")
    [ "$hits" -eq 0 ] && continue
    echo "  $f: $hits"
  fi
  total=$((total + hits)); files=$((files + 1))
done < <(grep -rlE "$RE" "${SUBJECTS[@]}" 2>/dev/null | sed 's|^\./||' | sort)

echo ""
echo "TOTAL: $total violation line(s) across $files file(s)"

if [ "$MODE" = "enforce" ]; then
  [ "$total" -eq 0 ] && { echo "enforce: clean"; exit 0; }
  echo "enforce: FAIL — scoring vocabulary survives in the live surface"
  exit 1
fi
echo "report mode: exit 0 regardless. Flip to enforce in the final phase."
exit 0
