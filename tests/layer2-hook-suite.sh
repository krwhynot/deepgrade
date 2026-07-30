#!/usr/bin/env bash
# Layer 2 dispatcher — PHV5-042.
#
# Layer 2 now covers BOTH hook implementations for the duration of Wave 4:
#   1. layer2-hook-simulation.sh  — the INLINE hooks in plugin.json, which are
#      what actually runs today. Kept because removing coverage from live code
#      before its replacement is activated would be backwards.
#   2. run-hook-corpus.js         — lane N's parser contract (F24/F22/F25/F26),
#      the acceptance authority for PHV5-041.
#   3. layer2-ledger-rows.js      — one falsifying test per behaviour-ledger row
#      (§3.1.4), the acceptance for PHV5-040.
#
# 4b deletes the inline hooks; this dispatcher then drops (1).
#
# Layers 6 and 7 are RESERVED by the locked test_layer_numbering decision (L6 drift
# gate in Wave 6, L7 runtime proof in 4c), which is why these are Layer 2 members
# rather than new layers.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.." || exit 1

FAILED=0
run_part() {
  local label=$1 runner=$2; shift 2
  echo ""
  echo "### Layer 2.$label"
  if [ "$runner" = "node" ]; then
    if ! command -v node >/dev/null 2>&1; then
      echo "[FAIL] node is required for Layer 2.$label and was not found on PATH"
      echo "       (never a silent skip — lane N's guards run ON node, so an absent"
      echo "        interpreter means this layer proves nothing, not that it passed)"
      FAILED=1; return
    fi
    node "$@" || FAILED=1
  else
    bash "$@" || FAILED=1
  fi
}

run_part "1 inline hooks (live implementation)" bash tests/layer2-hook-simulation.sh
run_part "2 lane-N parser contract (F24/F22/F25/F26)" node tests/run-hook-corpus.js scripts/dg-git-guard.js
run_part "3 lane-N behaviour ledger (rows 1-11)" node tests/layer2-ledger-rows.js

echo ""
if [ "$FAILED" -ne 0 ]; then
  echo ">>> Layer 2 FAILED <<<"
  exit 1
fi
echo ">>> Layer 2 parts all passed <<<"
exit 0
