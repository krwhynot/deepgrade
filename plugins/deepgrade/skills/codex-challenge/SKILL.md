---
name: codex-challenge
description: Adversarial review loop between Claude and OpenAI Codex CLI. Codex scores your plan across 8 dimensions (max 40), Claude optimizes until score reaches 36/40 GREEN. Implements the Evaluator-Optimizer pattern with score-driven convergence. Pass a plan name, file path, or leave empty for auto-detect. Use when the user asks for a Codex review, an adversarial plan review, or to challenge a plan.
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

This command runs a multi-round score-driven optimization loop following the Evaluator-Optimizer pattern from
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

## Steps 1-6: load the phase file on entry

The round loop and the report live in one file each under `${CLAUDE_SKILL_DIR}/phases/`,
alongside the Codex output schema and the review prompt template. Skill content enters
the conversation once and is not re-read after auto-compaction, so a multi-round Codex
session can silently lose its later steps. Each phase file is read when its step is
entered, so its instructions are always the most recent thing in context.

RULE: On entering a step, READ the phase file with the Read tool BEFORE doing any work
in that step. Re-read it after any compaction. Read `output-schema.md` and
`prompt-template.md` the first time Step 1 needs them (they are referenced as
`<output_schema>` and `<codex_prompt_template>` throughout).

| Step | Phase | File |
|------|-------|------|
| 1 (schema) | Codex output schema | `${CLAUDE_SKILL_DIR}/phases/output-schema.md` |
| 1 (prompt) | Codex review prompt template | `${CLAUDE_SKILL_DIR}/phases/prompt-template.md` |
| 1-4 | Round loop: send, parse, respond, exit check | `${CLAUDE_SKILL_DIR}/phases/round-loop.md` |
| 5-6 | Write report and display summary | `${CLAUDE_SKILL_DIR}/phases/report.md` |

Paths use forward slashes on every platform. If a phase file cannot be read, stop
and report the path; do not improvise the step from memory.

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
/deepgrade:codex-challenge, /deepgrade:documentation, /deepgrade:help, /deepgrade:plan,
/deepgrade:plan-export, /deepgrade:plan-status, /deepgrade:quick-audit, /deepgrade:quick-cleanup,
/deepgrade:quick-plan, /deepgrade:troubleshoot, /deepgrade-audit:codebase-audit,
/deepgrade-audit:codebase-characterize, /deepgrade-audit:codebase-delta,
/deepgrade-audit:codebase-gates, /deepgrade-audit:codebase-security,
/deepgrade-readiness:readiness-generate, /deepgrade-readiness:readiness-scan
</valid_commands>
