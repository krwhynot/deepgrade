<div align="center">

# Toque Readiness Guide v9.0.0

**2 Commands** &nbsp;&bull;&nbsp; **10 Agents** &nbsp;&bull;&nbsp; **1 Skill**

[![Plugin](https://img.shields.io/badge/Claude_Code-Plugin-5A45FF?style=for-the-badge)](https://github.com/krwhynot/toque)
[![Version](https://img.shields.io/badge/v9.0.0-stable-2ECC71?style=for-the-badge)](#)
[![Stack](https://img.shields.io/badge/Stack-Agnostic-F39C12?style=for-the-badge)](#)

</div>

> A reference for the toque-readiness plugin: AI-readiness scanning with a composite letter grade.

Toque Readiness scores how well an AI coding agent can read, navigate, and
safely modify a codebase: 52 checks across 9 categories, rolled up into a
composite grade from A+ to F. Run it before deeper code-quality audits — a
codebase an agent cannot navigate cannot be audited well either. It is one of
four Toque plugins; `toque-audit` picks up where the readiness grade
leaves off.

## Commands

### `/toque-readiness:readiness-scan`
**What it does:** Deploys 9 scanner agents in parallel to grade how well AI can read and navigate your codebase across 52 checks.
**When to use it:** Before anything else -- this is always step one. Run it on any new project.
**What it produces:** `docs/audit/readability/readability-report.md` + 9 JSON scan files + `readability-score.json`
**Example:**
```
/toque-readiness:readiness-scan
```

---

### `/toque-readiness:readiness-generate`
**What it does:** Reads the latest scan results and generates missing artifacts (CLAUDE.md, commands, rules, agent definitions) to improve your score.
**When to use it:** After a readiness scan shows gaps. Pick specific items or generate all critical ones.
**What it produces:** Varies -- CLAUDE.md, `.claude/commands/*.md`, `.claude/rules/*.md`, `.mcp.json`, etc.
**Example:**
```
/toque-readiness:readiness-generate all-critical
```

---


## The 10 Agents

#### These agents examine your codebase and produce structured data.

| | Agent | What It Does | Used By |
|:-:|-------|-------------|---------|
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | manifest-scanner | Finds package manifests, detects language/framework, checks project identity | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | context-scanner | Evaluates CLAUDE.md quality, .claude/ directory, rules, commands, skills | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | structure-scanner | Analyzes directory depth, file sizes, module organization (never reads source) | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | entry-scanner | Identifies entry points, routes, config sources, slash commands | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | convention-scanner | Checks linters, formatters, type safety, .gitignore, naming patterns | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | feedback-scanner | Detects test files, CI/CD pipelines, pre-commit hooks, Claude Code hooks | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | baseline-scanner | Looks for machine-readable state files, previous audit results, progress tracking | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | budget-scanner | Measures persistent context overhead (tokens), instruction density, anti-patterns | readiness-scan |
| ![s](https://img.shields.io/badge/-%E2%80%8B-4A90D9) | database-scanner | Evaluates schema-as-code, migrations, data access patterns, seed data (conditional) | readiness-scan |
| ![g](https://img.shields.io/badge/-%E2%80%8B-2ECC71) | readiness-report-generator | Transforms scan JSON into human-readable readiness report with letter grade | readiness-scan |

## The Skill

**readiness-scoring** -- Contains the grading rubric (A+ to F), the 9 scoring gates with max points, confidence thresholds, and the principle of deterministic scoring (all checks use bash commands with fixed thresholds, no AI judgment). Loads automatically during readiness scans and when interpreting scores.

---

## How to Install

```bash
claude plugin marketplace add krwhynot/toque
claude plugin install toque-readiness@toque-marketplace --scope user
```

User scope (recommended) makes the plugin available in every project; use
`--scope project` to limit it to one. Verify with:

```
/toque-readiness:readiness-scan
```

## How to Update

An installed plugin lives in a **versioned cache directory**, and third-party marketplace auto-update
is **off by default**. Pulling the repository does not update an installed copy — you must refresh the
marketplace and update the plugin explicitly:

```
/plugin marketplace update toque-marketplace
/plugin update toque-readiness
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
> claude --plugin-dir /path/to/toque/plugins/toque-readiness
> ```
> Use this for plugin development. For an installed plugin, use the four-command sequence above.
