# Changelog

## Unreleased

### Changed
- **`/deepgrade:plan` is a skill.** The 1,710-line command is now
  `skills/plan/SKILL.md` (a 319-line router) plus one file per phase under
  `skills/plan/phases/`, read on entry to that phase. Invocation, arguments,
  and `status.json` are unchanged. Closes F12 (deferred since 5.0.0): a
  single long command loses its later phases after context compaction in
  exactly the long sessions a nine-phase workflow produces. Tests that read
  Phase 5 content now point at `phases/phase-5-audit.md`.
- **`/deepgrade:troubleshoot` and `/deepgrade:codex-challenge` are skills**, on
  the same router-plus-phase-files layout as `plan`. troubleshoot (854 lines)
  becomes a 256-line router with the incident pre-flow, four phases,
  multi-agent mode, and knowledge-base write-back in one file each;
  codex-challenge (533 lines) becomes a 213-line router with the output
  schema, prompt template, round loop, and report split out. The parser
  tests now bind to `skills/codex-challenge/phases/output-schema.md`. The
  three remaining long commands (quick-cleanup, readiness-generate,
  plan-export) are under the documented 500-line guidance and stay as
  commands. Closes backlog B07.
- The documentation skill's bundled templates live in `references/`, the
  documented convention, instead of `resources/`. Closes backlog B28.
- The `(deepgrade)` description prefix is stripped from all 23 commands and
  skills. After the monorepo split it mislabelled 11 files owned by
  deepgrade-audit and deepgrade-readiness.
- Marketplace entries carry `category` and `tags`; the non-deliverable
  owner email is removed.

### Fixed
- Backlog triage of the 32 low/info findings recorded against 4.31.0: 13 were
  already closed by the hardening work; 15 fixed here. Scanner "Output"
  sentences un-garbled in all 8 readiness scanners; database-scanner check 9.1
  name matches its contract; plan-auditor steps renumbered 1-7 and its subagent
  count corrected to 5; gate-generator's duplicate Step 4.5 is now 4.6; every
  `<valid_commands>` block regenerated from the real 17-entry surface; help.md
  drops the dead `/tp`, lists the plan skill, and namespaces its documentation
  examples; the phantom `plan-review.js` reference is gone; two agents no longer
  read a `$ARGUMENTS` that is never substituted; the documentation skill no
  longer carries a literal positional placeholder in its body; the two long
  templates have a Contents list; mcp-research drops a baked-in date;
  METHODOLOGY.md stops describing the removed bash PATH preamble as current.
- Stop hooks (guard session-stop, deepgrade subagent-stop) exit silently when
  `stop_hook_active` is set, so a continued turn cannot re-post the summary.
  The session-stop hook also sweeps tracker files from other sessions older
  than a day; before this they accumulated in TMPDIR forever.

### Internal
- CR-7 (owner-ratified): the U7 compatibility-floor requirement is descoped.
  Verification is on the current Claude Code version at each release (hosted
  ubuntu+windows CI); no floor is declared. F24 closed — every
  plugin-hardening-v5 finding is now closed. The auth-free bisection facts
  (`--strict` appears at 2.1.145; git-subdir pinned installs work at ≤2.1.144)
  are preserved in the plan's research record.
- Test scratch directories are swept at process exit — 49 OS-temp entries
  leaked per combined test run before, zero after.

## 7.1.0 (2026-08-03)

### Changed
- **Check-element vocabulary ratified to `points`/`max`.** The 2026-08-03
  dogfood run showed every scanner template demanding `score`/`max_score`
  while all eight live scanners emitted `points`/`max` unanimously; the
  templates were aligned to observed reality, the interop fixture was
  regenerated from a real scan artifact, and the retired vocabulary is now
  banned by the INTEROP sweep.
- Marketplace entries use `git-subdir` sources with explicit https URLs, so
  installs no longer require GitHub SSH keys; SPLIT-4 guards the catalog
  shape. `interop.md` documents the cross-plugin artifact contracts,
  enforced by the INTEROP sweep. Two README drifts fixed (readiness score
  path, guard output table).

### Removed
- **Per-check `confidence` field dropped from scanner templates.** Recon
  proved zero consumers: the report generator never reads it, and the
  methodology's "confidence levels" are a module-level concept the
  orchestrator derives from gate results, not a `checks[]` field.
  Module-level confidence is untouched.

### Internal
- Runtime evidence completed: all nine PHV5-044 Part 2 owner-observed
  checks recorded live on the installed copy — SessionStart, PreCompact and
  both Stop branches surfacing; deny, ask and allow paths; and the
  node-less hook-error notice (CR-1 re-confirmed). Line-ending handling is
  enforced via `.gitattributes` (`* text=auto eol=lf`, snapshots frozen),
  and F30's directory allowlist was replaced by an occurrence-addressed
  provenance ledger.

## 7.0.0 (2026-08-03)

The monolith is now four plugins. Updating `deepgrade` alone does NOT keep the
toolkit you had — read the BREAKING section before updating.

