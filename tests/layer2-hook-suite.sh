#!/usr/bin/env bash
# Layer 2 dispatcher — PHV5-042 / PHV5-043.
#
#   1. layer2-ledger-rows.js  — one falsifying test per behaviour-ledger row
#      (§3.1.4) for the plan-context handlers that remain in toque.
#
# run-hook-corpus.js and tests/fixtures/hook-corpus.json were DELETED in 9.0.0
# with the toque-guard plugin whose git guard they exercised. The ledger rows
# for the guard, migration, tracker and stop handlers went with them.
#
# layer2-hook-simulation.sh was DELETED at 4b along with the inline hooks it
# exercised. It drove handlers embedded in plugin.json through positional-index
# field extraction; both the handlers and the extraction technique are gone, so
# the file had nothing left to test. That completes PHV5-042's "no positional-index
# extraction" clause — not by rewriting the file, but by removing its subject.
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
      echo "       (never a silent skip — the handlers run ON node, so an absent"
      echo "        interpreter means this layer proves nothing, not that it passed)"
      FAILED=1; return
    fi
    node "$@" || FAILED=1
  else
    bash "$@" || FAILED=1
  fi
}

# Guard against silently losing a part: the retired inline file must be GONE, not
# merely unreferenced, or a future reader will assume it still runs.
if [ -f tests/layer2-hook-simulation.sh ]; then
  echo "[FAIL] tests/layer2-hook-simulation.sh still exists but is no longer dispatched —"
  echo "       either wire it back in or delete it. An undispatched test file reads as coverage."
  FAILED=1
fi

# Guard against silently losing the retired part the other way round: a resurrected
# corpus runner with no dispatch would read as coverage too.
if [ -f tests/run-hook-corpus.js ] || [ -f tests/fixtures/hook-corpus.json ]; then
  echo "[FAIL] the hook corpus was retired with toque-guard (9.0.0) but a copy is back in the tree —"
  echo "       either dispatch it against a live handler or delete it."
  FAILED=1
fi

run_part "1 plan-context behaviour ledger (rows 4, 10, F26)" node tests/layer2-ledger-rows.js

echo ""
if [ "$FAILED" -ne 0 ]; then
  echo ">>> Layer 2 FAILED <<<"
  exit 1
fi
echo ">>> Layer 2 parts all passed <<<"
exit 0
