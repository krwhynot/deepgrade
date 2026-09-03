<div align="center">

# Toque Audit Guide v10.0.0

**5 Commands** &nbsp;&bull;&nbsp; **10 Agents** &nbsp;&bull;&nbsp; **3 Skills**

[![Plugin](https://img.shields.io/badge/Claude_Code-Plugin-5A45FF?style=for-the-badge)](https://github.com/krwhynot/toque)
[![Version](https://img.shields.io/badge/v10.0.0-stable-2ECC71?style=for-the-badge)](#)
[![Stack](https://img.shields.io/badge/Stack-Agnostic-F39C12?style=for-the-badge)](#)

</div>

> A reference for the toque-audit plugin: severity-graded codebase audits, security scans, delta tracking, characterization tests, and generated CI gates.

Toque Audit answers "what shape is this codebase in, and can we safely
change it?" A team of parallel agents inventories features, maps dependencies,
catalogs documentation, assesses per-module risk, and flags integration
touchpoints; a report generator turns their findings into a severity-classified
report any engineer can act on. Security runs as a separate control loop, and
delta scans re-measure against previous baselines so improvement is visible.
It is one of three Toque plugins; run `toque-readiness` first for a
navigability baseline.

## Commands

### `/toque-audit:codebase-audit`
**What it does:** Runs a full Toque codebase audit with 6 specialized agents across 4 phases (Stack Detection, Discovery, Analysis, Report Synthesis).
**When to use it:** After the readiness scan, when you want a deep assessment of code quality, risk, and documentation coverage.
**What it produces:** `docs/audit/toque-report.md` + feature inventory, dependency map, documentation audit, risk assessment, integration scan, and progress tracker.
**Example:**
```
/toque-audit:codebase-audit
```

---


### `/toque-audit:codebase-delta`
**What it does:** Quick 2-3 minute re-measurement against previous audit baselines. Shows what improved, what regressed, and flags stale findings via confidence decay.
**When to use it:** After making changes, to see if your scores improved without running a full audit.
**What it produces:** `docs/audit/delta-report.md` + `docs/audit/kpi-dashboard.md`
**Example:**
```
/toque-audit:codebase-delta
```

---

### `/toque-audit:codebase-characterize`
**What it does:** Generates golden master (characterization) tests that capture a module's current behavior before refactoring.
**When to use it:** Before touching any high-risk module -- especially monolith extractions or language migrations.
**What it produces:** Test files in the project's test directories (framework-dependent).
**Example:**
```
/toque-audit:codebase-characterize ReportsDB.GetSalesReport
/toque-audit:codebase-characterize payments
```

---


### `/toque-audit:codebase-gates`
**What it does:** Generates CI quality gates, Claude Code hooks, pre-commit hooks, and baseline-tracking scripts from audit findings. Three layers: passive tracking, smart nudges, and hard CI gates.
**When to use it:** After a codebase audit, to automate enforcement of the findings.
**What it produces:** `.github/workflows/toque-gate.yml`, `.claude/hooks/hooks.json`, `.pre-commit-config.yaml`, `docs/audit/gate-config.md`, and helper scripts.
**Example:**
```
/toque-audit:codebase-gates
```

---

### `/toque-audit:codebase-security`
**What it does:** Runs a security-specific scan covering dependencies, hardcoded secrets, SSL, injection risks, permissions, and more. Security is a separate control loop from code quality.
**When to use it:** Anytime you want a focused security assessment, independent from the general audit.
**What it produces:** `docs/audit/security-scan.md`
**Example:**
```
/toque-audit:codebase-security
/toque-audit:codebase-security secrets
```

---


## The 10 Agents

#### Assessors — analyze the codebase and assign risk.

| | Agent | What It Does | Used By |
|:-:|-------|-------------|---------|
| ![a](https://img.shields.io/badge/-%E2%80%8B-F39C12) | feature-scanner | Crawls codebase, produces feature inventory by functional domain | codebase-audit |
| ![a](https://img.shields.io/badge/-%E2%80%8B-F39C12) | dependency-mapper | Maps module-to-module refs, circular deps, coupling metrics, god classes | codebase-audit |
| ![a](https://img.shields.io/badge/-%E2%80%8B-F39C12) | doc-auditor | Catalogs all documentation, assesses quality, identifies business rules | codebase-audit |
| ![a](https://img.shields.io/badge/-%E2%80%8B-F39C12) | risk-assessor | Measures complexity, coupling, change frequency, test coverage, blast radius per module | codebase-audit |
| ![a](https://img.shields.io/badge/-%E2%80%8B-F39C12) | integration-scanner | Identifies all external touchpoints (APIs, payments, auth, databases) | codebase-audit |

#### Generators — produce reports and artifacts.

| | Agent | What It Does | Used By |
|:-:|-------|-------------|---------|
| ![g](https://img.shields.io/badge/-%E2%80%8B-2ECC71) | toque-report-generator | Transforms audit findings into severity-classified Toque report | codebase-audit |
| ![g](https://img.shields.io/badge/-%E2%80%8B-2ECC71) | gate-generator | Creates CI gates, Claude Code hooks, pre-commit hooks from audit findings | codebase-gates |
| ![g](https://img.shields.io/badge/-%E2%80%8B-2ECC71) | characterization-generator | Generates golden master tests capturing current behavior before refactoring | codebase-characterize |
| ![g](https://img.shields.io/badge/-%E2%80%8B-2ECC71) | security-scanner | Checks deps, secrets, SSL, injection, permissions (separate control loop) | codebase-security |
| ![p](https://img.shields.io/badge/-%E2%80%8B-9B59B6) | delta-scanner | Compares current state against audit baselines, tracks KPIs, applies confidence decay | codebase-delta |

## The 3 Skills

**toque-knowledge** -- Contains the Toque methodology: the three grade categories, enterprise best practices from 16-source research (risk assessment, discovery, documentation, report generation), and stack detection patterns. Loads automatically during codebase audits.

**governance-knowledge** -- Contains enterprise governance patterns: DORA metrics, confidence decay rules (findings lose trust after 30/60/90 days), quality gate patterns (SCAN pipeline, advisory mode, escape hatches), characterization testing methodology, and delta tracking guidance. Includes tier-aware confidence decay rates (Tier A/B/C findings decay at different speeds). Loads during delta scans, gate setup, security scans, and characterization test generation.

**self-audit-knowledge** -- Contains the LLM epistemic transparency framework: claim verification tiers (A = tool-verified, B = code-reading, C = pattern inference), evidence basis formatting, failure mode flags (`[ENUMERATION-MAY-BE-INCOMPLETE]`, `[INFERRED-FROM-NAMING]`, `[SIDE-EFFECTS-NOT-TRACED]`, `[DEAD-CODE-UNCERTAIN]`), category-based cascade risk classification (CASCADE/COVERAGE/CONTAINED), and report confidence thresholds. Loads during codebase audits, plan audits, and report generation.


---

## How to Install

```bash
claude plugin marketplace add krwhynot/toque
claude plugin install toque-audit@toque-marketplace --scope user
```

User scope (recommended) makes the plugin available in every project; use
`--scope project` to limit it to one. Verify with:

```
/toque-audit:codebase-audit
```

## How to Update

An installed plugin lives in a **versioned cache directory**, and third-party marketplace auto-update
is **off by default**. Pulling the repository does not update an installed copy — you must refresh the
marketplace and update the plugin explicitly:

```
/plugin marketplace update toque-marketplace
/plugin update toque-audit
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
> claude --plugin-dir /path/to/toque/plugins/toque-audit
> ```
> Use this for plugin development. For an installed plugin, use the four-command sequence above.
