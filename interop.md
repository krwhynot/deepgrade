# Cross-Repository Interop Contracts

Toque reads files it does not write. The audit and readiness scanners that
produce them moved to the [ai-scan](https://github.com/krwhynot/ai-scan)
repository in 11.0.0; before that they were sibling plugins here and the same
contracts were enforceable in one tree.

They are not any more, and that is the important thing about this file. Half of
every contract below now lives in a repository this test suite cannot see. What
was a two-sided guard is a one-sided one: the sweep in `tests/layer1-repo.sh`
verifies that every consumer named here exists and still reads the artifact it
claims to, and that no toque file reads an undocumented `docs/audit/` path. It
cannot verify that anything still writes them.

**So a green suite no longer means the contract holds.** It means Toque's half
holds. A rename on the producer side lands here as a feature that quietly stops
finding its input — no error, just a plan generated without risk data. That is
the cost of the split, recorded rather than papered over.

## What Toque does when an artifact is absent

Every consumer below degrades rather than fails. Toque works on a repository
that has never been scanned; the artifacts make its output better-informed, and
none is a dependency. This is why the split was survivable at all.

## Contract table

Format rules (the sweep depends on them):

- One row per artifact. Column 1 is the repo-relative artifact path, as it
  appears in the *consuming* repository at runtime.
- Column 2 is the producer, written `<repo>:<path>`. It is documentation, not
  a checkable claim — nothing in this repository can resolve it.
- Column 3 is every Toque consumer file, comma-separated, repo-relative.
- Only functional files count — `commands/`, `agents/`, `skills/`, `scripts/`.
  README/GUIDE mentions are description, not consumption, and are not swept.

| Artifact | Producer | Consumers |
| -------- | -------- | --------- |
| docs/audit/risk-assessment.md | ai-scan:plugins/ai-scan-audit/agents/risk-assessor.md | plugins/toque/agents/plan-auditor.md, plugins/toque/agents/plan-scaffolder.md, plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/SKILL.md, plugins/toque/skills/documentation/references/spec-template.md |
| docs/audit/dependency-map.md | ai-scan:plugins/ai-scan-audit/agents/dependency-mapper.md | plugins/toque/agents/plan-auditor.md, plugins/toque/agents/plan-scaffolder.md, plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/references/spec-template.md, plugins/toque/skills/plan/stages/stage-3-build.md |
| docs/audit/integration-scan.md | ai-scan:plugins/ai-scan-audit/agents/integration-scanner.md | plugins/toque/agents/plan-auditor.md, plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/references/spec-template.md, plugins/toque/skills/plan/stages/stage-3-build.md |
| docs/audit/feature-inventory.md | ai-scan:plugins/ai-scan-audit/agents/feature-scanner.md | plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/SKILL.md, plugins/toque/skills/documentation/references/spec-template.md |
| docs/audit/readability/readability-report.md | ai-scan:plugins/ai-scan/agents/readiness-report-generator.md | plugins/toque/skills/documentation/references/spec-template.md |
| docs/audit/baseline/feature-inventory.json | ai-scan:plugins/ai-scan-audit/agents/feature-scanner.md | plugins/toque/skills/documentation/references/adr-template.md, plugins/toque/skills/documentation/references/brd-template.md, plugins/toque/skills/documentation/references/prd-template.md |
| docs/audit/baseline/dependency-map.json | ai-scan:plugins/ai-scan-audit/agents/dependency-mapper.md | plugins/toque/skills/documentation/references/adr-template.md, plugins/toque/skills/documentation/references/readme-template.md |
| docs/audit/baseline/risk-assessment.json | ai-scan:plugins/ai-scan-audit/agents/risk-assessor.md | plugins/toque/skills/documentation/references/adr-template.md |
| docs/audit/baseline/integration-map.json | ai-scan:plugins/ai-scan-audit/agents/integration-scanner.md | plugins/toque/skills/documentation/references/adr-template.md |
| docs/audit/ai-scan-report.md | ai-scan:plugins/ai-scan-audit/agents/ai-scan-report-generator.md | plugins/toque/scripts/tq-session-start.js |
| docs/audit/toque-report.md | ai-scan:plugins/ai-scan-audit/agents/ai-scan-report-generator.md | plugins/toque/scripts/tq-session-start.js |

The last two rows are one artifact under two names. ai-scan writes
`ai-scan-report.md`; every repository audited before 11.0.0 has
`toque-report.md` on disk instead, and nothing rewrites it. `tq-session-start.js`
stats both and uses whichever is newer, so a session in an older repository
still gets its stale-audit warning. Neither row may be deleted until the legacy
name is genuinely extinct, which is not observable from here.

## Toque-internal paths under docs/audit/

These live under the same directory but are Toque's own and cross no boundary.
The sweep knows about them, so adding one does not need a contract row — but it
does need to be listed here, or the sweep reports it as undocumented.

- `docs/audit/plan-audit.md` — written by the design gate. `quick-audit.md`
  explicitly refuses to create it, which is why it appears in two files while
  crossing nothing.

## Deliberate non-edges

- **`readability-score.json` is no longer a Toque contract.** It was the one
  machine-read artifact, and its consumers (gate-generator, delta-scanner,
  codebase-delta) all moved to ai-scan. Toque never read it. The schema, its
  ratified `points`/`max` vocabulary, and the fixture derived from the
  2026-08-03 dogfood run travel with the producer; they are documented in
  ai-scan's own interop file, and this repository no longer asserts anything
  about them.
- **`docs/audit/audit-progress.md` is now ai-scan-internal.** Both its producer
  and its consumer were audit-side.
- **Session markers (`$TMPDIR/tq-*`) no longer exist.** The marker bus shipped
  inside toque-guard and was retired with it in 9.0.0. Layer 1's per-plugin core
  fails any plugin that grows a marker surface, so the bus cannot come back by
  accident.
- **Plan folders (`docs/plans/{date}-{name}/`) are Toque-internal.** Written by
  the planning commands and Toque's own hooks (`tq-subagent-stop` appends
  `subagent-log.txt` there); nothing outside Toque reads or writes them.
- **`docs/audit/readiness-report.md`** was a legacy fallback location for
  pre-split readiness reports. Nothing in this repository references it.

## Change protocol

Renaming or moving a contracted artifact now takes a commit in each repository,
and they cannot be atomic. Ship the consumer side first: teach Toque to accept
both names, release, then rename in ai-scan, then remove the old name here once
no installed repository still carries it. The two report rows above are that
protocol mid-flight — the reason both names are listed is that the last step has
not been reached and cannot be scheduled from this side.

Within this repository the sweep still fails on a partial change: a consumer
that stops reading its artifact, a consumer path that no longer exists, or a
`docs/audit/` path read by a Toque file with no row here and no entry in the
internal list.
