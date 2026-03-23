---
description: (deepgrade) Adversarial review loop between Claude and OpenAI Codex CLI. Codex scores your plan across 8 dimensions (max 40), Claude optimizes until score reaches 36/40 GREEN. Implements the Evaluator-Optimizer pattern with score-driven convergence. Pass a plan name, file path, or leave empty for auto-detect.
argument-hint: "[plan-name or file-path] [--rounds N] [--model gpt-5.3-codex]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<identity>
You orchestrate an adversarial review loop between Claude Code (you) and OpenAI
Codex CLI. You are the Optimizer; Codex is the Evaluator. Each round, you send
the plan to Codex for scoring, then address the gaps Codex identifies.

You are NOT a rubber stamp for either model. You evaluate each gap on its merits
against THIS codebase. AGREE when Codex is right. DISAGREE with evidence when
it is wrong. The goal is convergence on a better plan, not victory for either side.
</identity>

<context>
Single-model review creates blind spots — Claude auditing Claude shares the same
training biases. Cross-model adversarial review catches gaps that same-model
review misses. Codex operates independently (different training data, different
architecture), providing a genuinely orthogonal perspective.

This command extends the existing one-shot `plan-review.js` hook into a multi-round
score-driven optimization loop following the Evaluator-Optimizer pattern from
`docs/planning-techniques/02-evaluator-optimizer-loop.md`.

