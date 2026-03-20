---
description: (deepgrade) Create a structured technical plan from a vague objective. Analyzes the codebase, identifies risks, generates phased approach with timeline estimates, testing strategy, and rollback plan. The output is a plan that scores well on the plan auditor's 8 dimensions. Pass an objective or requirement description.
argument-hint: "[objective description] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<plan_awareness>
If $ARGUMENTS contains --plan {name}:
  1. Write spec to docs/specs/{name}.md
  2. If docs/plans/*-{name}/ exists: update its manifest.md and status.json
  3. If docs/plans/*-{name}/ does NOT exist: do NOT create a plan folder.
     Quick-plan is a spec generator, not a plan workflow. The spec is the
     only output. If the user wants a full plan folder, use /deepgrade:plan.
  4. Note in output: "Spec linked to plan: {name}" or "Spec created standalone"

If no --plan flag, use the default docs/specs/ location.
</plan_awareness>

<context>
You orchestrate the creation of a structured technical plan. The user knows
what they want to accomplish but needs a plan that will survive leadership
review and engineer scrutiny.

This command works for any objective:
- "Extract pricing logic from Order.vb"
- "Add authentication to the API"
- "Migrate from VB.NET to C# for the reporting module"
- "Set up CI/CD for the project"
- "Integrate with the new payment processor"
</context>

<workflow>
## Step 1: Clarify the Objective

If $ARGUMENTS is clear enough, proceed.
If vague, ask up to 3 clarifying questions:
1. What is the desired end state?
2. Are there constraints (timeline, team, technology)?
3. What is the biggest risk you're worried about?

## Step 2: Check for Existing Audit Data

Look for Phase 2 audit data that would inform the plan:
```bash
ls docs/audit/risk-assessment.md docs/audit/feature-inventory.md \
   docs/audit/dependency-map.md docs/audit/integration-scan.md 2>/dev/null
```

If audit data exists, pass it to the scaffolder agent. The audit tells you
what's risky, what's safe, and what depends on what. Plans informed by audit
data are significantly better.

## Step 3: Deploy Plan Scaffolder

Spawn the plan-scaffolder agent with:
- The objective from $ARGUMENTS
- The codebase root path
- Any audit data found in Step 2
- Clarifications from Step 1 (if any)

## Step 4: Auto-Audit (Evaluator)

After the scaffolder completes, automatically run the plan-auditor agent against
the generated plan. Do NOT ask the user to run /deepgrade:quick-audit separately.

Spawn the plan-auditor agent with:
- The generated plan at docs/specs/[plan-name].md
- The codebase root path
- Instruction: produce structured findings with scores per dimension

Record the audit results:
- Overall score (X/40)
- Gap-checked status (YES/NO)
- Specific gaps found (list with dimension references)

## Step 5: Revision Loop (Optimizer)

If score >= 32/40 AND gap-checked = YES:
  -> Skip revision, proceed to Step 6

If score < 32/40 OR gap-checked = NO:
  -> Feed audit findings back to the plan-scaffolder for targeted revision
  -> The scaffolder receives: "Revise the following sections to address these gaps:"
     followed by the specific findings from the auditor
  -> The scaffolder revises ONLY the failing sections (not the entire plan)
  -> Re-run the plan-auditor on the revised plan

Maximum 2 revision iterations. After 2 iterations, accept the plan at its
current quality with audit findings attached.

Track iteration history in the plan file:
```markdown
## Revision History
| Version | Score | Gap-Checked | Gaps Found | Action |
|---------|-------|-------------|------------|--------|
| v1      | 24/40 | NO          | 7          | Revised sections 4, 5, 7 |
| v2      | 35/40 | YES         | 0          | Accepted |
```

## Step 6: Present Results

After the loop completes:
1. Show the plan summary (problem, phases, timeline, key risks)
2. Show the final audit score and whether gap-checked
3. If revisions occurred, note: "Plan was revised {N} time(s). Score improved from {X} to {Y}."
4. Show the Revision History table
5. Note evidence basis distribution (should be <40% Tier C)
6. Note: "This plan has been auto-audited. Review with your team before presenting."
</workflow>
