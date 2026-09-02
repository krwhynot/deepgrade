# Report (Steps 5-6)

Loaded by /deepgrade:codex-challenge SKILL.md on entry.

## Step 5: Write Codex Review Report

Write `codex-review.md` to the output location determined in Step 0.

Report template:

```markdown
# Codex Adversarial Review Report

| Field | Value |
|-------|-------|
| Plan | {name} |
| Date | {ISO date} |
| Model | {codex model used} |
| Rounds | {N} |
| Final Score | {score}/40 ({rating}) |
| Target | 36/40 |

## Score Trajectory

{Round 1: X/40 → Round 2: Y/40 → ... → Round N: Z/40}

## Per-Dimension Score History

| Dimension | Round 1 | Round 2 | ... | Final |
|-----------|---------|---------|-----|-------|
| 1. Problem Definition | {X} | {Y} | ... | {Z} |
| 2. Architecture | ... | ... | ... | ... |
| ... | ... | ... | ... | ... |

## Gap Resolution Log

### Round 1
| # | Dimension | Score | Issue | Response | Outcome |
|---|-----------|-------|-------|----------|---------|
| GAP-1 | Risk (4) | 3/5 | {issue} | AGREE | Fixed in spec |
| GAP-2 | Testing (7) | 3/5 | {issue} | DISAGREE | Evidence cited |

### Round 2 (if applicable)
...

## Changes Made to Plan

| File | Section | Change |
|------|---------|--------|
| {file} | {section} | {description of change} |

## Unresolved Disagreements

{Any gaps where Claude DISAGREED and Codex maintained the concern. Include both
perspectives for human review.}

## Metadata

| Metric | Value |
|--------|-------|
| Total gaps raised | {N} |
| Gaps accepted (AGREE) | {N} |
| Gaps rejected (DISAGREE) | {N} |
| Gaps partially accepted | {N} |
| Acceptance rate | {percent} |
| Total elapsed time | {minutes} |
```

If a plan folder exists, also update `manifest.md` with a link to the codex-review.

## Step 6: Display Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 CODEX CHALLENGE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Plan: {name}
 Score: {trajectory} {✓ GREEN | ⚠ YELLOW | ...}
 Rounds: {N} | Target: 36/40
 Gaps: {agreed} fixed | {disagreed} defended | {partial} partial
 Report: {path to codex-review.md}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
