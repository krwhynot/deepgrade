# Phase 9: HANDOFF

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

Question: What happens next?

READINESS CHECK before entering this phase:
- Test phase complete (or explicitly waived)
- Audit score GREEN or YELLOW with gap-checked = YES
- No BLOCKED tickets remaining (or explicitly deferred)
- Rollback plan documented

Context-aware guidance based on situation:
- If ready to ship: specific deployment sequence with verification steps
- If gaps remain: prioritized list of what to fix with reasoning
- If timeline pressure: critical path items vs deferrable items

Update manifest.md with final status, decisions made, lessons learned.
Update status.json: handoff -> complete.

Present final summary:
```
Plan: {name} - Complete

Phases: 9/9
Duration: {started} to {completed}
Audit score: {score}/40 ({rating})
Tickets: {done}/{total}

Key decisions: [from approach.md and change records]
Change records: {count} (see changes/ folder)
What shipped: [summary]
What's deferred: [if anything]
```