### BREAKING

- **One plugin is now four.** `deepgrade` keeps only the planning core (plan,
  plan-status, plan-export, quick-plan, quick-audit, quick-cleanup,
  troubleshoot, codex-challenge, help). Auditing, readiness scanning, and the
  safety hooks moved to plugins that must be installed separately:
  `/plugin install deepgrade-audit@deepgrade-marketplace`,
  `deepgrade-readiness@deepgrade-marketplace`, and
  `deepgrade-guard@deepgrade-marketplace`.
- **Audit and readiness commands renamespace to their plugin.**
  `/deepgrade:codebase-audit` → `/deepgrade-audit:codebase-audit` (same for
  codebase-characterize, codebase-delta, codebase-gates, codebase-security);
  `/deepgrade:readiness-scan` → `/deepgrade-readiness:readiness-scan` (same for
  readiness-generate). Anything scripted against the old names breaks.
- **Skills renamespace with their plugin.** `deepgrade-knowledge` and
  `governance-knowledge` load as `deepgrade-audit:*`; `readiness-scoring` as
  `deepgrade-readiness:readiness-scoring`. `self-audit-knowledge` resolves under
  BOTH `deepgrade:` (canonical) and `deepgrade-audit:` (byte-identical mirror,
  guarded by the suite).
- **The safety hooks ship only in `deepgrade-guard`.** The git/DB deploy guard,
  migration guard, change/test trackers, and the Stop-time session summary
  (PreToolUse ×2, PostToolUse ×2, Stop) are no longer part of `deepgrade`,
  which retains only SessionStart, SubagentStop, and PreCompact. An update that
  does not add `deepgrade-guard` silently loses force-push and DB-deploy
  blocking.
- **The monolith GUIDE is retired.** Each plugin ships its own README and
  GUIDE; METHODOLOGY.md remains the deep reference for the audit methodology.

### Changed

- Versions are lockstep across the four manifests; the marketplace lists four
  entries sharing one ref+SHA pin, released atomically by `.github/release.sh`.
- The suite gained per-plugin layer-1 profiles plus split invariants: SPLIT-1
  (self-audit-knowledge mirror byte-identity, eol-insensitive), SPLIT-2
  (4-manifest lockstep), SPLIT-3 (cross-namespace reference resolution). CI
  validates the root marketplace and each plugin directory.

## 6.0.0 (2026-08-02)

The Phase 5 audit gate no longer authorizes a plan on the score the audited model
assigned to itself. Full design: `docs/specs/phase5-verifier-gate.md`.

### BREAKING

- **The Phase 5 gate expression changed.** `IF score >= 32 AND gap-checked = YES`
  is gone. A plan now passes only when the seeded canary was found, every evidence
  record survived mechanical re-checking, every applicable criterion is MET or N_A,
  and infra gaps are zero. **Plans that previously passed at 32-40 on prose scores
  will fail under 6.0.0 until their claims carry evidence.** This is intended: a
  score in that band proved the text resembled the rubric, not that the claims were
  true.
- **The YELLOW outcome is gone.** "Usable with known gaps" no longer exists as a
  rung; either every applicable criterion is satisfied and evidenced, or the
  specific unmet ones are named. Anything scripted against the GREEN/YELLOW/ORANGE
  bands must read the gate verdict instead.
- **`/deepgrade:quick-plan` uses the same gate.** It previously accepted a plan at
  `score >= 32/40` on its own; a lighter command with a score gate was a way
  around the main one.
- **The solo-mode review waiver is conditional.** Blocked when infra gaps exist,
  when the score is under 35, or when the canary was missed. Solo workflows that
  relied on an unconditional waiver will now be prompted for a named reviewer in
  those cases.
- **Audits must produce evidence.** The auditor writes one record per criterion to
  `evidence/{criterion_id}.json`; a missing or empty evidence directory fails the
  gate (exit 2 — treated as worse than a demotion, because an audit that produced
  nothing checkable reporting clean is the failure mode this release removes).
- **LINT-17/18 renumbering.** The confidence-brief rules formerly carrying those
  ids in `commands/plan.md` and `agents/plan-auditor.md` are now LINT-19/20; 17/18
  are the testing-methodology rules, as the registry always defined them. Audit
  reports written before 6.0.0 refer to the confidence-brief checks by the old ids
  and are left unrewritten.

### Added

- `scripts/dg-evidence-validate.js` — re-reads every cited artifact, verifies the
  hash, slices the cited line range, and compares byte-for-byte with the quote.
  Validation only ever demotes; the judge's MET is a proposal. Suite layer 6.
- `scripts/dg-canary.js` — injects one known defect (5 classes, seeded rotation)
  into a working copy before the audit; an audit that misses it twice fails as
  untrustworthy and does NOT trigger the revision loop. Suite layer 7.
- A rubric-free holistic judge whose unmapped findings land in
  `docs/planning-techniques/lint-candidates.md` — the only mechanism that can
  notice the rubric itself is incomplete. Advisory, never gates.
