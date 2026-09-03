# Round Loop (Steps 1-4)

Loaded by /toque:codex-challenge SKILL.md on entry.

## Contents

- Step 1: Send Plan to Codex (Round N)
- Step 2: Parse Codex Response (Schema-Validated JSON)
- Step 3: Claude Responds to Gaps
- Step 4: Check Exit Conditions

## Step 1: Send Plan to Codex (Round N)

1. Record file mtimes of all plan files (for post-call audit)
2. Construct the review prompt using `<codex_prompt_template>`
   - Round 1: base template with plan content
   - Round 2+: add previous round summary
3. Write prompt to temp file using `<codex_invocation>` Step 2
4. Invoke Codex using `<codex_invocation>` Step 3 (120s timeout)
5. Clean up temp file using `<codex_invocation>` Step 4
6. After Codex returns, verify plan file mtimes are unchanged (output audit)
7. If Codex times out: log "Codex timed out on round {N}. Ending loop." → go to Step 5
8. If Codex returns empty: log warning → go to Step 5
9. Display the round banner:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    CODEX CHALLENGE — Round {N} of {max}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

## Step 2: Parse Codex Response (Schema-Validated JSON)

The `--output-schema` flag ensures Codex returns valid JSON matching the schema.
Read the output file written by `-o OUTPUTFILE` and parse it as JSON.

**Parse the JSON output:**
```bash
node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.argv[1], 'utf-8'));
console.log(JSON.stringify(data, null, 2));
" "OUTPUTFILE"
```

**FAIL-CLOSED RULE**: If the output file is missing, empty, or not valid JSON:
- STOP the loop immediately
- Display the raw output (if any) to the user
- Say: "Codex response could not be parsed. You can re-run with a different
  model: `/toque:codex-challenge {name} --model gpt-5.4`"
- Do NOT silently continue

**Fallback**: If `--output-schema` is not supported by the installed Codex version,
fall back to free-text parsing: look for SCORES header, 8 numbered score lines
matching `N. Name: [1-5] — justification`, and TOTAL line. If this also fails,
stop and show raw output.

Extract from the JSON:
- `scores.*` — 8 dimension objects with `score` (1-5) and `justification`
- `total` — sum of all scores
- `gaps[]` — array of gap objects with `dimension`, `score`, `issue`, `fix`

Display the scorecard:
```
Score: {total}/40 ({GREEN|YELLOW|ORANGE|RED})

| Dimension | Score | Justification |
|-----------|-------|---------------|
| 1. Problem Definition | {X}/5 | {justification} |
| ... | ... | ... |

Gaps: {N} found
```

## Step 3: Claude Responds to Gaps

For each gap, prioritizing the lowest-scoring dimensions first:

1. Re-read the relevant section of the plan
2. Check the actual codebase for evidence (grep, read files) if the gap references
   code, architecture, or existing patterns
3. Decide:

**AGREE** — Codex is right:
- State what needs to change
- Make the change to the plan file using the Edit tool (surgical edits only —
  do not reorganize or reformat existing content)
- Log: "AGREE on GAP-N: {summary}. Updated {file} at {section}."

**DISAGREE** — Codex is wrong:
- Cite specific evidence from the plan or codebase
- Explain why the concern does not apply in this context
- Log: "DISAGREE on GAP-N: {summary}. Evidence: {citation}."

**PARTIAL** — Partly valid:
- Acknowledge the valid part, explain what does not apply
- Make targeted changes for the valid part only
- Log: "PARTIAL on GAP-N: {summary}. Addressed {X}, disagree on {Y}."

Display each response:
```
GAP-1 [Dim 4: Risk, 3/5]: No rollback strategy for database migration
  → AGREE — Added rollback strategy in Phase 2 risk section.

GAP-2 [Dim 7: Testing, 3/5]: No characterization tests for legacy code
  → DISAGREE — Characterization tests specified in Phase 1 Step 3
    (see docs/specs/pricing-engine.md lines 45-52).
```

## Step 4: Check Exit Conditions

After completing Step 3, check these conditions IN ORDER:

1. **Score >= 36/40** → GREEN achieved. Go to Step 5.
2. **Max rounds reached** → Go to Step 5 with final score.
3. **No score improvement between rounds AND all dimensions >= 3/5**
   → Convergence plateau. Go to Step 5.
4. **Any dimension at 1/5 or 2/5 persists after Round 2**
   → Halt for human review. Display: "CRITICAL: Dimension {N} remains at {score}/5
   after 2 rounds. This requires human review before proceeding."
   Go to Step 5.
5. **Budget checkpoint**: Check elapsed time. If < 3 minutes remain of the
   15-minute ceiling, force this to be the final round. Go to Step 5 after
   this round completes.
6. **Total elapsed time > 15 minutes** → Abort. Go to Step 5 with partial report.

**Model escalation**: If total score < 24/40 (RED) in Round 1 and `--model` was
not explicitly set, escalate to `gpt-5.4 -c model_reasoning_effort=high` for
Round 2+. Display: "Escalating to gpt-5.4 due to RED score ({score}/40)."

If none of the exit conditions are met → go back to Step 1 for the next round.
