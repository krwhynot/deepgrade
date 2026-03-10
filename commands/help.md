---
description: Show all DeepGrade Developer Toolkit commands, agents, and capabilities. Use when you need to see what's available or explain the toolkit to someone new.
---

# DeepGrade Developer Toolkit (/tp)

A planning + implementation assistant with codebase auditing. Stack-agnostic:
works on React/TypeScript, C#/.NET, Python, Rust, and Go projects.

## Commands

### Planning (the 9-phase guided workflow)

| Command | What It Does |
|---------|-------------|
| `/deepgrade:plan` | Start or resume a guided plan. 9 phases: Brainstorm, Research, Pre-Plan, Plan, Audit, Build, Impact Review, Test, Handoff. |
| `/deepgrade:plan-status` | Show all active plans or detailed status of one plan with staleness checks. |
| `/deepgrade:plan-export` | Export a plan as a self-contained zip. Includes all docs, redacts secrets, adds CLAUDE.md for vanilla Claude Code bootstrap. |

### Quick Shortcuts (standalone, no guided workflow)

| Command | What It Does |
|---------|-------------|
| `/deepgrade:quick-plan` | Create a plan directly from an objective (skips brainstorm/research). |
| `/deepgrade:quick-audit` | Audit any spec or plan file. 8-dimension score + devil's advocate. |
| `/deepgrade:quick-cleanup` | Clean up a folder of messy docs into structured reference files. |
| `/deepgrade:troubleshoot` | AI-guided debugging. Suggests diagnostics, logs every step tried, builds a knowledge base. Auto-links to active plan. |

### /deepgrade:plan vs /deepgrade:quick-plan: Which Do I Use?

| | `/deepgrade:plan` | `/deepgrade:quick-plan` |
|--|-----------|-----------------|
| **What** | Guided 8-phase workflow | One-shot plan generation |
| **Phases** | All 8 (Brainstorm through Handoff) | Phase 4 (Plan) only |
| **Asks questions?** | Yes, walks you through interactively | No, takes objective and generates immediately |
| **Creates plan folder?** | Yes: `docs/plans/2026-03-07-{name}/` | No, just writes `docs/specs/{name}.md` |
| **Research?** | Yes, scans codebase + docs + web | No, uses existing context |
| **Audit?** | Yes, scores and challenges the plan | No (run `/deepgrade:quick-audit` separately) |
| **Build help?** | Yes, tracks tickets and assists | No, plan is delivered |
| **Resumes?** | Yes, come back anytime | No, one and done |
| **Time** | 30-60 min full workflow | 5-10 min |

**When to use each:**

| Situation | Use |
|-----------|-----|
| New project, vague idea, need to think it through | `/deepgrade:plan` |
| Got docs from someone, need the full treatment | `/deepgrade:plan {name} from {folder}` |
| Already know what to build, just need it written down | `/deepgrade:quick-plan` |
| Someone asks "write up a plan for X" and you need it fast | `/deepgrade:quick-plan` |
| Plan needs leadership approval | `/deepgrade:plan` (includes audit) |
| Quick internal plan for yourself | `/deepgrade:quick-plan` |

Same pattern applies: `/deepgrade:quick-audit` = audit one file without the workflow.
`/deepgrade:quick-cleanup` = clean up docs without the workflow.

### Readiness Scan (Phase 1: Can AI read this codebase?)

| Command | What It Does |
|---------|-------------|
| `/deepgrade:readiness-scan` | AI Readiness scan. 52 checks, 9 categories, letter grade A+ to F. |
| `/deepgrade:readiness-generate` | Generate missing artifacts found by readiness scan. |

### Codebase Audit (Phase 2: What's in it and what's risky?)

| Command | What It Does |
|---------|-------------|
| `/deepgrade:codebase-audit` | Full DeepGrade codebase audit. 6 parallel agents: features, dependencies, docs, risk, integrations, report. |
| `/deepgrade:codebase-security` | Security-focused scan: dependency vulns, secrets, SSL, injection risks. |

### Codebase Monitoring (Phase 3: Did changes help or hurt?)

| Command | What It Does |
|---------|-------------|
| `/deepgrade:codebase-delta` | Quick re-measurement. What improved, what regressed, KPI dashboard. |
| `/deepgrade:codebase-gates` | Generate CI quality gates and Claude Code hooks from audit findings. |
| `/deepgrade:codebase-characterize` | Golden master tests that capture behavior before refactoring. |

### Documentation

| Command | What It Does |
|---------|-------------|
| `/deepgrade:doc` | Generate any document: ADR, BRD, PRD, README, release notes, spec. |

### Utility

| Command | What It Does |
|---------|-------------|
| `/deepgrade:help` | This command. |

## Phase 1: AI Readiness (10 scanner agents)

Scores how ready your codebase is for AI-assisted development.

