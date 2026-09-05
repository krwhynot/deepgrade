---
description: Audit any technical plan, spec, or proposal for gaps, risks, and leadership readiness. Reviews the plan across 8 dimensions (problem, architecture, phasing, risk, rollback, timeline, testing, team) and returns a per-criterion verdict (MET/UNMET/N_A) with evidence. Produces a go/no-go assessment and leadership presentation outline. Pass a file path or describe the plan.
argument-hint: "[plan-file-path or description] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<plan_awareness>
Every audit has a gate folder that receives audit.md, evidence/ and the .canary/
scratch copy. Which folder depends on what is being audited:

If $ARGUMENTS contains --plan {name}, or the file path starts with docs/plans/,
the gate folder is that plan's folder, docs/plans/{date}-{name}/. This is the
plan's Stage 2 gate run again against the same document; update manifest.md
with a link to the audit and update status.json.

Otherwise the gate folder sits beside the audited file, named after it without
the extension: docs/specs/pricing.md is audited into docs/specs/pricing/.

If the plan was pasted rather than given as a path, write it to
docs/specs/{slug}.md first and say so; the gate needs a file to mutate and
evidence records need a file to cite. Do NOT create docs/audit/plan-audit.md.
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

## Step 2: Design gate (the same gate as /toque:plan Stage 2)

Do not spawn the plan-auditor on your own terms. The gate is defined once, in
the stage file, and this command runs that definition:

Read `${CLAUDE_PLUGIN_ROOT}/skills/plan/stages/stage-2-design.md` and execute
its `<design_gate>` block, verbatim, with these bindings:

  {doc}        the file located in Step 1
  {gate_dir}   the gate folder chosen in <plan_awareness>
  {generator}  none

The block spawns the plan-auditor on a canary-mutated working copy, checks that
the planted defect was found, validates every evidence record mechanically,
applies the lint registry and the gap outputs, and derives PASS or NOT PASS
from its gate expression. With no generator bound there is no revision loop:
NOT PASS is reported with the unmet criteria named, and the document's author
decides what to do. If the block and this description ever disagree, the block
wins.

## Step 3: Present Results

After the gate completes, present:
1. The canonical gate result: `PASS` — passed the pass, or `NOT PASS` — back to
   the kitchen, with the criteria that failed. For each criterion, add the
   kitchen translation after its canonical token: `MET` — passed the pass;
   `UNMET` — back to the kitchen; `N_A` — not on this plate.
2. Canary found or missed, and the evidence validator's exit code; a missed
   canary means the audit could not be trusted and its findings are not shown
   as findings
3. Findings by severity, each citing file:line evidence
4. Top 3 gaps that must be addressed
5. Go/No-Go recommendation
6. The gate record: {gate_dir}/audit.md and {gate_dir}/evidence/, to be
   committed with the audited document

If the user mentioned presenting to leadership, also highlight:
- The 5-6 slide outline from the report
- The executive summary
- The go/no-go criteria
</workflow>

<examples>
User: /toque:quick-audit docs/specs/pricing-engine-extraction.md
-> Reads the spec, returns a verdict per criterion, finds gaps, produces audit report

User: /toque:quick-audit "the migration plan in our last meeting notes"
-> Searches for matching files, asks for clarification if ambiguous

User: /toque:quick-audit
-> "What plan would you like me to audit? Provide a file path or paste the plan."
</examples>
