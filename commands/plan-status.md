---
description: (deepgrade) Show status of all active plans or detailed status of a specific plan. Checks for staleness, shows progress, and recommends next action. Pass a plan name for details or no argument for overview.
argument-hint: "[plan-name]"
allowed-tools: Read, Grep, Glob, Bash
---

<workflow>
## If no argument: Show all plans

```bash
PLANS_DIR="docs/plans"
[ ! -d "$PLANS_DIR" ] && [ -d "plans" ] && PLANS_DIR="plans"
if [ ! -d "$PLANS_DIR" ]; then
  echo "No plans found. Start one with /deepgrade:plan <name>."
  exit 0
fi

for d in "$PLANS_DIR"/*/; do
  [ ! -d "$d" ] && continue
  NAME=$(basename "$d")

  # Read status.json if it exists
  if [ -f "$d/status.json" ]; then
    # Interpreter name differs by host: Windows python.org installs ship
    # `python` only, most Linux distros ship `python3` only. Try both, then fall
    # back to grep so a missing interpreter degrades to a slightly weaker read
    # rather than an empty phase.
    PY=""
    command -v python3 >/dev/null 2>&1 && PY=python3
    [ -z "$PY" ] && command -v python >/dev/null 2>&1 && PY=python
    if [ -n "$PY" ]; then
      PHASE=$("$PY" -c "
import json, sys
with open(sys.argv[1]) as f:
  print(json.load(f).get('current_phase', 'unknown'))
" "$d/status.json" 2>/dev/null)
    fi
    if [ -z "$PHASE" ]; then
      PHASE=$(grep -o '"current_phase"[[:space:]]*:[[:space:]]*"[^"]*"' "$d/status.json" 2>/dev/null \
              | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
    fi
    [ -z "$PHASE" ] && PHASE="unknown"
  else
    PHASE="no status"
  fi

  # Count files per subdirectory
  BRAINSTORM=$([ -f "$d/brainstorm.md" ] && echo "done" || echo "-")
  RESEARCH=$(ls "$d/research/" 2>/dev/null | wc -l)
  APPROACH=$([ -f "$d/approach.md" ] && echo "done" || echo "-")
  PLAN=$([ -f "$d/plan.md" ] && echo "done" || echo "-")
  AUDIT=$([ -f "$d/audit.md" ] && echo "done" || echo "-")
  TEST=$([ -f "$d/test-plan.md" ] && echo "done" || echo "-")

  echo "$NAME | phase: $PHASE | brainstorm: $BRAINSTORM | research: $RESEARCH files | approach: $APPROACH | plan: $PLAN | audit: $AUDIT | test: $TEST"
done
```

Present as a summary table. For each plan, recommend the next action.

## If plan name provided: Show detailed status

Read docs/plans/{date}-{name}/status.json.

Show:
1. Phase-by-phase status with freshness indicators
2. Any STALE or WARNING phases (check file hashes)
3. Build progress (if in build phase): tickets done/total/blocked
4. Audit score (if audit complete)
5. Recommended next action with reasoning

```
Plan: worldpay-canada
Created: 2026-03-07
Current Phase: 6 - Build (in_progress)
Audit Score: 31/40 (YELLOW)

| # | Phase | Status | Freshness | File |
|---|-------|--------|-----------|------|
| 1 | Brainstorm | Complete | Fresh | brainstorm.md |
| 2 | Research | Complete | Warning | research/findings.md |
| 3 | Pre-Plan | Complete | Fresh | approach.md |
| 4 | Plan | Complete | Fresh | plan.md |
| 5 | Audit | Complete | Fresh | audit.md (31/40 YELLOW) |
| 6 | Build | In Progress | - | 2/24 tickets done, 1 blocked |
| 7 | Test | Not Started | - | - |
| 8 | Handoff | Not Started | - | - |

Warning: Research findings may be stale (related files in CreditCard/ changed).
Consider re-running research if current build work affects payment code.

Next action: Continue building. Current focus: POS-5163 (receipt strings).
Resume with: /deepgrade:plan worldpay-canada
```
</workflow>
