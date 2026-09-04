<div align="center">

# Toque Knowledge Guide v11.0.0

**6 Commands** &nbsp;&bull;&nbsp; **2 Agents** &nbsp;&bull;&nbsp; **5 Skills** &nbsp;&bull;&nbsp; **7 Document Templates** &nbsp;&bull;&nbsp; **3 Plan-Context Hooks** &nbsp;&bull;&nbsp; **2 Gate Tools** &nbsp;&bull;&nbsp; **Requires Node.js 18+**

[![Plugin](https://img.shields.io/badge/Claude_Code-Plugin-5A45FF?style=for-the-badge)](https://github.com/krwhynot/toque)
[![Version](https://img.shields.io/badge/v11.0.0-stable-2ECC71?style=for-the-badge)](#)
[![Stack](https://img.shields.io/badge/Stack-Agnostic-F39C12?style=for-the-badge)](#)

</div>

> A reference for the toque planning plugin: six-stage planning with a verifier-first design gate, plan-linked troubleshooting, and documentation generation.

Toque's planning core walks an idea through the six stages of Anthropic's
AI-Native SDLC playbook, Plan, Design, Build, Test, Deploy, Maintain, each
committing one artifact the next stage reads. The Design stage ends in an
adversarial gate: a fresh, isolated plan-auditor judges the spec against
falsifiable criteria, its evidence is re-validated byte-for-byte by
`scripts/tq-evidence-validate.js`, and a seeded canary defect from
`scripts/tq-canary.js` proves the audit can actually see defects before its
verdict counts. The gate passes on verified evidence, never on a self-assigned
score. See [The Design Gate](#the-design-gate) below.

Toque is the only plugin in this repository. Codebase auditing and AI-readiness
scanning were removed in 11.0.0. Toque still reads analysis files left in
`docs/audit/` and works without them. The methodology reference lives in the
repository's
[METHODOLOGY.md](https://github.com/krwhynot/toque/blob/main/METHODOLOGY.md).

## Contents

- [Commands at a Glance](#commands-at-a-glance)
- [The Six Stages](#the-six-stages)
- [The Design Gate](#the-design-gate)
- [The 2 Agents](#the-2-agents)
- [The 5 Skills](#the-5-skills)
- [The 7 Document Templates](#the-7-document-templates)
- [The 3 Hooks](#the-3-hooks)
- [The Scripts](#the-scripts)
- [Where Files Land](#where-files-land)
- [How to Install](#how-to-install)
- [How to Update](#how-to-update)

## Commands at a Glance

Nine entry points. Three are skills (`plan`, `troubleshoot`, `documentation`)
that also answer to natural-language triggers; six are command files under
`commands/`.

### `/toque:help`
**What it does:** Shows all commands, agents, workflows, and output locations in one reference page.
**When to use it:** First time using Toque, or when you forget a command name.
**What it produces:** Conversation output (no files).
**Example:**
```
/toque:help
```

---

### ![planning](https://img.shields.io/badge/Planning-9B59B6?style=for-the-badge)

---

### `/toque:plan`
**What it does:** Walks you through the six-stage playbook: Plan (intent.md), Design (spec.md plus the design gate), Build (plan.md, code, impact review), Test, Deploy (review.md, release authorization), Maintain (incidents become new intents). `intent {name}` captures intent only and stops. Every stage ends at a human gate; nothing advances on its own.
**When to use it:** For any significant initiative -- migrations, new features, refactoring projects. This is the full workflow.
**What it produces:** `docs/plans/YYYY-MM-DD-{name}/` with manifest, status, intent.md, research, spec.md, audit.md, evidence, plan.md, impact-review.md, test-plan.md, review.md, and optionally runbook.md.
**Example:**
```
/toque:plan worldpay-canada
/toque:plan intent worldpay-canada
/toque:plan pricing-engine from docs/vendor-specs/
```

---

### `/toque:quick-plan`
**What it does:** One-shot plan generation from a vague objective. Analyzes the codebase and produces a phased technical plan covering the plan-auditor's eight review dimensions. It reports findings per dimension, not a total, and gates nothing.
**When to use it:** For smaller changes where the full six-stage workflow is overkill.
**What it produces:** `docs/specs/{plan-name}.md`
**Example:**
```
/toque:quick-plan Extract pricing logic from Order.vb
```

---

### `/toque:plan-status`
**What it does:** Shows progress of all active plans or detailed stage-by-stage status of one plan, including staleness checks.
**When to use it:** To check where a plan stands, or to see all plans at a glance.
**What it produces:** Conversation output (no files).
**Example:**
```
/toque:plan-status
/toque:plan-status worldpay-canada
```

---

### `/toque:plan-export`
**What it does:** Packages a plan into a self-contained zip that another developer can use with vanilla Claude Code (no plugin required). Redacts secrets, includes a bootstrapping CLAUDE.md, and adds codebase verification checks.
**When to use it:** When handing off a plan to someone else.
**What it produces:** `{plan-name}-export.zip` at project root.
**Example:**
```
/toque:plan-export worldpay-canada
```

---

### `/toque:quick-audit`
**What it does:** Audits a technical plan, spec, or proposal through the plan-auditor's eight review dimensions (problem clarity, architecture, phasing, risk, rollback, timeline, testing, team). Produces evidence-backed findings, a go/no-go recommendation, and a leadership summary. The verdict rests on the findings and their evidence; there is no score.
**When to use it:** Before presenting a plan to stakeholders, or to stress-test any proposal outside the full workflow.
**What it produces:** `docs/plans/{date}-{name}/audit.md` (if plan-linked) or conversation output.
**Example:**
```
/toque:quick-audit docs/specs/pricing-engine-extraction.md
```


### ![docs](https://img.shields.io/badge/Documentation_&_Troubleshooting-1ABC9C?style=for-the-badge)

---

### `/toque:documentation`
**What it does:** Routes to 7 document templates (ADR, BRD, PRD, README, Runbook, Release Notes, Spec). Each template carries a fill-in document skeleton, so the output has a fixed shape. If audit data exists, documents are richer and auto-linked, and a document-chain check suggests the missing neighbor (a PRD asks for its BRD, a runbook asks to be linked from review.md).
**When to use it:** Whenever you need to create a project document. If unsure which type, just describe what you need.
**What it produces:** Files in `docs/adr/`, `docs/brd/`, `docs/prd/`, `docs/runbooks/`, `docs/specs/`, or project root (README). A plan-linked runbook lands in the plan folder.
**Example:**
```
/toque:documentation adr credential rotation
/toque:documentation prd refund processing
/toque:documentation runbook worldpay-canada
/toque:documentation release-notes v2.5.0
```

---

### `/toque:quick-cleanup`
**What it does:** Cleans up a folder of messy documents (PDFs, vendor manuals, meeting notes, legacy docs) into structured markdown and JSON reference files.
**When to use it:** At the start of a plan when you have raw input material, or standalone for document organization.
**What it produces:** `docs/plans/{date}-{name}/research/intake/` with summary, reference data, source index, and setup checklist.
**Example:**
```
/toque:quick-cleanup ./vendor-docs worldpay-canada
```

---

### `/toque:troubleshoot`
**What it does:** Implements a strict 4-phase debugging framework (Root Cause, Pattern Analysis, Hypothesis, Fix) with severity-driven incident triage. For SEV1/SEV2, a containment gate allows a temporary mitigation (rollback, feature flag, config revert) before investigation, then a status-update cadence keeps people outside the investigation informed. Every run writes a timestamped log and a knowledge-base entry; SEV1/SEV2 runs also write a blameless postmortem and, when plan-linked, propose a new intent that re-enters Stage 1.
**When to use it:** When something breaks and you want a systematic approach instead of guessing, or when a production incident needs triage and containment before debugging.
**What it produces:** `docs/troubleshooting/YYYY-MM-DD-{issue-slug}.md`, updates to `docs/troubleshooting/knowledge-base.md`, and for SEV1/SEV2 a `-postmortem.md` beside the log. Plan-linked runs write under the plan's `troubleshooting/` folder instead.
**Example:**
```
/toque:troubleshoot "Payment processing returns null on Canadian cards"
/toque:troubleshoot login timeout --plan worldpay-canada
/toque:troubleshoot "checkout is down for all users" --severity SEV1
```

---

## The Six Stages

`/toque:plan` runs Anthropic's AI-Native SDLC loop. Each stage reads the
artifact the previous one committed and leaves one behind. The chain of
artifacts is the audit trail.

| Stage | Question it answers | Reads | Commits | Human gate |
|-------|--------------------|-------|---------|------------|
| 1. Plan | What are we trying to change, for whom, and why? | Any input: idea, ticket, docs folder, incident | `intent.md` | Intent accepted |
| 2. Design | What exactly will be built, and does it survive scrutiny? | `intent.md`, research | `spec.md`, `audit.md`, `evidence/` | Scope lock mid-stage, then the design gate passes |
| 3. Build | What files change, in what order, and what did we actually do? | `spec.md` | `plan.md`, code, `impact-review.md`, change records | Codebase writes approved |
| 4. Test | Does it do what the spec says, measured the way the spec said? | `spec.md` verification plan | `test-plan.md`, test results | Runbook reviewed by someone other than the author |
| 5. Deploy | Is the diff what was planned, and is it safe to release? | `plan.md`, the diff | `review.md` with a release checklist | Release authorization. The agent never crosses the production gate. |
| 6. Maintain | What did production teach us? | Troubleshoot logs, postmortems | A new `intent.md` proposed for Stage 1 | Intent accepted or declined |

Spec requirements carry a priority (P0/P1/P2), trace to a line of intent.md,
and have Given/When/Then acceptance criteria. Success metrics have a numeric
target, a window, and a measurement method. Review.md's release checklist has
pre-deploy, deploy, post-deploy, and rollback sections with numeric rollback
triggers, and Stage 6 uses those thresholds to classify severity.

## The Design Gate

Stage 2 ends in an audit. Version 8 removed the numeric score from that audit
because a gate that passes on a number the audited model chose for itself lets
no reader tell a plan that earned it from one written to earn it. What replaced
it is a set of checks a person can re-derive from the plan folder without
re-running anything.

**The auditor** is `agents/plan-auditor.md`, spawned fresh for every iteration
with a `<forbidden_inputs>` block: it never reads a previous iteration's
verdicts. It returns criterion records, each with a verdict (MET, UNMET, N_A)
and the evidence it rests on: file, content hash, line range, verbatim quote.
The rubric it applies lives in `docs/planning-techniques/lint-registry.md`,
the single enforced source of rule text.

**The canary** (`scripts/tq-canary.js`) checks the auditor rather than the
plan. Before the auditor is spawned, one known defect is injected into a
working copy of the spec under `.canary/`. Five classes rotate by seed:

| Class | What it does | Criterion it violates |
|-------|-------------|----------------------|
| `rollback-strip` | Removes the rollback line from one deployment phase | LINT-03 |
| `owner-strip` | Blanks the owner of one external dependency | LINT-04 |
| `assumption-inject` | Adds an unverified HIGH-impact assumption | LINT-08 |
| `criteria-strip` | Deletes the go/no-go criteria | LINT-10 |
| `test-claim-inject` | Claims coverage from a test file that does not exist | LINT-15 |

The auditor audits the mutated copy without being told. If the planted
criterion does not come back UNMET, the audit is re-run once with a different
class. A second miss fails the gate as "audit untrustworthy" and does not
trigger the revision loop, because revising a plan against findings from an
audit that could not see a planted defect rewrites the spec to satisfy
conclusions never derived from reading it. If the canary is found, that one
finding is stripped as a harness artifact and the same criterion is re-checked
against the unmutated original, so a genuine gap on the same rule is not
stripped with it.

**The evidence validator** (`scripts/tq-evidence-validate.js`) treats the
auditor's records as a proposal. It re-reads every cited artifact, confirms the
LF-normalized hash still matches, slices the cited line range, and asserts the
quote is byte-identical. It can only demote. A record comes back UNMET with one
of these flags:

| Flag | Meaning |
|------|---------|
| `EVIDENCE-INVALID` | The quote does not match the lines it cites |
| `EVIDENCE-MISSING` | MET was claimed with no evidence at all |
| `EVIDENCE-STALE` | The artifact changed after the record was written |
| `EVIDENCE-UNPINNED` | The citation carries no `sha256`, so staleness cannot be detected |
| `EVIDENCE-ARTIFACT-MISSING` | The cited file does not exist |
| `EVIDENCE-PATH-ESCAPE` | The citation is absolute, or resolves outside the audited tree |
| `EVIDENCE-RANGE-INVALID` | The cited line range does not exist in the file |
| `EVIDENCE-QUOTE-EMPTY` | The quote is empty or whitespace, so it evidences nothing |
| `EVIDENCE-UNSUPPORTED` | An executable criterion has no citation that survived re-checking |
| `EVIDENCE-VERDICT-INVALID` | The verdict is not one of MET, UNMET, N_A. A file that parses as JSON but is not a record object — `null`, a number, a string, an array — lands here too: it has no verdict to read |
| `EVIDENCE-UNPARSEABLE` | The record file is not valid JSON |

One flag is **advisory**: it is reported and changes nothing.

| Flag | Meaning |
|------|---------|
| `EVIDENCE-EXITCODE-IGNORED` | The record supplied an `exit_code`; it carried no weight |

`exit_code` is ignored because the record's author wrote it. A number you supply
about your own work is not evidence, and the validator will not run a
model-authored command string to check it. An executable criterion is settled by
a citation that survives re-checking instead.

Which criteria are executable is fixed in the validator, not declared by the
record, so the judge cannot relabel a run-it check as a read-it check and
satisfy it with a quote.

**The gate expression** is the whole verdict:

```
CANARY_OK   = the criterion the planted defect violates came back UNMET
EVIDENCE_OK = tq-evidence-validate.js exited 0 (nothing was flagged)
VERIFIED    = every applicable criterion is MET or N_A after validation
INFRA_OK    = infra_gaps == 0

PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

There is no weighted sum. A strong showing on seven criteria cannot offset a
miss on the eighth.

**The holistic judge** runs beside the rubric and never gates. Its unmapped
findings land in `docs/planning-techniques/lint-candidates.md` as proposed
rules. It is the only mechanism that can notice the rubric itself is
incomplete.

> [!WARNING]
> **Known limitations, stated rather than glossed.** The auditor holds Read,
> Grep, and Glob over the repository and can reach the criterion files and the
> canary's defect table. Isolation is enforced by instruction, not capability.
> The canary reliably detects a lazy audit and only incidentally an adversarial
> one. And nothing in this release measures whether the judge is *right*, only
> whether it is evidenced. Calibration against known-good and known-bad plans
> is the natural successor.

## The 2 Agents

| | Agent | What It Does | Used By |
|:-:|-------|-------------|---------|
| ![p](https://img.shields.io/badge/-%E2%80%8B-9B59B6) | plan-scaffolder | Creates structured technical plans from vague objectives using 3 parallel analysts | quick-plan, plan |
| ![p](https://img.shields.io/badge/-%E2%80%8B-9B59B6) | plan-auditor | The isolated judge. Reviews a plan through 8 dimensions with parallel specialist subagents and returns criterion records with evidence, never a gating score | quick-audit, plan (design gate) |

Both agents load the `self-audit-knowledge` skill so every claim carries a
verification tier and, where relevant, a failure-mode flag.

## The 5 Skills

Skills are persistent knowledge that loads automatically when relevant — reference books the plugin carries in its back pocket.

**plan** -- The `/toque:plan` workflow itself. `SKILL.md` is a router (identity, lifecycle, workspace layout, Step 0 intent detection and schema migration) and each of the six stages lives in its own file under `stages/`, with artifact templates for intent.md, spec.md, plan.md, and review.md under `templates/`, read when the stage is entered. Split this way so the later stages survive context compaction in long planning sessions instead of being silently dropped with the rest of a 1,700-line command.

**troubleshoot** -- The `/toque:troubleshoot` workflow: a router holding identity, timeline logging, plan detection, and Step 0 knowledge-base lookup, with the incident pre-flow (triage, containment gate, status updates), the four phases, multi-agent mode, and the knowledge-base write-back with postmortem in one file each under `phases/`, read on entry.

**documentation** -- The dispatch hub for document generation. Contains routing logic (first word = subcommand), 7 template references each with a fill-in skeleton, smart suggestions when audit data exists, and document chain enforcement (a PRD triggers a check for a related BRD, a runbook checks it is linked from review.md). Loads when you ask for a document, or invoke `/toque:documentation` directly.

**self-audit-knowledge** -- Contains the LLM epistemic transparency framework: claim verification tiers (A = tool-verified, B = code-reading, C = pattern inference), evidence basis formatting, failure mode flags (`[ENUMERATION-MAY-BE-INCOMPLETE]`, `[INFERRED-FROM-NAMING]`, `[SIDE-EFFECTS-NOT-TRACED]`, `[DEAD-CODE-UNCERTAIN]`), category-based cascade risk classification (CASCADE/COVERAGE/CONTAINED), and report confidence thresholds. Loads during codebase audits, plan audits, and report generation.

**mcp-research** -- Teaches when and how to use external MCP search tools (Ref, Exa, Perplexity) for documentation lookup and research: tool selection heuristics, token budget rules, suffix-matching for server-qualified tool names, and graceful degradation when a tool is absent. Loads during plan research phases. Every template and stage works without these tools.

### The 7 Document Templates

Each template under `skills/documentation/references/` has two parts: the
workflow (disambiguate the topic, pull audit data if present, confirm scope)
and a fill-in document skeleton the output must follow.

| Template | What It Produces | Location |
|----------|-----------------|----------|
| `adr-template.md` | Architecture Decision Record -- context, decision, two or more options assessed on a dimension table, trade-offs, consequences, action items | `docs/adr/` |
| `brd-template.md` | Business Requirements Document -- business context, objectives, stakeholders, BR-NNN requirements mapped to PRDs, feature coverage, metrics, risks | `docs/brd/` |
| `prd-template.md` | Product Requirements Document -- problem, goals, non-goals, user stories, P0/P1/P2 requirements with Given/When/Then acceptance criteria, leading and lagging success metrics | `docs/prd/{domain}/` |
| `readme-template.md` | Project README -- purpose, quick start, structure, dependencies, integrations, configuration, testing, known risks, related docs | Project root |
| `runbook-template.md` | Operational Runbook -- prerequisites, exact steps each with expected result and failure action, verification, troubleshooting table, rollback trigger and steps, escalation, run history | `docs/runbooks/` or the plan folder |
| `release-notes-template.md` | Release Notes / Changelog -- what changed, why, and how to upgrade, from git history | `docs/` or project root |
| `spec-template.md` | Technical Specification -- extraction, migration, feature, or infrastructure plans with phases, validation, risk, rollback, and success criteria | `docs/specs/` |

> [!IMPORTANT]
> When an audit baseline exists in `docs/audit/`, templates pull from it automatically. A PRD pulls feature confidence scores and entry points from `feature-inventory.json`, an ADR pulls related findings from `risk-assessment.json`, a README pulls dependencies from `dependency-map.json`. Documents generated **after** an audit are richer than documents generated from scratch. Everything below 0.90 confidence is tagged `[ASSUMPTION]` rather than stated as fact.

---

## The 3 Hooks

The plan-context hooks keep a session anchored to the active plan. They are
declared in `hooks/hooks.json` and run as Node scripts from `scripts/`, one
file per handler (**requires Node.js 18+**, the same runtime Claude Code
itself needs). All three are informational: they fail open and always exit 0.
There are no blocking hooks in any Toque plugin; force-push, migration, and
database-deploy protection belongs in Claude Code permission rules (`deny` and
`ask` entries in `settings.json`), which need no runtime and cannot disagree
with a project's own choices.

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Active Plan Display (SessionStart Hook)
**Script:** `scripts/tq-session-start.js`
**Fires when:** A session starts, resumes, or continues after a compaction in a repo with an active plan under `docs/plans/`.
**What it does:** Parses the newest plan's `status.json` and reports the active plan, its phase and that phase's status. The stale-audit nudge was removed in 11.0.0: it stat-ed a report this plugin does not produce, which made a session message depend on another tool having run in the same repository. It parses JSON rather than grepping it, which is what fixed two old bugs where pretty-printed files read as "phase: unknown" and a nested phase status was reported as the plan's status.

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Subagent Log (SubagentStop Hook)
**Script:** `scripts/tq-subagent-stop.js`
**Fires when:** A subagent completes while a plan is active.
**What it does:** Appends the completion to `troubleshooting/subagent-log.txt` in the active plan, so multi-agent work leaves a trace in the plan record. It only writes if that folder already exists; a stop hook silently creating directories in someone's repo would be a surprise.

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Plan Context (PreCompact Hook)
**Script:** `scripts/tq-pre-compact.js`
**Fires when:** Claude Code's context window is getting full and it needs to compress earlier messages.
**What it does:** Emits the active plan name and current stage as JSON so Claude doesn't lose track of what you're working on. If this channel proves invisible in a given Claude Code build, the SessionStart handler's compact-resume path carries the same message, so this handler is not the only carrier.

> [!TIP]
> `[Toque] Compacting. Active plan: worldpay-canada at phase: design. Resume with /toque:plan worldpay-canada`

## The Scripts

`scripts/` holds five Node files. Three are the hook handlers above. Two are
the design-gate tools, which are not hooks: Stage 2 of `/toque:plan` runs
them explicitly, and you can run them by hand.

| Script | Role | Invoked by | Usage |
|--------|------|-----------|-------|
| `tq-session-start.js` | Hook handler | SessionStart event | automatic |
| `tq-subagent-stop.js` | Hook handler | SubagentStop event | automatic |
| `tq-pre-compact.js` | Hook handler | PreCompact event | automatic |
| `tq-canary.js` | Gate tool: checks the auditor | Stage 2, before the auditor is spawned | `node tq-canary.js inject <spec-path> <out-dir> [seed]` |
| `tq-evidence-validate.js` | Gate tool: checks the evidence | Stage 2, before any verdict is treated as MET | `node tq-evidence-validate.js <evidence-dir> [root-dir]` |

Both gate tools have regression suites in the monorepo's `tests/` folder
(layers 5 and 6 of `tests/run-all.sh`).

**What happens without Node.** The hooks cannot start, and Claude Code reports
a hook error on each guarded event. That is deliberate: absent and loud beats
present and wrong. The gate tools fail the same way, and Stage 2 cannot pass
without them.

## Where Files Land

| Output | Location | Committed? |
|--------|----------|-----------|
| Plan workspace | `docs/plans/{date}-{name}/` (manifest.md, status.json, intent.md, spec.md, plan.md, review.md, ...) | Yes |
| Plan research and intake | `docs/plans/{date}-{name}/research/` | Yes |
| Audit report | `docs/plans/{date}-{name}/audit.md` | Yes |
| Audit evidence records | `docs/plans/{date}-{name}/evidence/` | Yes |
| Canary working copy | `docs/plans/{date}-{name}/.canary/` | No, scratch |
| Change records | `docs/plans/{date}-{name}/changes/` | Yes |
| Plan-linked troubleshooting logs and postmortems | `docs/plans/{date}-{name}/troubleshooting/` | Yes |
| Plan-linked runbook | `docs/plans/{date}-{name}/runbook.md` | Yes |
| Standalone troubleshooting logs | `docs/troubleshooting/YYYY-MM-DD-{slug}.md` | Yes |
| Knowledge base | `docs/troubleshooting/knowledge-base.md` | Yes |
| Quick plans and specs | `docs/specs/` | Yes |
| ADRs, BRDs, PRDs | `docs/adr/`, `docs/brd/`, `docs/prd/{domain}/` | Yes |
| Standalone runbooks | `docs/runbooks/` | Yes |
| Proposed lint rules from the holistic judge | `docs/planning-techniques/lint-candidates.md` | Yes |
| Plan export | `{plan-name}-export.zip` at project root | No |

---

## How to Install

```bash
claude plugin marketplace add krwhynot/toque
claude plugin install toque@toque-marketplace --scope user
```

User scope (recommended) makes the plugin available in every project; use
`--scope project` to limit it to one. Verify with:

```
/toque:help
```

## How to Update

An installed plugin lives in a **versioned cache directory**, and third-party marketplace auto-update
is **off by default**. Pulling the repository does not update an installed copy — you must refresh the
marketplace and update the plugin explicitly:

```
/plugin marketplace update toque-marketplace
/plugin update toque
/reload-plugins
/plugin list
```

`/plugin list` is the verification step: confirm the version shown is the one you expect. **Without a
version bump in `plugin.json`, nothing propagates** — the version is the cache key.

> [!IMPORTANT]
> **Editing plugin files does not affect an installed copy.** The live-edit workflow — where changes
> take effect on the next session with no reinstall — applies **only** when you run Claude Code with
> `--plugin-dir`, pointing directly at your working tree:
> ```bash
> claude --plugin-dir /path/to/toque/plugins/toque
> ```
> Use this for plugin development. For an installed plugin, use the four-command sequence above.