| Agent | Scans For |
|-------|----------|
| manifest-scanner | package.json, .sln, pyproject.toml completeness |
| context-scanner | CLAUDE.md, .claude/ rules, AI context files |
| structure-scanner | Directory organization, co-location, nesting depth |
| entry-scanner | Main entry points, startup files, route handlers |
| convention-scanner | Naming patterns, linting config, formatting consistency |
| feedback-scanner | CI/CD, pre-commit hooks, test automation |
| baseline-scanner | Existing audit baselines, confidence tracking |
| budget-scanner | Context window efficiency, instruction count |
| database-scanner | Schema docs, migration tracking, connection patterns |
| readiness-report-generator | Synthesizes all scanner outputs into scored report |

## Phase 2: DeepGrade Audit (6 agents)

Deep analysis producing actionable documentation.

| Agent | Produces |
|-------|---------|
| feature-scanner | Feature inventory by domain with critical business paths |
| dependency-mapper | Dependency graph, coupling metrics, circular dependencies |
| doc-auditor | Documentation coverage assessment, gap analysis |
| risk-assessor | Module risk ratings, debt classification, phase boundaries |
| integration-scanner | External touchpoints, security observations |
| deepgrade-report-generator | Final DeepGrade report with severity-classified findings |

## Phase 3: Enterprise Governance (4 agents)

Verify progress, enforce quality, and maintain audit freshness.

| Agent | What It Does |
|-------|-------------|
| delta-scanner | Re-measures codebase, compares against baselines, tracks KPIs, handles confidence decay |
| gate-generator | Creates CI workflows, Claude Code hooks, and pre-commit hooks from audit findings |
| security-scanner | Dependency vulns, hardcoded secrets, SSL config, injection risks, permissions |
| characterization-generator | Golden master tests that capture current behavior before refactoring |

## Planning Tools (2 agents)

Create and review technical plans for any engineering initiative.

| Agent | What It Does |
|-------|-------------|
| plan-auditor | Scores any plan across 8 dimensions (problem, architecture, phasing, risk, rollback, timeline, testing, team). Produces go/no-go assessment. |
| plan-scaffolder | Creates structured plans from vague objectives. Reads codebase + audit data to generate evidence-based phased plans. |

## Documentation Skill (6 templates)

Generate any project document. Auto-loaded when you mention documentation.
Powered by audit data when available. Suggests which document to create if you're unsure.

| Type | Command Example | What It Creates |
|------|----------------|----------------|
| ADR | `doc adr credential rotation` | Architecture Decision Record |
| BRD | `doc brd Ordering` | Business Requirements Document |
| PRD | `doc prd refund processing` | Product Requirements Document |
| README | `doc readme BusinessLogic` | Project README |
| Release Notes | `doc release-notes v2.5.0` | Release notes from git history |
| Spec | `doc spec pricing engine extraction` | Technical Specification / Engineering Plan |

Don't know which format? Just say "I need to document X" and the skill will recommend the right type based on your context and audit data.

## Typical Workflow

**For codebase auditing:**
1. `/deepgrade:readiness-scan` to get your baseline score
2. `/deepgrade:readiness-generate` to fix low-hanging issues
3. Re-scan to verify improvement
4. `/deepgrade:codebase-audit` when score reaches 80%+
5. `/deepgrade:codebase-gates` to generate CI quality checks
6. `/deepgrade:codebase-delta` after changes to verify improvement
7. `/deepgrade:codebase-security` periodically

**For planning any new work (the 8-phase guided workflow):**
```
/deepgrade:plan {name}
```
Walks you through: Brainstorm -> Research -> Pre-Plan -> Plan -> Audit -> Build -> Impact Review -> Test -> Handoff

All artifacts go to `docs/plans/{date}-{name}/`. Check progress with `/deepgrade:plan-status`.

**For standalone tasks (experienced users):**
- `/deepgrade:quick-plan [objective]` to generate a plan directly
- `/deepgrade:quick-audit [file]` to audit any spec or plan
- `/deepgrade:quick-cleanup [folder]` to clean up messy docs
- `/deepgrade:doc [type] [topic]` to generate a specific document
- `/deepgrade:codebase-characterize [module]` to generate golden master tests

**Note on gating:** The readiness scan uses two tiers of gates:
- **Hard gates** (manifest, context file, entry point, tests): Must pass or Phase 2 is blocked
- **Soft gates** (CLAUDE.md specifics, monolith files, do-not-touch zones): Score penalty + warning, but Phase 2 still runs with reduced confidence on affected modules

If soft gates fail (e.g., monolith files exist), the readiness report generates
a "Phase 2 Focus Priorities" section that tells the audit exactly where to dig
deepest. The audit output becomes your roadmap for fixing the structural issues.

## Output Locations

| What | Where |
|------|-------|
| Plan homebase (brainstorm, approach, research) | `docs/plans/YYYY-MM-DD-{name}/` |
| Plan manifest (links to everything) | `docs/plans/YYYY-MM-DD-{name}/manifest.md` |
| Specs | `docs/specs/` |
| ADRs | `docs/adr/` |
| PRDs | `docs/prd/` |
| Plan audits | `docs/audit/` |
| Readiness scan data | `docs/audit/readability/` |
| Codebase audit reports | `docs/audit/` |
| Golden master tests | Project test directories |
