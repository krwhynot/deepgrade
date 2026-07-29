#!/usr/bin/env bash
# DeepGrade Plugin Test Runner
# Run from plugin root: bash tests/run-all.sh
#
# Layers:
#   1. Config/Wiring   - Parse plugin.json, check consistency
#   2. Hook Simulation - Feed canned payloads, assert block/allow
#   3. Fixture Lint    - Known-gap plans, verify detection
#   4. Behavioral      - Command structure and cross-references
#   5. Codex Challenge - SCORES/GAPS parser regression (node)
#
# Usage:
#   bash tests/run-all.sh              # Run all layers
#   bash tests/run-all.sh 1            # Run only layer 1
#   bash tests/run-all.sh 1 3          # Run layers 1 and 3
#   bash tests/run-all.sh --quick      # Layers 1-3 only (skip behavioral)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PLUGIN_ROOT"

TOTAL_PASS=0
TOTAL_FAIL=0
LAYERS_RUN=0
LAYERS_FAILED=0

run_layer() {
    local LAYER=$1
    local NAME=$2
    local SCRIPT=$3
    local RUNNER=${4:-bash}

    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║  Layer $LAYER: $NAME"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    if [[ ! -f "$SCRIPT" ]]; then
        echo "[ERROR] $SCRIPT not found"
        LAYERS_FAILED=$((LAYERS_FAILED + 1))
        return 1
    fi

    # A layer whose interpreter is unavailable must FAIL, never silently skip —
    # a skipped layer that reports success is indistinguishable from a passing one.
    if ! command -v "$RUNNER" >/dev/null 2>&1; then
        echo "[ERROR] interpreter '$RUNNER' not found on PATH — Layer $LAYER cannot run"
        LAYERS_FAILED=$((LAYERS_FAILED + 1))
        return 1
    fi

    "$RUNNER" "$SCRIPT"
    local EXIT_CODE=$?

    LAYERS_RUN=$((LAYERS_RUN + 1))
    if [[ $EXIT_CODE -ne 0 ]]; then
        LAYERS_FAILED=$((LAYERS_FAILED + 1))
        echo ""
        echo ">>> Layer $LAYER FAILED (exit $EXIT_CODE) <<<"
    else
        echo ""
        echo ">>> Layer $LAYER PASSED <<<"
    fi

    return $EXIT_CODE
}

# Determine which layers to run
RUN_LAYERS=""
QUICK=false

for arg in "$@"; do
    case $arg in
        --quick) QUICK=true ;;
        [1-5]) RUN_LAYERS="$RUN_LAYERS $arg" ;;
    esac
done

# Default: run all (or 1-3 if --quick)
if [[ -z "$RUN_LAYERS" ]]; then
    if $QUICK; then
        RUN_LAYERS="1 2 3"
    else
        RUN_LAYERS="1 2 3 4 5"
    fi
fi

# Layer-count assertion (PHV5-002 / matrix row A2 negative case): the number of layers that
# actually ran must equal the number requested. Without this, a layer that vanishes from the
# case statement disappears silently and the suite still reports success.
EXPECTED_LAYERS=$(echo $RUN_LAYERS | wc -w | tr -d ' ')

echo "============================================"
echo "  DeepGrade Plugin Test Suite"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Layers: $RUN_LAYERS"
echo "============================================"

OVERALL_EXIT=0

for layer in $RUN_LAYERS; do
    case $layer in
        1) run_layer 1 "Config/Wiring" "$SCRIPT_DIR/layer1-config-wiring.sh" || OVERALL_EXIT=1 ;;
        2) run_layer 2 "Hook Simulation" "$SCRIPT_DIR/layer2-hook-simulation.sh" || OVERALL_EXIT=1 ;;
        3) run_layer 3 "Fixture Lint" "$SCRIPT_DIR/layer3-fixture-lint.sh" || OVERALL_EXIT=1 ;;
        4) run_layer 4 "Behavioral Smoke" "$SCRIPT_DIR/layer4-behavioral-smoke.sh" || OVERALL_EXIT=1 ;;
        5) run_layer 5 "Codex Challenge Parser" "$SCRIPT_DIR/codex-challenge-test.js" node || OVERALL_EXIT=1 ;;
    esac
done

if [[ $LAYERS_RUN -ne $EXPECTED_LAYERS ]]; then
    echo ""
    echo ">>> LAYER-COUNT ASSERTION FAILED: requested $EXPECTED_LAYERS layer(s), only $LAYERS_RUN ran <<<"
    OVERALL_EXIT=1
fi

echo ""
echo "============================================"
echo "  FINAL SUMMARY"
echo "  Layers run: $LAYERS_RUN / $EXPECTED_LAYERS requested"
echo "  Layers failed: $LAYERS_FAILED"
if [[ $OVERALL_EXIT -eq 0 ]]; then
    echo "  Status: ALL PASSED"
else
    echo "  Status: FAILURES DETECTED"
fi
echo "============================================"

exit $OVERALL_EXIT
