# Phase 6: BUILD

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

## Contents

- Hard gate: assumption verification (LINT-08)
- Parallel execution rule
- Document actions and codebase actions
- Change control and change record template

Question: What got built/changed?

HARD GATE: ASSUMPTION VERIFICATION (LINT-08)
Before ANY build work begins, check assumptions in status.json:

```
For each assumption where impact = HIGH:
  If status = unverified:
    -> BLOCK entry to Phase 6
    -> Present: "Cannot start Build. These HIGH-impact assumptions are unverified:"
    -> List each with its verification method
    -> Offer: [1] Verify now  [2] Accept risk (waiver)  [3] Back to research

  If status = verified: -> PASS
  If status = waived: -> PASS (with documented risk acceptance)
  If status = falsified: -> BLOCK and return to Phase 3 (approach is invalid)

For each assumption where impact = MEDIUM and status = unverified:
  -> WARN but allow proceeding

For each assumption where impact = LOW and status = unverified:
  -> INFO only
```

If user chooses [2] Accept risk (waiver), require:
- Documented risk statement
- Approver name
- Contingency plan if assumption fails
- Update assumption status to "waived" in status.json

This gate is NOT advisory. It is a hard block. The plan CANNOT proceed to
Build with unverified HIGH-impact assumptions unless explicitly waived.

This phase actively assists with implementation.

PARALLEL EXECUTION RULE:
Before starting tickets, analyze the dependency graph from the plan:
- Tickets with NO dependencies on other tickets can run IN PARALLEL as subagents
- Tickets that depend on other tickets must wait until dependencies complete
- Group independent tickets into parallel batches

```
Example dependency graph:
  POS-5160 (no deps)     -> Batch 1 (parallel)
  POS-5161 (no deps)     -> Batch 1 (parallel)
  POS-5162 (no deps)     -> Batch 1 (parallel)
  POS-5163 (needs 5160)  -> Batch 2 (after 5160 completes)
  POS-5164 (needs 5162)  -> Batch 2 (after 5162 completes)
  POS-5165 (needs 5163, 5164) -> Batch 3 (after Batch 2)
```

Present the batch plan to the user:
"I can run {N} tickets in parallel (Batch 1: {tickets}).
Batch 2 ({tickets}) depends on Batch 1. Execute Batch 1 in parallel? [Y/n]"

For each parallel batch, deploy subagents:
- Each subagent gets: ticket description, relevant plan sections, codebase context
- Each subagent writes to a separate branch or file set
- Orchestrator tracks progress and resolves conflicts between parallel work

DOCUMENT ACTIONS (no approval needed):
- Track ticket progress (update status.json with per-ticket notes)
- Answer questions about the plan ("what file for POS-5162?")
- Provide code context from research
- Suggest next ticket to work on based on dependencies

CODEBASE ACTIONS (approval required per action):
- "Generate code scaffold for CcReceiptStrings.cs? [Y/n]"
- "Run characterization tests on Printing.FormatReceipt? [Y/n]"
- "Create branch description for Phase 1 tickets? [Y/n]"

CHANGE CONTROL (backward flow rules with immutable records):
After Phase 3 scope lock, accepted plan documents are immutable. Changes
require a formal Change Record, not silent edits.

- Minor discovery during build:
  1. Create docs/plans/{date}-{name}/changes/CR-{N}.md with:
     - What changed and why
     - Which document/section it supersedes
     - The NEW content (the CR is the authoritative version going forward)
     - Impact on other phases
  2. Add a status line to the TOP of the original document: "SUPERSEDED by CR-{N} on {date}"
     Do NOT modify the original document's content. The CR contains the new version.
  3. Update manifest.md with link to the Change Record
  4. Update status.json: { "change_records": [{ "id": "CR-001", "date": "...", "summary": "..." }] }

- Scope change discovered -> "This changes the scope. Go back to Pre-Plan? [Y/n]"
  If yes: create CR-{N} documenting the scope change reason, mark pre_plan
  and plan as STALE, return to Phase 3. Original approach.md preserved.

- New blocker found -> mark current build ticket as BLOCKED with reason,
  create CR-{N} documenting the blocker and its impact.

- Implementation diverges from plan -> create CR-{N} documenting the divergence
  and rationale. This replaces informal ADR/change notes.

Change Record template:
```markdown
# CR-{N}: {Title}
Date: {date}
Author: {name}
Supersedes: {document or section}

## What Changed
## Why It Changed
## Impact on Other Phases
```

Update status.json with build progress, manifest.md.

No gate. User stays in Build until ready for Impact Review.
