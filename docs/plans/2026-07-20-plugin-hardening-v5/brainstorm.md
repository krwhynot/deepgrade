# Brainstorm: Plugin Hardening v5

Created: 2026-07-20 (Phase 1)
Source material: structural audit of `toque-plugin` + `troubleshooting-skill` against the
official Claude Code plugin/skill specification (workflow `wf_f737844e-590`, 142 agents,
every finding adversarially verified; 88 raw confirmations → 65 unique findings after merging
cross-auditor duplicates, 4 candidates refuted).

---

## Problem Statement

Toque v4.31.0 passes `claude plugin validate` and installs cleanly, but a layer of
**declaration/execution drift** sits on top of a structurally correct plugin. Components are
registered by frontmatter rather than filename, hooks execute only what is *wired* rather than
what ships, and tools resolve only by exact identifier — so the plugin can validate, install,
and still have whole subsystems that silently never run. Nothing errors; things quietly don't
happen.

Concretely, at the audited commit (`4fb4b64`):

- Two agents register the identical name `report-generator`, so one definition is unreachable
  and an audit command hands its results to the wrong report generator.
- All eight maintained hook implementations in `scripts/` are dead code. The hooks that actually
  run are hand-minified `bash -c` one-liners embedded in `plugin.json`, which have drifted behind
  the scripts: a `SubagentStop` handler that never fires, migration-guard coverage that silently
  narrowed, an audit-staleness nudge that was dropped, and two implementations writing
  incompatible state keys.
- Agents are instructed to write output files, spawn subagents, and consult knowledge skills that
  their own `tools:` allowlists forbid.
- Commands and templates invoke commands and agents that do not exist, and the plugin's
  user-facing documentation describes a version, component count, and update mechanism that do
  not match what ships.

The cost is **false confidence**: a user installs the toolkit, sees safety guards and scanner
agents advertised, and receives materially less than the documentation promises — with no error
to signal the gap.

## Goals

1. **Correctness first.** Every component that the plugin advertises actually loads and executes.
   No duplicate registrations, no unreachable definitions, no instruction an agent is forbidden
   from carrying out.
2. **One source of truth for hooks.** Hook behavior lives in exactly one place, in the documented
   location (`hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` script references), with the drift
   between the scripts and the inline copies resolved deliberately rather than by accident.
3. **No phantom references.** Every command, agent, skill, template, and doc path referenced
   anywhere in the plugin resolves to something that exists after a real install.
4. **Honest self-description.** README, GUIDE, CHANGELOG, and `help` state the shipped version,
   the real component counts, and an update procedure that actually delivers updates.
5. **Resolve the plugin/skill duplication.** The nine troubleshooting technique files that exist
   in both `toque-plugin/docs/troubleshooting-techniques/` and
   `troubleshooting-skill/resources/techniques/` get one canonical source with a defined
   derivation, ending the diverging phase numbering and incompatible KB schemas.
6. **Prove it.** The existing four-layer test suite passes at HEAD and gains assertions that
   would have caught the in-scope defect classes (name collisions, phantom references,
   tool/instruction mismatches).

## Non-Goals

- **Not a feature release.** No new commands, agents, or skills. Scope is conformance and
  correctness only.
- **Not the low/info backlog.** 32 low/info findings (legacy flat `commands/` layout, ~700 KB of
  inert payload shipped to installers, TOCs on long reference files, the `(toque)` description
  prefix, marketplace discovery metadata) are documented in `research/reference-data.json` under
  `backlog` and deliberately deferred.
- **Not a methodology rewrite.** `METHODOLOGY.md` and the planning/troubleshooting technique
  *content* are not being re-authored; only their location, references, and duplication are in
  scope.
- **Not a rename of the marketplace or plugin.** Install identifiers stay stable.

## Open Questions

