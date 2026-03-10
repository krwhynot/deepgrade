---
description: Re-measure the codebase against previous audit baselines. Shows what improved, what regressed, tracks KPIs over time, and flags stale findings. Quick check (2-3 min) without running a full scan. Use after making changes to see if scores improved.
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<context>
You are the orchestrator for a delta scan. This is a quick comparison against
previous audit baselines, NOT a full Phase 1 or Phase 2 scan.

The delta scan answers: "Since the last audit, what got better and what got worse?"
It takes 2-3 minutes, not the 10-15 minutes of a full scan.
</context>

<workflow>
## Step 1: Check for Baselines

Look for previous audit data:
- docs/audit/readability/readability-score.json
- docs/audit/deepgrade-report.md
- docs/audit/kpi-dashboard.md

If none exist, tell the user:
"No previous baselines found. Run /deepgrade:readiness-scan first to
establish a baseline, then run /deepgrade:codebase-delta after making changes."

## Step 2: Deploy Delta Scanner Agent

Spawn the delta-scanner agent with:
- Path to all baseline files found in Step 1
- Current date for confidence decay calculations
- Instructions to write docs/audit/delta-report.md and docs/audit/kpi-dashboard.md

## Step 3: Present Results

After the agent completes, read both output files and present:
1. Score delta (up or down, by how many points)
2. Top 3 improvements
3. Top 3 regressions (if any)
4. Stale findings count
5. Whether a full re-scan is recommended

If the delta suggests the readiness score crossed a threshold (e.g., crossed 80%
or crossed 90%), recommend running a full /deepgrade:readiness-scan to confirm.

If stale findings are detected (>60 days), recommend a full re-scan.

After the delta scan completes, reset the baseline tracker:
```bash
if [ -f ".claude/scripts/baseline-tracker.sh" ]; then
  bash .claude/scripts/baseline-tracker.sh reset
fi
```
This zeroes the file change counter since baselines are now fresh.
</workflow>

<output_guidance>
Keep the summary concise. The user wants to know:
- Did my changes help? (yes/no, by how much)
- What should I do next? (specific recommendation)
- Are any findings going stale? (time pressure)

The detailed data is in docs/audit/delta-report.md and docs/audit/kpi-dashboard.md.
Don't repeat every line. Summarize the key takeaways.
</output_guidance>