The loop targets **36/40** (upper GREEN threshold from DeepGrade's plan-auditor rubric):
- GREEN: 32-40 (plan is solid)
- YELLOW: 24-31 (notable gaps)
- ORANGE: 16-23 (critically incomplete areas)
- RED: 1-15 (fundamentally flawed)
</context>

<plan_awareness>
Parse $ARGUMENTS for three modes:

**Mode 1 — Plan name** (e.g., `worldpay-canada`):
```bash
ls -td docs/plans/*-$NAME/ 2>/dev/null | head -1
```
Read `status.json` from the matched folder. Then read plan content in priority order:
1. `docs/specs/$NAME.md` (Phase 4 spec — most detailed)
2. `docs/plans/{date}-{name}/approach.md` (Phase 3 scope/options)
3. `docs/plans/{date}-{name}/brainstorm.md` (Phase 1 problem definition)

**Mode 2 — File path** (e.g., `docs/specs/pricing-engine.md`):
Read that file directly. If path starts with `docs/plans/`, auto-detect the plan context.

**Mode 3 — Empty** (no arguments):
```bash
ls -td docs/plans/*/ 2>/dev/null | head -1
```
Use the most recent plan folder's primary document.

**Content assembly**: Concatenate all available plan documents. Cap at 12,000 characters.
If over limit, truncate from the bottom of the lowest-priority document.

**Parse flags from $ARGUMENTS**:
- `--rounds N`: Max rounds (default 3, max 5)
- `--model MODEL`: Codex model (default `gpt-5.3-codex`)

**Output location**:
- If plan folder exists: `docs/plans/{date}-{name}/codex-review.md`
- If only spec file: same directory as the spec
- If standalone: present in conversation only
</plan_awareness>

<codex_invocation>
## Codex CLI Invocation Pattern

All Codex interactions use the temp-file pattern for Windows compatibility and
`--output-schema` for structured JSON output. NEVER pass multi-line prompts as
inline bash arguments.

### Step 1: Check Codex availability (once, before first call)
```bash
codex --version
```
If this fails: "Codex CLI not found. Install with: `npm i -g @openai/codex`"

### Step 2: Write prompt and schema to temp files
Use Node.js to write both the prompt and the JSON schema file:
```bash
node -e "
const fs = require('fs');
const os = require('os');
const path = require('path');
const ts = Date.now();
const promptFile = path.join(os.tmpdir(), 'codex-challenge-' + ts + '.txt');
const schemaFile = path.join(os.tmpdir(), 'codex-challenge-schema-' + ts + '.json');
fs.writeFileSync(promptFile, process.argv[1], 'utf-8');
fs.writeFileSync(schemaFile, process.argv[2], 'utf-8');
console.log(promptFile + '\n' + schemaFile);
" "PROMPT_CONTENT" "SCHEMA_JSON"
```

The JSON schema enforces structured output (see `<output_schema>` section below).

### Step 3: Invoke Codex in read-only sandbox
Codex CLI defaults to **read-only sandbox** — verified on v0.116.0. No dangerous
bypass flag needed. Use `--ephemeral` to avoid persisting session files.
Use `--output-schema` to enforce structured JSON response.
Run from `os.tmpdir()` for additional isolation.
```bash
cd "$(node -e "console.log(require('os').tmpdir())")" && cat "PROMPTFILE" | codex exec -m MODEL --ephemeral --output-schema "SCHEMAFILE" -o "OUTPUTFILE" --skip-git-repo-check -
```
Timeout: 120 seconds per call.

### Step 4: Read output and clean up temp files
Read the JSON output file, then clean up all temp files:
```bash
cat "OUTPUTFILE"
node -e "
const fs = require('fs');
for (const f of process.argv.slice(1)) {
  try { fs.unlinkSync(f); } catch(e) {}
}
" "PROMPTFILE" "SCHEMAFILE" "OUTPUTFILE"
```
</codex_invocation>

<review_dimensions>
## 8 Adversarial Review Dimensions

Each dimension is scored 1-5 by Codex. These are complementary to (not identical
to) the plan-auditor's 8 dimensions — optimized for cross-model adversarial review.

| # | Dimension | Challenge Question |
|---|-----------|-------------------|
| 1 | Problem Definition | Is the problem real and well-scoped? |
| 2 | Architecture | Is the design sound and appropriately complex? |
| 3 | Sequencing | Are phases ordered to minimize risk? |
| 4 | Risk | What blind spots exist? |
| 5 | Rollback | Is the undo strategy realistic? |
| 6 | Timeline | Are estimates evidence-based? |
| 7 | Testing | Would tests actually catch regressions? |
| 8 | Omissions | What is conspicuously absent? |

### Scoring Rubric (included in Codex prompt)
- 5/5 = Thorough, no gaps, evidence-backed
- 4/5 = Solid but one minor gap
- 3/5 = Present but notable gaps
- 2/5 = Critically incomplete
- 1/5 = Absent or fundamentally flawed
</review_dimensions>

<output_schema>
## Codex Output Schema

The `--output-schema` flag enforces structured JSON output from Codex CLI,
eliminating free-text parsing entirely. Write this schema to a temp file and
pass it via `--output-schema SCHEMAFILE`.

```json
{
  "type": "object",
  "properties": {
    "scores": {
      "type": "object",
      "properties": {
        "problem_definition": { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "architecture":       { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "sequencing":         { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "risk":               { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "rollback":           { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "timeline":           { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "testing":            { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] },
        "omissions":          { "type": "object", "properties": { "score": { "type": "integer", "minimum": 1, "maximum": 5 }, "justification": { "type": "string" } }, "required": ["score", "justification"] }
      },
      "required": ["problem_definition", "architecture", "sequencing", "risk", "rollback", "timeline", "testing", "omissions"]
    },
    "total": { "type": "integer", "minimum": 8, "maximum": 40 },
    "gaps": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "dimension": { "type": "string" },
          "score": { "type": "integer", "minimum": 1, "maximum": 5 },
          "issue": { "type": "string" },
          "fix": { "type": "string" }
        },
        "required": ["dimension", "score", "issue", "fix"]
      },
      "maxItems": 7
    }
  },
  "required": ["scores", "total", "gaps"],
  "additionalProperties": false
}
```

This schema is passed to Codex via `--output-schema`. Codex CLI validates the
response shape automatically. If the response does not match the schema, Codex
CLI will return an error — this is the schema-enforced fail-closed mechanism.
</output_schema>

<codex_prompt_template>
## Codex Review Prompt Template

Use this template for the initial round. For subsequent rounds, append the
round summary section at the bottom. The `--output-schema` flag handles
response formatting, so the prompt focuses on review instructions only.

```
You are a senior software architect performing an adversarial review of a plan
created by another AI (Claude Code). Your job is to find REAL problems, not
nitpick. Focus on things that would cause production failures, missed deadlines,
or architectural regret.

Score this plan across 8 dimensions (1-5 each, max 40):

Scoring Rubric:
- 5/5 = Thorough, no gaps, evidence-backed
- 4/5 = Solid but one minor gap
- 3/5 = Present but notable gaps
- 2/5 = Critically incomplete
- 1/5 = Absent or fundamentally flawed

Dimensions:
1. problem_definition — Is the problem real and well-scoped?
2. architecture — Is the design sound and appropriately complex?
3. sequencing — Are phases ordered to minimize risk?
4. risk — What blind spots exist?
5. rollback — Is the undo strategy realistic?
6. timeline — Are estimates evidence-based?
7. testing — Would tests actually catch regressions?
8. omissions — What is conspicuously absent?

PLAN TO REVIEW:
{plan_content}

Respond with scores for all 8 dimensions, a total, and gaps for any dimension
scoring below 5 (max 7 gaps). Your response will be validated against a JSON schema.
```

### Re-review prompt addition (Round 2+)
Append this after the plan content:

```
PREVIOUS ROUND SUMMARY:
{for each gap: gap text + Claude's response (AGREE/DISAGREE/PARTIAL) + evidence}

Focus on:
1. Were AGREE changes implemented correctly?
2. Are DISAGREE responses convincing, or do they dodge the issue?
3. Did the changes introduce NEW problems?
```
</codex_prompt_template>

<workflow>
## Step 0: Detect Plan and Parse Arguments

1. Parse `$ARGUMENTS` using the `<plan_awareness>` rules
2. Extract `--rounds` (default 3, max 5) and `--model` (default `gpt-5.3-codex`)
3. Read plan content; assemble from multiple files if needed (cap at 12K chars)
4. If no plan found, display:
   "No plan found. Options:
   1. `/deepgrade:codex-challenge {plan-name}` — review a specific plan
   2. `/deepgrade:codex-challenge docs/specs/my-spec.md` — review any spec file
   3. Create a plan first with `/deepgrade:plan` or `/deepgrade:quick-plan`"
5. Display: "Found plan: {name} ({N} chars). Starting Codex challenge with {model}, max {rounds} rounds. Target: 36/40."
6. Run `codex --version` to verify availability. If fails, abort with install instructions.
7. Record start timestamp for time budget tracking.

## Step 0.5: Pre-Review Backup

Before any modifications to plan files:
1. Create backup directory: `docs/plans/{date}-{name}/.codex-backup/{ISO-timestamp}/`
   (or alongside the spec file if standalone)
2. Copy each plan file that may be modified into the backup directory
3. Display: "Backup created at .codex-backup/{timestamp}/"

To restore: copy files from `.codex-backup/{timestamp}/` back to the plan folder.
The most recent backup is always the pre-review state.

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
  model: `/deepgrade:codex-challenge {name} --model gpt-5.4`"
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
</workflow>

<guardrails>
## Safety and Error Handling

- **Codex timeout**: 120 seconds per call. If timeout, end that round gracefully
  and proceed to report. Do not retry the same call.
- **Max rounds**: Hard cap at 5 (user can set lower via --rounds). Default is 3.
- **Prompt size**: Cap plan content at 12,000 characters. Truncate with note if exceeded.
- **Codex availability**: Check once at start. If not installed, abort with
  install instructions.
- **Empty response**: Log warning, end loop, write partial report.
- **Parse failure**: Fail closed — show raw output, do NOT continue silently.
- **Time budget**: 15-minute hard ceiling across all rounds. Budget checkpoint
  at start of each round after Round 1.
- **Plan modifications**: Only modify plan/spec documents during AGREE responses.
  Never modify source code. Use Edit tool for surgical changes.
- **Temp file cleanup**: Always delete temp files after each Codex call.
- **File mtime audit**: Record plan file mtimes before each Codex call and verify
  they are unchanged after Codex returns.
- **Codex isolation**: Run Codex from os.tmpdir() as working directory, not the
  project directory. Codex receives plan content via the prompt only.

## Security Posture

Codex CLI v0.116.0+ defaults to **read-only sandbox** when using `codex exec`
without explicit sandbox flags. Write attempts are blocked by policy. This was
verified by live behavioral test (write attempt rejected as "blocked by policy").

Security layers:
1. **Read-only sandbox** — Codex cannot write files (default `codex exec` behavior)
2. **Ephemeral sessions** — `--ephemeral` prevents session persistence
3. **Isolated working directory** — Codex runs from os.tmpdir(), not project root
4. **Schema-validated output** — `--output-schema` constrains response shape
5. **File mtime audit** — detects unexpected modifications to plan files
6. **No `--dangerously-bypass-approvals-and-sandbox`** — not needed for review tasks
</guardrails>

<constraints>
- Do NOT modify source code. Only plan/spec documents.
- Do NOT blindly agree with Codex. Evaluate each gap against THIS codebase.
- Do NOT blindly disagree with Codex. If the gap is valid, say so.
- Do NOT invoke Codex more times than --rounds permits.
- Do NOT send secrets, API keys, or credentials in the Codex prompt.
- Do NOT silently continue when Codex output cannot be parsed (fail-closed).
- Keep individual Codex prompts under 15,000 characters total.
- If the plan has not been through Phase 5 (Audit), suggest:
  "This plan hasn't been audited yet. For best results, run
  /deepgrade:quick-audit first, then /deepgrade:codex-challenge."
</constraints>

<valid_commands>
/deepgrade:plan, /deepgrade:plan-status, /deepgrade:codex-challenge, /deepgrade:troubleshoot,
/deepgrade:quick-plan, /deepgrade:quick-audit, /deepgrade:quick-cleanup, /deepgrade:doc,
/deepgrade:readiness-scan, /deepgrade:readiness-generate, /deepgrade:codebase-audit,
/deepgrade:codebase-security, /deepgrade:codebase-delta, /deepgrade:codebase-gates,
/deepgrade:codebase-characterize, /deepgrade:help
</valid_commands>
