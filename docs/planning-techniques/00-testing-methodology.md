# Planning Technique Testing Methodology

## Principle

"Tested" means both **behavior is correct** AND **the plugin is actually wired to use it**. Fixture plans alone prove detection logic works; they do not prove the techniques are integrated into the command/agent pipeline.

## 4 Test Layers

### Layer 1: Config/Wiring Tests
Parse `plugin.json`, `commands/`, and `agents/` to verify:
- Manifest validity (required frontmatter fields present)
- File existence (every file referenced in plugin.json exists)
- Repo consistency (version matches across plugin.json, README, CHANGELOG)
- Hook count consistency (README claims match plugin.json definitions)
- Command/agent cross-references resolve (agents referenced by commands exist)

### Layer 2: Hook Simulation Tests
Feed canned JSON payloads into actual hook scripts and assert:
- Migration guard blocks migration file edits
- Git guard blocks force-push and hard reset
- DB deploy guard blocks remote database operations
- Change tracking increments counters correctly
- Test tracking detects framework invocations

### Layer 3: Fixture Lint Tests
Known-gap plans with parser scripts (not grep-only):
- Plans with unverified HIGH assumptions → LINT-08 blocks
- Plans with no options analysis → LINT-13 fires
- Plans with orphan code changes → LINT-11 fires
- Plans with missing test infrastructure → LINT-15/LINT-16 fire
- Clean plans → all lint rules pass

### Layer 4: Behavioral Smoke Tests
Periodically run actual commands against fixed fixtures:
- `/deepgrade:help` produces expected command list
- `/deepgrade:quick-plan` against fixture objective produces required sections
- `/deepgrade:quick-audit` against known-gap plan detects expected gaps
- Assert required sections/artifacts exist, not exact wording

## Drift Detection
Repo-consistency assertions run on every test pass to catch:
- Version string drift (plugin.json vs README vs CHANGELOG)
- Hook count drift (README claims vs plugin.json definitions)
- Command list drift (help.md vs actual command files)
- Agent reference drift (commands referencing agents that don't exist)
