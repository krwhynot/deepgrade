# Changelog

## 2.0.0 (2026-03-06)

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

## 1.0.0 (2026-02-xx)

### Added
- Phase 1: 10 AI Readiness scanner agents + 2 commands
- Phase 2: 6 DeepGrade audit agents + 1 command (C#/.NET only)
- Hardened deterministic scoring (7 unstable checks fixed)
