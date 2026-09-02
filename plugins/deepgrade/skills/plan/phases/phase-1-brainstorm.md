# Phase 1: BRAINSTORM

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

Question: What problem are we solving?

IF input is a vague idea or just a plan name:
  Ask structured questions ONE AT A TIME:
  1. "What problem are you trying to solve?"
  2. "Who is affected by this problem?"
  3. "Why is this happening now? What triggered it?"
  4. "What does success look like?"

IF input includes source docs (from keyword):
  Read the source material, draft a problem statement, ask:
  "Based on what I read, here's the problem as I understand it: [statement].
   Is this right, or should I adjust?"

IF input includes an existing ticket or spec:
  Extract the problem statement, confirm with user.

Write brainstorm.md with: Problem Statement, Goals, Non-Goals, Open Questions, Ownership (plan owner, tech reviewer, business approver - ask or default TBD).

Update status.json: brainstorm -> complete, research -> not_started
Update manifest.md progress table.

GATE: Ask user "Problem defined. Ready to move to research? [Y/n]"
On confirm -> proceed to Phase 2.
