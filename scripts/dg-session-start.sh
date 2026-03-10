#!/bin/bash
# DeepGrade: SessionStart hook
# Checks for active plans and staleness. Pure bash.

PLANS_DIR="docs/plans"
[ ! -d "$PLANS_DIR" ] && [ -d "plans" ] && PLANS_DIR="plans"
[ ! -d "$PLANS_DIR" ] && exit 0

LATEST_PLAN=$(ls -td "$PLANS_DIR"/*/ 2>/dev/null | head -1)
[ -z "$LATEST_PLAN" ] && exit 0
[ ! -f "$LATEST_PLAN/status.json" ] && exit 0

PLAN_NAME=$(basename "$LATEST_PLAN")
PHASE=$(grep -o '"current_phase":"[^"]*"' "$LATEST_PLAN/status.json" 2>/dev/null | head -1 | sed 's/"current_phase":"//;s/"$//')
STATUS=$(grep -o '"status":"[^"]*"' "$LATEST_PLAN/status.json" 2>/dev/null | head -1 | sed 's/"status":"//;s/"$//')

OUTPUT="Active plan: $PLAN_NAME (phase: ${PHASE:-unknown}, status: ${STATUS:-unknown})"

# Check audit staleness
if [ -f "docs/audit/deepgrade-report.md" ]; then
  AUDIT_MTIME=$(stat -c %Y "docs/audit/deepgrade-report.md" 2>/dev/null || stat -f %m "docs/audit/deepgrade-report.md" 2>/dev/null)
  if [ -n "$AUDIT_MTIME" ]; then
    AUDIT_AGE=$(( ($(date +%s) - AUDIT_MTIME) / 86400 ))
    [ "$AUDIT_AGE" -gt 7 ] && OUTPUT="$OUTPUT. Audit report is $AUDIT_AGE days old."
  fi
fi

echo "[DeepGrade] $OUTPUT"
exit 0
