# Cross-Plugin Interop Contracts

The three plugins exchange artifacts through the repository they are installed
into. SPLIT-3 proves that namespaced *references* resolve; this file is the
contract for the *artifacts* those plugins hand each other — who writes a file,
who reads it, and which fields are load-bearing. The INTEROP section of
`tests/layer1-repo.sh` parses the table below and verifies every row against
the tree, in both directions: an edge that exists in the tree but not here
fails, and a row here that the tree no longer backs fails.

## Contract table

Format rules (the sweep depends on them):

- One row per artifact. Column 1 is the repo-relative artifact path.
- Column 2 is the single producer file, as a repo-relative path.
- Column 3 is every cross-plugin consumer file, comma-separated,
  repo-relative. "Cross-plugin" means the consumer lives in a different
  `plugins/<name>/` directory than the producer.
- Only functional files count — `commands/`, `agents/`, `skills/`, `scripts/`
  under each plugin. README/GUIDE mentions are description, not consumption,
  and are not listed or swept.

| Artifact | Producer | Consumers |
| -------- | -------- | --------- |
| docs/audit/readability/readability-score.json | plugins/deepgrade-readiness/commands/readiness-scan.md | plugins/deepgrade-audit/agents/gate-generator.md, plugins/deepgrade-audit/agents/delta-scanner.md, plugins/deepgrade-audit/commands/codebase-delta.md |
| docs/audit/readability/readability-report.md | plugins/deepgrade-readiness/agents/readiness-report-generator.md | plugins/deepgrade-audit/commands/codebase-audit.md, plugins/deepgrade-audit/agents/delta-scanner.md, plugins/deepgrade/skills/documentation/references/spec-template.md |
| docs/audit/deepgrade-report.md | plugins/deepgrade-audit/agents/deepgrade-report-generator.md | plugins/deepgrade/scripts/dg-session-start.js |
| docs/audit/risk-assessment.md | plugins/deepgrade-audit/agents/risk-assessor.md | plugins/deepgrade/agents/plan-scaffolder.md, plugins/deepgrade/agents/plan-auditor.md, plugins/deepgrade/commands/quick-plan.md, plugins/deepgrade/skills/documentation/SKILL.md, plugins/deepgrade/skills/documentation/references/spec-template.md |
| docs/audit/dependency-map.md | plugins/deepgrade-audit/agents/dependency-mapper.md | plugins/deepgrade/agents/plan-scaffolder.md, plugins/deepgrade/agents/plan-auditor.md, plugins/deepgrade/commands/quick-plan.md, plugins/deepgrade/skills/plan/stages/stage-3-build.md, plugins/deepgrade/skills/documentation/references/spec-template.md |
| docs/audit/feature-inventory.md | plugins/deepgrade-audit/agents/feature-scanner.md | plugins/deepgrade/commands/quick-plan.md, plugins/deepgrade/skills/documentation/SKILL.md, plugins/deepgrade/skills/documentation/references/spec-template.md |
| docs/audit/integration-scan.md | plugins/deepgrade-audit/agents/integration-scanner.md | plugins/deepgrade/agents/plan-auditor.md, plugins/deepgrade/commands/quick-plan.md, plugins/deepgrade/skills/plan/stages/stage-3-build.md, plugins/deepgrade/skills/documentation/references/spec-template.md |
| docs/audit/audit-progress.md | plugins/deepgrade-audit/commands/codebase-audit.md | plugins/deepgrade-readiness/agents/baseline-scanner.md |

## The readability-score.json schema

The producer's schema lives in
`plugins/deepgrade-readiness/commands/readiness-scan.md` (the fenced block
after "must follow this schema"). The canonical valid instance is
`tests/fixtures/interop/readability-score.sample.json`; the INTEROP sweep
verifies the fixture parses, carries every load-bearing key, and agrees with
the schema block's top-level key set.

Load-bearing keys — fields a cross-plugin consumer actually extracts:

- `timestamp` — deepgrade-audit's delta-scanner greps it for scan age.
- `overall.score`, `overall.grade` — gate-generator and codebase-delta read
  the current score and grade.
- `categories.*` — all nine category keys (manifest, context_files,
  structure, entry_points, conventions, feedback_loops, baseline,
  context_budget, database); database additionally carries `status`
  ("applicable" or "not_applicable") because category 9 is conditional.
- `checks[]` elements carry `id`, `name`, `status`, `points`, `max` —
  readiness-generate and delta tracking address checks by id and score them
  by points against max. The `points`/`max` spelling is RATIFIED from
  observed output (2026-08-03 dogfood run): the templates originally said
  `score`/`max_score`, all eight live scanners emitted `points`/`max`
  unanimously, and the templates were aligned to reality rather than the
  reverse. The retired vocabulary is banned by the sweep.

The fixture is DERIVED from a real scan (2026-08-03, hono@main shallow
clone), sanitized and trimmed to two representative check elements — not
authored from this file or the templates. A fixture written from the docs
reproduced the documented shape instead of the actual one and hid the
vocabulary drift above; provenance from a live artifact is what makes it a
known-positive. One observed key was deliberately NOT ratified: a top-level
`weight_set` appeared in the live artifact but in no template or schema and
has no consumer; it stays out of the contract. The per-check `confidence` field the templates
originally requested was RESOLVED the same way (2026-08-03): recon showed it
had no consumer anywhere — the report generator never reads it, and the
methodology's "confidence levels" are a different, module-level concept the
orchestrator derives from gate results, not from a checks[] field. The dead
field is removed from the templates; module-level confidence is untouched.

## Deliberate non-edges

- **Session markers (`$TMPDIR/dg-*`) no longer exist.** The marker bus shipped
  inside deepgrade-guard and was retired with it in 9.0.0. Layer 1's per-plugin
  core fails any plugin that grows a marker surface, so the bus cannot come
  back by accident.
- **Plan folders (`docs/plans/{date}-{name}/`) are deepgrade-internal.**
  Written by the planning commands and deepgrade's own hooks
  (dg-subagent-stop appends `subagent-log.txt` there); no other plugin reads
  or writes them.
- **Single-plugin artifacts are not contracts.** Files under `docs/audit/`
  referenced by only one plugin (documentation-audit.md, security-scan.md,
  gate-config.md, kpi-dashboard.md, delta-report.md, plan-audit.md,
  characterization-tests.md, override-log.md) may be renamed freely with
  their plugin; the sweep derives the cross-plugin set rather than trusting
  this list.
- **`docs/audit/readiness-report.md`** appears in codebase-audit.md only as
  a legacy fallback location ("or ...") for pre-split readiness reports;
  nothing produces it today. It is deliberately not a contract row.

## Change protocol

Renaming or moving a contracted artifact touches, in ONE commit: the
producer, every consumer in its row, and this table. The INTEROP sweep fails
on any partial version of that commit, in whichever direction the drift
points. Fields consumed from readability-score.json change the same way:
producer schema block, consumer extraction, fixture, and this file together.