- `score_history` in `status.json`: the score no longer gates, but its
  distribution is the cheapest detector of threshold-aiming.
- Judge isolation: the rubric, anchors, and thresholds moved out of
  generator-readable files; `<forbidden_inputs>` in `agents/plan-auditor.md`; a
  fresh auditor instance per revision iteration; verdict schema with no total
  field and evidence serialized before the verdict.
- `docs/planning-techniques/lint-registry.md` is now the enforced single source of
  lint rule text and counts (guards PH5-001/002 in the suite; every rule had
  drifted into at least one alternate wording, and two into a second meaning).

### Known limitations (stated, not closed)

- The auditor holds Read/Grep/Glob over the repository and can reach the criterion
  files and the canary defect table. Isolation is enforced by instruction, not
  capability; the canary reliably detects a lazy audit, only incidentally an
  adversarial one.
- Nothing in this release measures whether the judge is *right* — only whether it
  is evidenced. Judge calibration against known-good/known-bad plans is the
  natural successor.

## 5.0.1 (2026-08-02)

### Added
- The 4.x migration note 5.0.0 should have carried. 5.0.0 changed the hook runtime
  dependency, moved where hooks are declared, and changed the `git reset --hard` decision —
  and shipped with no upgrade sequence, no disable procedure, and no statement of what was
  and was not verified. Those are now recorded under 5.0.0 below, describing the release
  they belong to. This version exists so they reach installed copies: the version in
  `plugin.json` is the cache key, and text attached to an already-published tag propagates
  to nobody.
- The marketplace catalog now pins an explicit source object carrying the release commit's
  full SHA, so an install resolves to a known tree rather than to whatever the default
  branch happens to hold.


## 5.0.0 (2026-07-30)

A hardening pass across the plugin's configuration, hooks, and command surface. No new
user-facing features — this release fixes defects found by a structured audit and verifies
the fixes actually work, including with a runtime check that confirms the safety hooks fire
in a live session rather than just looking correctly configured on disk.

### Breaking

**The safety hooks now require `node` (18 or later) instead of `bash` and `jq`.** On 4.31.0
the hooks were declared inline in `plugin.json` as `bash -c '...'` one-liners that preferred
`jq` and fell back to `grep`/`sed` string parsing. They are now one Node script per handler
under `scripts/`, declared in `hooks/hooks.json`. Where `node` cannot be spawned the guards
do not run at all and Claude Code surfaces its own hook-error notice — visible in an
interactive session, suppressed under `claude -p`.

**`git reset --hard` now asks instead of blocking.** On 4.x it was denied outright. It now
raises a confirmation prompt you can accept. Force pushes and direct database deploys are
still blocked.

**Guard matching is scoped to the command itself.** On 4.x the guard matched its trigger
strings anywhere in the hook payload, so `git commit -m "no git push --force"` was blocked by
its own commit message, and a trigger word inside a quoted argument or a tool description
stopped legitimate work. Matching is now shell-word aware and reads only the command field.
Commands that 4.x wrongly blocked will now run.

**Enforcement is PARTIAL by design.** The guards enforce only where a real parser is
available. On a host without one they allow the event and report themselves rather than
failing closed. This is recorded as formally NOT MET on parser-less hosts rather than
claimed fixed everywhere.

### Upgrading from 4.x

Third-party marketplace auto-update is off by default, and hook commands keep using the
previous version's path mid-session. An upgrade will not reach you without these four
commands:

```
/plugin marketplace update deepgrade-marketplace
/plugin update deepgrade
/reload-plugins
/plugin list
```

`/plugin list` is the verification step — confirm it reports the version you expect.
**The version in `plugin.json` is the cache key; without a bump, nothing propagates.**

**To turn the guards off immediately**, in order of preference:

1. `/plugin uninstall deepgrade` (or disable it) **followed by `/reload-plugins`**. Verify by
   attempting a guarded command and confirming it is not stopped, and restart the session if
   any handler is still live. Uninstalling alone does not relieve a running session — hook
   commands keep using the previous version's path until `/reload-plugins` runs.
2. Set `DG_DISABLE_GUARDS=1` in the environment **and restart the session**. A process that
   is already running does not observe a newly-set environment variable.

**The `dg-*` temp files are disposable.** The plugin writes them to track state across a
session. A stale-schema file left by a mid-upgrade session is read as zero, and deleting any
`dg-*` temp file is always a safe recovery step.

### Verification scope

Stated plainly so it is not read as more than it is:

- The test suite and the manifest schema are verified **on Windows only**. There is no CI
  matrix yet, so behaviour on Linux and macOS — including runtime hook dispatch — is
  unverified.
- **No minimum Claude Code version is declared.** The plugin relies on hooks-folder-over-
  manifest precedence, exec-form `args`, `${CLAUDE_PLUGIN_ROOT}` substitution and structured
  hook output. All were confirmed on the development host (2.1.216), but the lowest version
  that supports them has not been established by running against it, so no floor is claimed
  rather than implying one that has not been tested.

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
