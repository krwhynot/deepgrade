---
description: (deepgrade) Create a structured technical plan from a vague objective. Analyzes the codebase, identifies risks, generates phased approach with timeline estimates, testing strategy, and rollback plan. The output is a plan that scores well on the plan auditor's 8 dimensions. Pass an objective or requirement description.
argument-hint: "[objective description] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<plan_awareness>
If $ARGUMENTS contains --plan {name}, write output to docs/specs/{name}.md
and update docs/plans/{date}-{name}/manifest.md with a link to the spec.
Also update docs/plans/{date}-{name}/status.json to mark plan as "complete".

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

## Step 4: Present Results

After the scaffolder completes:
1. Show the plan summary (problem, phases, timeline, key risks)
2. Note the self-audit score (should be 32+/40)
3. Suggest: "Run /deepgrade:quick-audit docs/specs/[plan-name].md for a formal audit"
4. Note: "This plan is a starting point. Review with your team before presenting."
</workflow>
