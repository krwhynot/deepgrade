---
description: Create a structured technical plan from a vague objective. Analyzes the codebase, identifies risks, generates phased approach with timeline estimates, testing strategy, and rollback plan. The output is a plan built to survive the design gate. Pass an objective or requirement description.
argument-hint: "[objective description] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<plan_awareness>
If $ARGUMENTS contains --plan {name}:
  1. Write spec to docs/specs/{name}.md
  2. If docs/plans/*-{name}/ exists: update its manifest.md and status.json
  3. If docs/plans/*-{name}/ does NOT exist: do NOT create a plan folder.
     Quick-plan is a spec generator, not a plan workflow. The spec is the
     only output. If the user wants a full plan folder, use /toque:plan.
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

Look for audit data in `docs/audit/` that would inform the plan. Toque does not
produce it; a codebase-analysis tool may have left it:
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
the generated plan. Do NOT ask the user to run /toque:quick-audit separately.

Spawn the plan-auditor agent with:
- The generated plan at docs/specs/[plan-name].md
- The codebase root path
- Instruction: produce structured findings — one verdict per criterion (MET,
  UNMET or N_A) with evidence, never a score

Record the audit results:
- Findings by severity with evidence, reported only — they do not gate anything
- Gap-checked status (YES/NO)
- Specific gaps found, each named by criterion id with a location

## Step 5: Revision Loop (Optimizer)

This uses the same gate as `/toque:plan` Stage 2 (Design). It has to: a command that
accepted a plan on a score the model gave itself would be a way around the gate
rather than a lighter version of it, and the way around is the one that gets used.

If every applicable criterion is MET or N_A after validation, and gap-checked = YES:
  -> Skip revision, proceed to Step 6

Otherwise:
  -> Feed audit findings back to the plan-scaffolder for targeted revision
  -> The scaffolder receives one line per unmet criterion, in the form
     "{criterion_id} UNMET: {what is missing}. Location: {file}:{line}."
     Never the rubric, the totals, the bands, or how close the plan came
  -> The scaffolder revises ONLY the failing sections (not the entire plan)
  -> Re-run the plan-auditor on the revised plan, as a FRESH instance

Maximum 2 revision iterations. After 2 iterations, accept the plan at its
current quality with audit findings attached.

Track iteration history in the plan file:
```markdown
## Revision History
| Version | Verdict | Gap-Checked | Gaps Found | Action |
|---------|-------|-------------|------------|--------|
| v1      | NOT PASS | NO          | 7          | Revised sections 4, 5, 7 |
| v2      | PASS     | YES         | 0          | Accepted |
```

## Step 6: Present Results

After the loop completes:
1. Show the plan summary (problem, phases, timeline, key risks)
2. Show the final gate verdict (PASS / NOT PASS), the MET/UNMET/N_A counts, and whether gap-checked
3. If revisions occurred, note: "Plan was revised {N} time(s). {X} criteria moved from UNMET to MET."
4. Show the Revision History table
5. Note evidence basis distribution (should be <40% Tier C)
6. Note: "This plan has been auto-audited. Review with your team before presenting."
</workflow>
