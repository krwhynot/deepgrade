#!/bin/bash
# DeepGrade: PreCompact hook. Pure bash.

PLANS_DIR="docs/plans"
[ ! -d "$PLANS_DIR" ] && [ -d "plans" ] && PLANS_DIR="plans"

LATEST_PLAN=$(ls -td "$PLANS_DIR"/*/ 2>/dev/null | head -1)
[ -z "$LATEST_PLAN" ] || [ ! -f "$LATEST_PLAN/status.json" ] && exit 0

PLAN_NAME=$(basename "$LATEST_PLAN")
PHASE=$(grep -o '"current_phase":"[^"]*"' "$LATEST_PLAN/status.json" 2>/dev/null | head -1 | sed 's/"current_phase":"//;s/"$//')

echo "[DeepGrade] Compacting. Active plan: $PLAN_NAME at phase: ${PHASE:-unknown}. Resume with /deepgrade:plan $PLAN_NAME"
exit 0
