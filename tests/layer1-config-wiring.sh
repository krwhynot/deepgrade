#!/usr/bin/env bash
# =============================================================================
# Layer 1: Config/Wiring — dispatcher (split step 4).
#
# The monolithic script this used to be is now two parts:
#
#   layer1-core.sh <plugin-dir> <profile>  — per-plugin config/wiring checks
#   layer1-repo.sh                         — repo-wide sweeps (eol policy, F30,
#                                            the PH5 sentinels, root-doc claims)
#
# This file runs every part and owns the single anchored `Results:` line the
# mutation harness keys on (`^Results: \d+ passed`). Parts emit `Subtotal` lines
# only, so a part that dies cannot leave a completion record behind — the same
# rule as run-all.sh's layer-count assertion, applied one level down: the number
# of subtotals collected must equal the number of parts dispatched, or the run
# reports itself incomplete instead of clean.
# =============================================================================

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

echo "=== DeepGrade Plugin: Layer 1 - Config/Wiring Tests ==="
echo ""

# Parts: one core run per plugin profile, then the repo-wide sweeps.
PARTS=(
  "plugins/deepgrade deepgrade"
  "plugins/deepgrade-readiness deepgrade-readiness"
  "plugins/deepgrade-audit deepgrade-audit"
)

COUNTS_FILE=$(mktemp)
export DG_COUNTS_FILE="$COUNTS_FILE"

OVERALL=0
DISPATCHED=0

for spec in "${PARTS[@]}"; do
  set -- $spec
  DISPATCHED=$((DISPATCHED + 1))
  bash "$SCRIPT_DIR/layer1-core.sh" "$1" "$2" || OVERALL=1
  echo ""
done

DISPATCHED=$((DISPATCHED + 1))
bash "$SCRIPT_DIR/layer1-repo.sh" || OVERALL=1

# Aggregate. A missing subtotal row means a part crashed before finishing; that
# must surface as an incomplete run (no Results line), never as a clean one.
ROWS=$(grep -c . "$COUNTS_FILE" || true)
if [ "$ROWS" -ne "$DISPATCHED" ]; then
  echo ""
  echo ">>> LAYER-1 PART-COUNT ASSERTION FAILED: dispatched $DISPATCHED part(s), only $ROWS reported <<<"
  rm -f "$COUNTS_FILE"
  exit 1
fi

TOTAL_PASS=$(awk '{ p += $2 } END { print p + 0 }' "$COUNTS_FILE")
TOTAL_FAIL=$(awk '{ f += $3 } END { print f + 0 }' "$COUNTS_FILE")
rm -f "$COUNTS_FILE"

echo ""
echo "==========================================="
echo "Results: $TOTAL_PASS passed, $TOTAL_FAIL failed"
echo "==========================================="

if [ "$OVERALL" -ne 0 ] || [ "$TOTAL_FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
