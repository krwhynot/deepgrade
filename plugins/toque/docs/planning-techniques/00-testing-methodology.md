# Planning Technique Testing Methodology

## Principle

"Tested" means both **behavior is correct** AND **the plugin is actually wired to use it**. Fixture plans alone prove detection logic works; they do not prove the techniques are integrated into the command/agent pipeline.

## 8 Test Layers

### Layer 1: Config/Wiring Tests
Parse `plugin.json`, `commands/`, and `agents/` to verify:
- Manifest validity (required frontmatter fields present)
- File existence (every file referenced in plugin.json exists)
- Repo consistency (version matches across plugin.json, README, CHANGELOG)
- Hook consistency (README claims match `hooks/hooks.json` definitions; an inline `hooks` key in plugin.json is a defect, because it silently disables the folder)
- Command/agent cross-references resolve (agents referenced by commands exist)

### Layer 2: Hook Simulation Tests
Feed canned JSON payloads into actual hook scripts. Only the three plan-context handlers
declared in `hooks/hooks.json` remain — SessionStart, SubagentStop, PreCompact. The guard,
migration, tracker and Stop handlers shipped in toque-guard and were retired with it in 9.0.0,
along with the hook corpus that exercised them. What the layer asserts today:
- One falsifying test per surviving behaviour-ledger row, via `layer2-ledger-rows.js`
- Row 10: SessionStart reads a pretty-printed `status.json` and reports that phase's own status, not the first one in the file
- Row 4: SubagentStop appends the stop reason to the plan log — and creates neither log nor directory when there is no `troubleshooting/` dir
- F26: every informational handler exits 0 emitting JSON only, with stderr empty
- Retired parts stay retired: `layer2-hook-simulation.sh` and the hook corpus must be absent, not merely undispatched, since an undispatched test file reads as coverage
- A missing `node` fails the layer rather than skipping it — the handlers run on node, so an absent interpreter means the layer proves nothing

### Layer 3: Fixture Lint Tests
Known-gap plans with parser scripts (not grep-only):
- Plans with unverified HIGH assumptions → LINT-08 blocks
- Plans with no options analysis → LINT-13 fires
- Plans with orphan code changes → LINT-11 fires
- Plans with missing test infrastructure → LINT-15 fires
- Clean plans → all lint rules pass

### Layer 4: Behavioral Smoke Tests
Periodically run actual commands against fixed fixtures:
- `/toque:help` produces expected command list
- `/toque:quick-plan` against fixture objective produces required sections
- `/toque:quick-audit` against known-gap plan detects expected gaps
- Assert required sections/artifacts exist, not exact wording

### Layer 5: Evidence Validator
Require the real `scripts/tq-evidence-validate.js` module — no second copy of the rules to drift:
- Evidence records carry a valid verdict
- Quoted evidence matches the cited artifact byte for byte
- Directory-level validation reports every malformed record

### Layer 6: Canary
Check the **auditor**, not the plan. A known defect is injected into a fixture spec; an audit that
fails to report it is not a clean audit, it is a broken one.

### Layer 7: Release Preflight
Run `.github/release.sh check` against a scratch clone:
- It passes on a clean released tree
- It refuses each synthetic violation (missing breaking-change section, missing migration note, unpinned catalog)
- Every violation is committed in the clone, so a preflight that only checked tree cleanliness cannot pass

### Layer 8: Protected Artifacts
Run `.github/protected-artifacts.sh` against a scratch clone:
- A clean tree passes; adding a new change record passes
- Modifying, deleting, renaming or retyping a `snapshots/` file or a `changes/CR-*.md` is refused
- An `evidence/` edit is NOT refused — the scope boundary is asserted, not assumed
- CI modes: a push range containing a violation fails; a zero or unresolvable before-SHA fails loud (exit 2) rather than passing vacuously; a dispatch on main checks `HEAD^..HEAD`; a pull request diffs from the merge-base so base-branch commits are not blamed on the PR

## Drift Detection
Repo-consistency assertions run on every test pass to catch:
- Version string drift (plugin.json vs README vs CHANGELOG)
- Hook drift (README claims vs `hooks/hooks.json` definitions)
- Command list drift (help.md vs actual command files)
- Agent reference drift (commands referencing agents that don't exist)
