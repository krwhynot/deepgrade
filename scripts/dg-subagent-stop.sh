#!/bin/bash
# Three Pillars: SubagentStop hook. Pure bash.

PLANS_DIR="docs/plans"
[ ! -d "$PLANS_DIR" ] && [ -d "plans" ] && PLANS_DIR="plans"

LATEST_PLAN=$(ls -td "$PLANS_DIR"/*/ 2>/dev/null | head -1)
[ -z "$LATEST_PLAN" ] && exit 0
[ ! -d "$LATEST_PLAN/troubleshooting" ] && exit 0

INPUT=$(cat)
REASON=$(echo "$INPUT" | grep -o '"reason":"[^"]*"' | head -1 | sed 's/"reason":"//;s/"$//')

echo "[$(date -Iseconds)] Subagent stopped: ${REASON:-completed}" >> "$LATEST_PLAN/troubleshooting/subagent-log.txt"
exit 0
