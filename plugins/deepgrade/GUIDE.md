<div align="center">

# DeepGrade Knowledge Guide v7.0.0

**9 Commands** &nbsp;&bull;&nbsp; **2 Agents** &nbsp;&bull;&nbsp; **3 Skills** &nbsp;&bull;&nbsp; **3 Safety Hooks** &nbsp;&bull;&nbsp; **Requires Node.js 18+**

[![Plugin](https://img.shields.io/badge/Claude_Code-Plugin-5A45FF?style=for-the-badge)](https://github.com/krwhynot/deepgrade)
[![Version](https://img.shields.io/badge/v7.0.0-stable-2ECC71?style=for-the-badge)](#)
[![Stack](https://img.shields.io/badge/Stack-Agnostic-F39C12?style=for-the-badge)](#)

</div>

> A reference for the deepgrade planning plugin: structured planning with an adversarial audit gate, plan-linked troubleshooting, and documentation generation.

DeepGrade's planning core walks an idea through nine phases from brainstorm to
handoff, with an adversarial audit gate in the middle: a fresh, isolated
plan-auditor judges every plan against falsifiable criteria, its evidence is
re-validated byte-for-byte by `scripts/dg-evidence-validate.js`, and a seeded
canary defect (`scripts/dg-canary.js`) proves the audit can actually see
defects before its verdict counts. The gate passes on verified evidence, never
on a self-assigned score.

It is one of four DeepGrade plugins. `deepgrade-readiness` grades AI
navigability, `deepgrade-audit` runs codebase audits, and `deepgrade-guard`
carries the always-on git/migration/tracking rails — install any subset. The
methodology reference lives in the monorepo's
[METHODOLOGY.md](https://github.com/krwhynot/deepgrade/blob/main/METHODOLOGY.md).

## Commands at a Glance

### `/deepgrade:help`
**What it does:** Shows all commands, agents, workflows, and output locations in one reference page.
**When to use it:** First time using DeepGrade, or when you forget a command name.
**What it produces:** Conversation output (no files).
**Example:**
```
/deepgrade:help
```

---


### ![planning](https://img.shields.io/badge/Planning-9B59B6?style=for-the-badge)

---

### `/deepgrade:plan`
**What it does:** Walks you through a 9-phase guided planning workflow: Brainstorm, Research, Pre-Plan, Plan, Audit, Build, Impact Review, Test, and Handoff.
**When to use it:** For any significant initiative -- migrations, new features, refactoring projects. This is the full workflow.
**What it produces:** `docs/plans/YYYY-MM-DD-{name}/` folder with manifest, status, brainstorm, approach, research, audit, specs, and more.
**Example:**
```
/deepgrade:plan worldpay-canada
/deepgrade:plan pricing-engine from docs/vendor-specs/
```

---

### `/deepgrade:quick-plan`
**What it does:** One-shot plan generation from a vague objective. Analyzes the codebase and produces a phased technical plan targeting 32+/40 on audit dimensions.
**When to use it:** For smaller changes where the full 9-phase workflow is overkill.
**What it produces:** `docs/specs/{plan-name}.md`
**Example:**
```
/deepgrade:quick-plan Extract pricing logic from Order.vb
```

---

### `/deepgrade:plan-status`
**What it does:** Shows progress of all active plans or detailed phase-by-phase status of one plan, including staleness checks.
**When to use it:** To check where a plan stands, or to see all plans at a glance.
**What it produces:** Conversation output (no files).
**Example:**
```
/deepgrade:plan-status
/deepgrade:plan-status worldpay-canada
```

---

### `/deepgrade:plan-export`
**What it does:** Packages a plan into a self-contained zip that another developer can use with vanilla Claude Code (no plugin required). Redacts secrets, includes a bootstrapping CLAUDE.md, and adds codebase verification checks.
**When to use it:** When handing off a plan to someone else.
**What it produces:** `{plan-name}-export.zip` at project root.
**Example:**
```
/deepgrade:plan-export worldpay-canada
```

---


### `/deepgrade:quick-audit`
**What it does:** Audits a technical plan, spec, or proposal across 8 dimensions (problem clarity, architecture, phasing, risk, rollback, timeline, testing, team). Produces a go/no-go recommendation.
**When to use it:** Before presenting a plan to stakeholders, or to stress-test any proposal.
**What it produces:** `docs/plans/{date}-{name}/audit.md` (if plan-linked) or conversation output.
**Example:**
```
/deepgrade:quick-audit docs/specs/pricing-engine-extraction.md
```

---


### `/deepgrade:codex-challenge`
**What it does:** Runs an adversarial review loop between Claude and the OpenAI Codex CLI: Codex scores a plan across 8 dimensions and Claude revises until the score converges.
**When to use it:** When you want a second, independent model attacking a plan before you commit to it.
**What it produces:** A scored review transcript in the plan folder.
**Example:**
```
/deepgrade:codex-challenge my-plan
```

### ![docs](https://img.shields.io/badge/Documentation_&_Troubleshooting-1ABC9C?style=for-the-badge)

---

### `/deepgrade:documentation`
**What it does:** Routes to 6 document templates (ADR, BRD, PRD, README, Release Notes, Spec). If audit data exists, documents are richer and auto-linked.
**When to use it:** Whenever you need to create a project document. If unsure which type, just describe what you need.
**What it produces:** Files in `docs/adr/`, `docs/brd/`, `docs/prd/`, `docs/specs/`, or project root (README).
**Example:**
```
/deepgrade:documentation adr credential rotation
/deepgrade:documentation spec pricing engine extraction
/deepgrade:documentation release-notes v2.5.0
```

---

### `/deepgrade:quick-cleanup`
**What it does:** Cleans up a folder of messy documents (PDFs, vendor manuals, meeting notes, legacy docs) into structured markdown and JSON reference files.
**When to use it:** At the start of a plan when you have raw input material, or standalone for document organization.
**What it produces:** `docs/plans/{date}-{name}/research/intake/` with summary, reference data, source index, and setup checklist.
**Example:**
```
/deepgrade:quick-cleanup ./vendor-docs worldpay-canada
```

---

### `/deepgrade:troubleshoot`
**What it does:** Implements a strict 4-phase debugging framework (Root Cause, Pattern Analysis, Hypothesis, Fix) with severity-driven incident triage and optional containment for production fires. Enforces investigation before any permanent fix. For SEV1/SEV2 incidents, temporary containment (rollback, feature flag, config revert) is allowed before investigation to restore service. Builds a persistent knowledge base with guardrail evaluation and timestamped investigation timelines.
**When to use it:** When something breaks and you want a systematic approach instead of guessing, or when a production incident needs triage and containment before debugging.
**What it produces:** `docs/troubleshooting/YYYY-MM-DD-{issue-slug}.md` + updates to `docs/troubleshooting/knowledge-base.md`
**Example:**
```
/deepgrade:troubleshoot "Payment processing returns null on Canadian cards"
/deepgrade:troubleshoot login timeout --plan worldpay-canada
/deepgrade:troubleshoot "checkout is down for all users" --severity SEV1
```

---


## The 2 Agents

| | Agent | What It Does | Used By |
|:-:|-------|-------------|---------|
| ![p](https://img.shields.io/badge/-%E2%80%8B-9B59B6) | plan-scaffolder | Creates structured technical plans from vague objectives using 3 parallel analysts | quick-plan, plan |
| ![p](https://img.shields.io/badge/-%E2%80%8B-9B59B6) | plan-auditor | Scores plans across 8 dimensions using parallel specialist subagents | quick-audit, plan |

## The 3 Skills

Skills are persistent knowledge that loads automatically when relevant — reference books the plugin carries in its back pocket.

**documentation** -- The dispatch hub for document generation. Contains routing logic (first word = subcommand), 6 template references, smart suggestions when audit data exists, and document chain enforcement (a PRD triggers a check for a related BRD, etc.). Loads when you ask for a document, or invoke `/deepgrade:documentation` directly.


**self-audit-knowledge** -- Contains the LLM epistemic transparency framework: claim verification tiers (A = tool-verified, B = code-reading, C = pattern inference), evidence basis formatting, failure mode flags (`[ENUMERATION-MAY-BE-INCOMPLETE]`, `[INFERRED-FROM-NAMING]`, `[SIDE-EFFECTS-NOT-TRACED]`, `[DEAD-CODE-UNCERTAIN]`), category-based cascade risk classification (CASCADE/COVERAGE/CONTAINED), and report confidence thresholds. Loads during codebase audits, plan audits, and report generation.

**mcp-research** -- Teaches when and how to use external MCP search tools (Ref, Exa, Perplexity) for documentation lookup and research: tool selection heuristics, token budget rules, suffix-matching for server-qualified tool names, and graceful degradation when a tool is absent. Loads during plan research phases.

### The 6 Document Templates


| Template | What It Produces | Location |
|----------|-----------------|----------|
| `adr-template.md` | Architecture Decision Record -- captures a technical decision, alternatives considered, and rationale | `docs/adr/` |
| `brd-template.md` | Business Requirements Document -- domain-level requirements tied to business outcomes | `docs/brd/` |
| `prd-template.md` | Product Requirements Document -- feature-level spec with acceptance criteria | `docs/prd/` |
| `readme-template.md` | Project README -- setup, architecture overview, contribution guide | Project root |
| `release-notes-template.md` | Release Notes / Changelog -- what changed, why, and how to upgrade | `docs/` or project root |
| `spec-template.md` | Technical Specification -- extraction plans, migration plans, RFCs, design docs | `docs/specs/` |

> [!IMPORTANT]
> When a Phase 2 audit has been run, templates automatically pull from audit data. For example, a PRD template pulls feature confidence scores from `feature-inventory.md`, and a spec template pulls risk levels from `risk-assessment.md`. Documents generated **after** an audit are richer than documents generated from scratch.

---


## The 3 Hooks

The plan-context hooks keep a session anchored to the active plan. They are
declared in `hooks/hooks.json` and run as Node scripts from `scripts/`
(**requires Node.js 18+**, the same runtime Claude Code itself needs). The
git, migration, and tracking rails are the `deepgrade-guard` plugin.

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Active Plan Display (SessionStart Hook)
**Fires when:** A session starts in a repo with an active plan under `docs/plans/`.
**What it does:** Reports the active plan, its phase and status, and nudges when a linked audit has gone stale (the staleness check is if-exists: it works with or without the audit plugin installed).

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Subagent Log (SubagentStop Hook)
**Fires when:** A subagent completes while a plan is active.
**What it does:** Appends the completion to the active plan's troubleshooting log, so multi-agent work leaves a trace in the plan record.

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Plan Context (PreCompact Hook)
**Fires when:** Claude Code's context window is getting full and it needs to compress earlier messages.
**What it does:** Injects the active plan name and current phase into the compressed context so Claude doesn't lose track of what you're working on.
**Why:** Without this, Claude might forget which plan you were on after a compaction. The hook ensures continuity.

> [!TIP]
> `[DeepGrade] Compacting. Plan: worldpay-canada. Resume with /deepgrade:plan worldpay-canada`


---

## How to Install

```bash
claude plugin marketplace add krwhynot/deepgrade
claude plugin install deepgrade@deepgrade-marketplace --scope user
```

User scope (recommended) makes the plugin available in every project; use
`--scope project` to limit it to one. Verify with:

```
/deepgrade:help
```

## How to Update

An installed plugin lives in a **versioned cache directory**, and third-party marketplace auto-update
is **off by default**. Pulling the repository does not update an installed copy — you must refresh the
marketplace and update the plugin explicitly:

```
/plugin marketplace update deepgrade-marketplace
/plugin update deepgrade
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
> claude --plugin-dir /path/to/deepgrade/plugins/deepgrade
> ```
> Use this for plugin development. For an installed plugin, use the four-command sequence above.
