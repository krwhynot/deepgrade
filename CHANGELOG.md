# Changelog

## 4.29.0 (2026-03-22)

### Added
- New command: `/deepgrade:codex-challenge` — Evaluator-Optimizer loop between Claude and OpenAI Codex CLI
- Score-driven convergence: Codex scores plan (8 dimensions × 5 = max 40), Claude optimizes until 36/40 GREEN achieved
- 8 adversarial review dimensions (problem, architecture, sequencing, risk, rollback, timeline, testing, omissions)
- Model escalation: auto-upgrades to gpt-5.4 when score < 24/40 (RED)
- Structured `codex-review.md` report with per-dimension score trajectory and gap resolution log
- Pre-review backup system with timestamped snapshots in `.codex-backup/`
- Schema-validated JSON output via Codex CLI `--output-schema` (eliminates free-text parsing)
- Read-only sandbox: no `--dangerously-bypass-approvals-and-sandbox` needed (default read-only verified)
- Ephemeral sessions via `--ephemeral` flag (no session file persistence)
- Fail-closed parsing with JSON primary, legacy text fallback
- Security isolation: Codex runs from `os.tmpdir()` in read-only sandbox
- Parser regression tests: 41 test cases covering JSON, text, schema, and edge cases
- Windows-compatible Codex invocation via Node.js temp-file pattern
- 15-minute hard ceiling with per-round budget checkpoints

## 4.27.1 (2026-03-15)

### Added
- LLM Self-Audit Framework: epistemic transparency for audit findings
- New skill: `self-audit-knowledge` — single source of truth for claim verification tiers (A/B/C), failure mode flags, and cascade risk classification
- Evidence Basis column in all 5 Phase 2 scanner agents (feature-scanner, dependency-mapper, doc-auditor, risk-assessor, integration-scanner)
- Structured Phase 3 synthesis with 7 steps: cross-reference matrix, contradiction detection, spot-checking, cascade risk assessment, coverage failure checks
- Self-Audit Summary section in report generator (replaces Confidence Summary)
- Analysis Reliability paragraph in Executive Summary
- Evidence-based finding format with cascade risk line (exception-only for non-CONTAINED)
- Tier A/B/C labels in plan-auditor Confidence Summary
- Evidence basis format in plan-scaffolder Plan Confidence table
- Plan audit failure mode flags: `[PLAN-GAP-INFERRED]`, `[SCOPE-ASSUMED]`, `[CODEBASE-CLAIM-NOT-VERIFIED]`
- Tier-aware confidence decay in governance-knowledge (Tier A: 30/60/90d, Tier B: 20/45/75d, Tier C: 15/30/60d)
- Claim verification tier guidance in codebase-audit confidence_tiers section
- Thinking guidance for CASCADE + Tier C and setter/mutation side-effects

### Changed
- Confidence Summary in report generator replaced by richer Self-Audit Summary
- Phase 3 synthesis expanded from 5 lines to 7 structured steps
- Plan-auditor evidence requirement now maps to Tier A/B/C alongside HIGH/MEDIUM/LOW
- Plan-scaffolder Confidence Summary uses evidence basis format
- quick-plan Step 4 references evidence basis distribution and Tier C threshold

## 4.27.0 (2026-03-06)

### Breaking Changes
- Converted from standalone `.claude/` format to Claude Code plugin
- All commands now namespaced: `/deepgrade:command-name`
- File names changed (see migration guide below)

### Added
- Plugin manifest (`.claude-plugin/plugin.json`)
- `/deepgrade:help` command listing all capabilities
- Stack-agnostic Phase 2 agents (React/TS, C#/.NET, Python, Rust, Go)
- Phase 0 stack detection in Phase 2 orchestrator
- Fan-in/fan-out coupling metrics in risk-assessor (from PViz research)
- Debt classification: CRITICAL/MANAGED/DEFERRED in risk-assessor (from CAST Highlight)
- SCC (circular dependency) detection in dependency-mapper
- "Outcomes that cannot fail" identification in feature-scanner
- Business outcome narrative in report-generator
- Two skills: readiness-scoring, deepgrade-knowledge

### Changed
- report-generator split into readiness-report-generator (Phase 1) and deepgrade-report-generator (Phase 2)
- context-file-scanner renamed to context-scanner
- entry-point-scanner renamed to entry-scanner
- feedback-loop-scanner renamed to feedback-scanner
- context-budget-scanner renamed to budget-scanner
- documentation-auditor renamed to doc-auditor

### Migration from 1.x (standalone)

If upgrading from the standalone `.claude/` version:

1. Remove old files from `.claude/agents/` and `.claude/commands/`
2. Install the plugin: `claude --plugin-dir ./deepgrade`
3. Commands change from `/ai-readiness-scan` to `/deepgrade:readiness-scan`
4. Commands change from `/deepgrade-audit` to `/deepgrade:codebase-audit`

## 4.26.0 (2026-02-xx)

### Added
- Phase 1: 10 AI Readiness scanner agents + 2 commands
- Phase 2: 6 DeepGrade audit agents + 1 command (C#/.NET only)
- Hardened deterministic scoring (7 unstable checks fixed)
