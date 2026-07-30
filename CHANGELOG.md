# Changelog

## 5.0.0 (2026-07-30)

A hardening pass across the plugin's configuration, hooks, and command surface. No new
user-facing features — this release fixes defects found by a structured audit and verifies
the fixes actually work, including with a runtime check that confirms the safety hooks fire
in a live session rather than just looking correctly configured on disk.

### Fixed
- `/deepgrade:codebase-gates` told users their generated hooks were written to
  `.claude/hooks/hooks.json` — a location Claude Code never reads from a project. The feature
  silently did nothing. Hooks are now correctly targeted at the `hooks` key of
  `.claude/settings.json`, merged rather than overwritten.
- `/deepgrade:plan-status` with no argument reported "No plans found." on a normal project
  layout, because its existence check and its listing loop referenced different directories.
- `/deepgrade:quick-cleanup`'s Word-document fallback printed a "no pandoc and no python
  interpreter" error on a **successful** conversion, due to a shell operator-precedence bug.
- `/deepgrade:plan-export`'s Windows fallback (no `zip` on stock Windows) is now verified to
  actually create an archive, not merely to mention the right PowerShell cmdlet.
- `/deepgrade:readiness-generate` no longer shells out to `tree`, which is absent from Git
  Bash; several commands' temp-file handling is now portable across Windows and Linux.
- Removed dead `/ai-readiness-*` command references left over from an earlier rename; the
  real commands are `/deepgrade:readiness-*`.
- Several skills carried thin or absent trigger descriptions and could not reliably load;
  descriptions now carry concrete trigger phrasing.
- The `mcp-research` skill was referenced only in prose ("see the mcp-research skill") with
  no resolvable link; now referenced by its namespaced name.
- The former `doc` command (superseded by the `documentation` skill) is fully retired: no
  command file, no live references to it anywhere in the plugin's product surface.
- Hooks are now proven to fire at runtime (not just correctly declared): file-change
  tracking, test-run detection, and subagent-completion logging were each verified by
  actually triggering them in a live session, not by reading configuration.

### Removed
- `docs/troubleshooting-techniques/` — nine files duplicating content from a standalone
  sibling skill bundle, referenced by nothing in this plugin (no command, agent, skill, or
  test loaded it). Removing the orphaned copy eliminates the duplication permanently; the
  content is preserved in git history.

### Known gaps
A small number of internal consistency checks for this release are text-based and were
found to be an unreliable way to verify certain claims — specifically, whether an
*instruction* is followed (e.g., "the agent must emit a PowerShell variant") as opposed to
whether a *string* is present or absent. Where our verification could not distinguish a real
instruction from an example, a decoy, or a negation, we are recording that honestly rather
than shipping a check that looked green without meaning much. This affects a handful of
internal acceptance criteria, not shipped behavior we have reason to believe is broken; each
underlying product change was independently verified by reading the actual file. Tightening
these into genuine runtime tests is ongoing.

### Deferred to 5.1.0
- Converting the 1,528-line `/deepgrade:plan` command into a skill (better survival across
  context compaction in long planning sessions). This is an improvement to a command that
  works today, not a fix, and is being done separately with its own staging and rollback
  proof.

## 4.31.0 (2026-04-03)

### Added
- Optional MCP research tool integration across planning, troubleshooting, documentation, and audit
  workflows. **All integrations degrade gracefully — the plugin works identically with no MCP servers
  connected.**
- New knowledge skill: `skills/mcp-research/SKILL.md` — tool selection heuristics and tier mapping
  (Ref → Exa → Perplexity), token budget rules, and graceful degradation patterns
- `/deepgrade:plan`: tiered Ref → Exa → Perplexity search in Phase 2 Track 3, plus URL verification
  for HIGH-impact confidence entries
- `/deepgrade:troubleshoot`: Step 0.2 external documentation and issue lookup (Ref + Exa)
- The documentation command and skill: external enrichment for specs, ADRs, and READMEs
- `integration-scanner`: API validation against external documentation via Ref
- `dependency-mapper`: deprecation checking via Ref documentation

### Changed
- `METHODOLOGY.md`: Track 3 tools table updated for the tiered search strategy
- `/deepgrade:readiness-generate`: now offers to generate a research MCP server `.mcp.json`

## 4.30.0 (2026-03-31)

### Added
- `confidence.md` brief in the planning process — a stakeholder-readable knowledge brief grounding
  every tool, method, and pattern choice in external industry evidence. Created in Phase 3 (Pre-Plan),
  reinforced in Phase 5 (Audit).
- Source credibility tiers (A/B/C) with impact classification and required rationale per entry
- LINT-17 and LINT-18 validation rules for confidence brief completeness
- Confidence falsification protocol, staleness cascade integration, timeline-pressure protections for
  HIGH-impact entries, and a conflicting-evidence protocol

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