| # | Question | Why it matters | Resolve in |
|---|----------|----------------|------------|
| 1 | Do the `scripts/tq-*.sh` implementations or the inline `plugin.json` one-liners become the source of truth? | Determines whether the drifted features (SubagentStop, build-verify, audit nudge, wider migration coverage) are restored or dropped. Largest single decision in the plan. | Phase 3 options analysis |
| 2 | Is `plan.md` (F12, 1,529 lines) split into a skill, trimmed in place, or left alone? | Splitting is the spec-idiomatic fix but changes how the flagship workflow is invoked. | Phase 3 options analysis |
| 3 | Which copy of the nine troubleshooting techniques is canonical — plugin `docs/` or the standalone skill? | Sets the direction of the de-duplication and which phase numbering survives. | Phase 3 options analysis |
| 4 | Does v5.0.0 signal breaking changes, and do 4.x users need a migration note? | The chosen name implies a major bump; hook relocation and any command changes are user-visible. | Phase 3 / Phase 4 |
| 5 | Are the MCP-dependent research paths (Ref/Exa/Perplexity) fixed to qualified `mcp__server__tool` names, or removed as unshippable? | The plugin does not bundle these servers; qualified names still won't resolve for users who lack them. Graceful degradation already exists in `mcp-research`. | Phase 3 |
| 6 | Should `disable-model-invocation` be set on side-effectful commands (F14), and which ones count? | Affects whether Claude can auto-trigger gate generation, plan export, and mass artifact generation without the user asking. | Phase 4 |

## Constraints

- **Bootstrapping constraint.** `/toque:plan` (`commands/plan.md`) is simultaneously the tool
  executing this plan and an in-scope defect (F12, plus stale `valid_commands` allowlists).
  Modifying it mid-plan swaps the workflow out from under the work in progress. It must be
  sequenced last, or executed from a pinned copy while being edited.
- **Windows-first host.** Development and verification happen on Windows 11 / Git Bash. Several
  findings (F15 missing `zip`/`python3`/`pdftotext`/`pandoc`, F24 jq-less fallback, F08 Unix-only
  generated hook scripts, non-executable script mode bits) are precisely platform-portability
  defects, so fixes must be validated for both Windows and POSIX rather than only where they were
  authored.
- **Working tree is clean at `4fb4b64` on `main`.** Any change begins from a known-good baseline,
  and the audit's findings are all anchored to that commit.
- **The plugin audits itself.** Changes to agents/skills alter the behavior of the very tools used
  to verify the changes, so verification must lean on the shell-level test suite rather than only
  on agent self-report.

## Ownership

| Role | Name | Notes |
|------|------|-------|
| Plan owner | Kyle (repo owner, `krwhynot`) | Sole maintainer; solo mode likely for the Phase 5 review gate |
| Tech reviewer | **OpenAI Codex (non-Claude model family), per approach.md §10.4** — owner decision 2026-07-29 | The independent-verification control IS the §10.4 model review on Waves 4/6/7 (pinned SHA, committed `reviews/wave-N-round-M.md`, GO + zero unresolved critical/major, max 2 rounds then owner override recorded as a CR and named in release notes). Precedent: 17 rounds on the scope lock, 40/40. **Solo execution with bus factor 1 over the 28–34 day envelope is an owner-accepted risk**, recorded here rather than mitigated |
| Business approver | N/A | Open-source developer toolkit; no business sign-off required |

## Scope Decisions (locked at Phase 1)

| Decision | Choice | Consequence |
|----------|--------|-------------|
| Plan name | `plugin-hardening-v5` | Framed as a release milestone; implies a v5.0.0 bump at handoff |
| Finding depth | Critical + High + Medium (32) | 33 low/info items deferred to a documented backlog |
| Artifact scope | Plugin **and** standalone skill, duplication resolved | Adds F33 (technique-file duplication) to the in-scope set → **33 total** |

## In-Scope Finding Set

33 findings, IDs `F01`–`F33`, with full detail, spec basis, and proposed fix in
[`research/reference-data.json`](research/reference-data.json).

| Severity | Count | Areas |
|----------|-------|-------|
| Critical | 1 | agents |
| High | 5 | agents (2), consistency, hooks, manifest |
| Medium | 26 | commands (7), consistency (6), skills (6), hooks (4), agents (2), manifest (1) |
| Low (scope addition) | 1 | standalone-skill |

Audit provenance: commit `4fb4b64`, plugin v4.31.0, audited 2026-07-19.
