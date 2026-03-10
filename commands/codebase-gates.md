---
description: Generate CI quality gates, Claude Code hooks, and baseline maintenance nudges from DeepGrade audit findings. Creates automated checks that warn when HIGH-risk modules are modified, track file change counts, and nudge you when audit baselines go stale. Requires a Phase 2 audit to have been run first.
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<context>
You orchestrate the generation of quality gates AND baseline maintenance hooks
that enforce DeepGrade audit findings in the development workflow. This turns
static audit reports into active guards with a nervous system that detects drift.

The system has three layers:
1. Passive Tracking: PostToolUse hook counts file changes silently
2. Smart Nudges: Threshold-based suggestions to re-scan
3. Hard Gates: CI blocks PRs when code health declines (optional)
</context>

<workflow>
## Step 1: Verify Prerequisites

Check that Phase 2 audit data exists:
- docs/audit/risk-assessment.md (required)
- docs/audit/deepgrade-report.md (required)

If missing, tell the user:
"Quality gates require Phase 2 audit data. Run /deepgrade:codebase-audit
first, then run /deepgrade:codebase-gates to generate automated checks."

## Step 2: Deploy Gate Generator

Spawn the gate-generator agent with paths to all audit data files.

The gate-generator now produces 6 outputs (up from 4):
1. .github/workflows/deepgrade-gate.yml (CI quality gate)
2. .claude/hooks/hooks.json (Claude Code hooks: risk warnings + baseline nudges)
3. .claude/scripts/check-risk-zone.sh (risk zone checker)
4. .claude/scripts/baseline-tracker.sh (file change counter + staleness checker)
5. .pre-commit-config.yaml (pre-commit hooks, if applicable)
6. docs/audit/gate-config.md (documents everything)

## Step 3: Present Results

After generation, list what was created organized by layer:

```
LAYER 1: Passive Tracking
  .claude/hooks/hooks.json -> PostToolUse counter (tracks file changes per session)
  .claude/scripts/baseline-tracker.sh -> Counter script

LAYER 2: Smart Nudges (when these trigger)
  - After {N} file changes: "Consider running /deepgrade:codebase-delta"
  - Config/migration file changed: "Baseline may be stale. Run /deepgrade:codebase-security?"
  - HIGH-risk module touched: "Run /deepgrade:codebase-characterize before changing this"
  - {N} days since last audit: "Last audit was X days ago"
  - Plan PR merged: "Update baselines with /deepgrade:codebase-delta?"

LAYER 3: Hard Gates (CI)
  .github/workflows/deepgrade-gate.yml -> PR risk scoring + audit staleness check
```

Remind the user:
- Nudges are suggestions, not blocks. You can always ignore them.
- Gates start in ADVISORY MODE (warnings, not blocks) for 2 weeks.
- After 2 weeks, switch to blocking mode by editing the workflow.
- Re-run /deepgrade:codebase-gates after a new audit to update thresholds.
- File change threshold is configurable in baseline-tracker.sh (default: 15).
</workflow>
