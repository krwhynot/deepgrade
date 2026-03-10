---
description: Audit any technical plan, spec, or proposal for gaps, risks, and leadership readiness. Scores the plan across 8 dimensions (problem, architecture, phasing, risk, rollback, timeline, testing, team). Produces a go/no-go assessment and leadership presentation outline. Pass a file path or describe the plan.
argument-hint: "[plan-file-path or description] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<plan_awareness>
If $ARGUMENTS contains --plan {name}, write output to
docs/plans/{date}-{name}/audit.md and update docs/plans/{date}-{name}/manifest.md
with a link to the audit. Also update status.json.

If the file path starts with docs/plans/, auto-detect the plan context and write
audit output into that plan's folder: docs/plans/{date}-{name}/audit.md.

If no --plan flag and no auto-detect, present the audit results directly in the
conversation. Do NOT create docs/audit/plan-audit.md.
</plan_awareness>

<context>
You orchestrate a technical plan audit. The user has received or written a plan
and needs it reviewed before approving, presenting, or executing it.

This command works on ANY technical plan:
- Migration/extraction specs (monolith decomposition, language migration)
- Architecture proposals (microservices, event-driven, API design)
- Refactoring plans (VB.NET to C#, framework upgrades, modernization)
- Feature implementation plans (new capabilities, integrations)
- Infrastructure proposals (cloud migration, CI/CD setup, observability)

The audit is objective and constructive. It finds gaps and suggests fixes.
</context>

<workflow>
## Step 1: Locate the Plan

If $ARGUMENTS is a file path, read that file.
If $ARGUMENTS is a description, search for matching files:
```bash
find . -name "*.md" -o -name "*.txt" -o -name "*.doc" | xargs grep -l "$ARGUMENTS" 2>/dev/null | head -10
```

If no plan is found, ask the user to provide the plan:
"I couldn't find a plan matching '$ARGUMENTS'. Options:
1. Paste the plan text directly into the chat
2. Provide the exact file path
3. Describe what plan you want audited"

## Step 2: Deploy Plan Auditor

Spawn the plan-auditor agent with:
- The full plan text
- The codebase root path (so it can verify claims against actual files)
- If linked to a plan: write output to docs/plans/{date}-{name}/audit.md
- If standalone: present results in conversation (no file creation)

## Step 3: Present Results

After the auditor completes, present:
1. Overall score (X/40) with color (Green/Yellow/Orange/Red)
2. The scorecard table (8 dimensions)
3. Top 3 gaps that must be addressed
4. Go/No-Go recommendation
5. If linked to a plan, link to full report at docs/plans/{date}-{name}/audit.md

If the user mentioned presenting to leadership, also highlight:
- The 5-6 slide outline from the report
- The executive summary
- The go/no-go criteria
</workflow>

<examples>
User: /deepgrade:quick-audit docs/specs/pricing-engine-extraction.md
-> Reads the spec, scores it, finds gaps, produces audit report

User: /deepgrade:quick-audit "the migration plan in our last meeting notes"
-> Searches for matching files, asks for clarification if ambiguous

User: /deepgrade:quick-audit
-> "What plan would you like me to audit? Provide a file path or paste the plan."
</examples>
