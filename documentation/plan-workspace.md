# The plan workspace

Every plan lives in one folder. This page is the reference for what is in it,
what tracks progress, and how resuming and staleness work.

Companion to [The plan workflow](./the-plan-workflow.md), which covers the six
stages themselves.

---

## The folder is the homebase

```
docs/plans/YYYY-MM-DD-{plan-name}/
  manifest.md          human-readable index linking to every related file
  status.json          machine-readable progress, timestamps, resume state
  intent.md            Stage 1 — problem, outcome, affected systems, constraints
  research/            Stage 1 — the three research tracks
    findings.md          combined summary
    reference-data.json  structured facts
    codebase-scan.md     track 1 output
    best-practices.md    track 3 output
    intake/              track 2 — cleaned source docs
  spec.md              Stage 2 — requirements, design, evidence, verification, delivery
  audit.md             Stage 2 gate — criterion verdicts, canary and evidence results
  evidence/            Stage 2 gate — one record per criterion, committed with audit.md
  .canary/             Stage 2 gate — the mutated working copy (NOT committed)
  plan.md              Stage 3 — files that change, order, risks, proof, verification
  changes/             Stage 3 — immutable change records, CR-001, CR-002, ...
  impact-review.md     Stage 3 exit — cross-cutting findings, integration edges
  test-plan.md         Stage 4 — test matrix, two-tier verification
  review.md            Stage 5 — diff-versus-plan, findings, release checklist
  troubleshooting/     Stage 6 — incident logs linked to this plan
```

Artifacts are named the way the underlying playbook names them, so a reader can
follow the chain from intent to release **without leaving the folder**.

### What is committed

Everything except `.canary/` — the mutated spec copy the design gate works
against — and the plan export zip.

Two artifacts land outside the folder, in standard project locations, and are
linked from `manifest.md`:

| Document | Location |
| --- | --- |
| ADRs created during design | `docs/adr/ADR-{topic}.md` |
| PRDs created during design | `docs/prd/{feature}.md` |

---

## manifest.md — the human index

A table per category — artifacts, project documents, change records, codebase
files — each row carrying a status and a date.

**It is updated at every stage.** When any stage creates or links a document,
both `manifest.md` and `status.json` are updated together. A manifest that has
drifted from the folder is a bug, not a cosmetic issue: it is what a reviewer
reads instead of the folder.

---

## status.json — the machine state

Schema 2. The shape:

```json
{
  "schema_version": 2,
  "plan_name": "{name}",
  "plan_dir": "docs/plans/{date}-{name}",
  "created": "{ISO}",
  "current_phase": "design",
  "documents": {},
  "phases": {
    "plan":     { "status": "complete", "started": "...", "completed": "...",
                  "accepted_by": "...", "accepted_date": "..." },
    "design":   { "status": "in_progress", "started": "..." },
    "build":    { "status": "not_started" },
    "test":     { "status": "not_started" },
    "deploy":   { "status": "not_started" },
    "maintain": { "status": "not_started" }
  }
}
```

### The timestamps are the metrics

Every stage records `started` and `completed` in ISO format when its status
changes. Those pairs are what produce the numbers worth tracking:
**intent-to-spec**, **spec-to-plan**, and **plan-to-release** elapsed time.

`/toque:plan-status` reads them.

### Gate bookkeeping

Every time a gate passes, five things happen together:

1. The stage's `completed` timestamp is set.
2. The next stage goes to `in_progress` with its `started` timestamp.
3. `current_phase` moves.
4. The approver is recorded — `accepted_by`, `approved_by`, or `authorized_by`
   — with a date.
5. `manifest.md` is updated to match.

> A gate without a recorded name is not passed.

---

## Resuming

`/toque:plan {name}` against an existing folder reads `status.json`, finds the
current stage, checks the freshness of everything already complete, and reports
before offering to continue:

```
Plan: {name}
Current stage: {stage} ({status})
Last updated: {date}
Intent -> spec: {elapsed}   Spec -> plan: {pending}

[artifact table from manifest.md]

Continue from {stage}?
```

### Recovering a broken workspace

| Failure | Recovery |
| --- | --- |
| `status.json` corrupted | Rebuilt from the files present in the plan folder |
| Stage partially complete | Saved to `status.json`, resumable |
| A plan folder already exists | Asks: resume it, or create `{name}-2`? |
| Referenced files deleted | Findings marked STALE, re-research suggested |
| Source folder unreadable | Doc cleanup skipped, continues with codebase and web |
| No external search tools | Track 3 skipped, output tagged as unavailable |
| Gate approver not named | Does not advance; asks for the name |

---

## Staleness

Freshness is tracked by **path-scoped fingerprinting** — each stage records
hashes of only the files it actually referenced, not a whole-repo SHA. A commit
elsewhere in the repo does not invalidate a plan.

Three levels:

| Level | Meaning |
| --- | --- |
| **FRESH** | Referenced files unchanged since the stage completed |
| **WARNING** | Related files in the same directory changed — findings may be affected |
| **STALE** | Directly referenced files changed — findings likely invalid |

### The invalidation cascade

Changing an artifact after its gate has consequences downstream:

| Change | Effect |
| --- | --- |
| `intent.md` changes after acceptance | `spec.md` becomes STALE, **and the change is a Change Record** |
| `spec.md` changes after approval | `audit.md` and `plan.md` become STALE |
| `plan.md` changes after approval | Recorded under "Departures from plan" in the same commit; Stage 5's diff check reads it |
| Source docs change after research | Research drops to WARNING |

That first row is the one to internalize. Editing an accepted intent is not a
free correction — the workflow treats intent edits after the first spec commit
as a measurable event, because that is where scope creep originates.

---

## Migrating a pre-8.0.0 plan

Plans started before 8.0.0 use schema 1, with different phase names. On resume,
they are migrated **before anything else happens**, then written back as
schema 2 with every other field preserved.

| Old phase (schema 1) | New stage (schema 2) |
| --- | --- |
| brainstorm, research | plan |
| pre_plan, plan, audit | design |
| build, impact_review | build |
| test | test |
| handoff | deploy |

Status is derived in a fixed order: any old status whose text ends in `complete`
counts as complete; every mapped phase complete makes the stage complete; any
mapped phase complete or in progress makes the stage in progress; otherwise not
started.

Two deliberate choices in that migration are worth knowing:

- **Nothing is thrown away.** The entire old `phases` object is kept verbatim
  under `phases_schema1`, including keys the table does not name, alongside a
  `schema1_migration` block recording the date and the old `current_phase`.
- **Old artifacts keep their old names.** Files like `brainstorm.md`,
  `approach.md`, and `confidence.md` are read where a stage asks for `intent.md`
  or `spec.md`, and the resume summary says so. They are not rewritten.

If a later stage is complete while an earlier one is not — a plan closed by
decision rather than by sequence — the summary says that rather than inventing
progress.

---

## Related

- [The plan workflow](./the-plan-workflow.md) — the six stages in depth
- [The design gate](./the-design-gate.md) — what `audit.md` and `evidence/` contain
