# Make /toque:plan the centerpiece the rest of the toolkit agrees with — Specification

- Derived from: intent.md (Accepted, Kyle, 2026-09-03; amended by CR-001)
- Author: agent draft; human reviewer Kyle
- Status: Draft (revision 2)
- Date: 2026-09-03

## Revision history

**Revision 2 — 2026-09-03.** Rewritten after the design gate returned NOT PASS
(`audit.md`) and CR-001 was ratified. Revision 1 is preserved at commit
`f21f550`. Changes:

| Source | Change |
| --- | --- |
| CR-001 | `/toque:codex-challenge` is deleted, not de-scored. FR-3 and FR-3a **withdrawn** — there is no loop left to converge. Old Phase 2 deleted. |
| audit.md | FR-2's acceptance criterion was unachievable. Rewritten. |
| audit.md | `METHODOLOGY.md` §7 added to scope. It is titled "The Plan Audit Scoring System" and revision 1 cited it as authority for *removing* scoring. |
| audit.md | `10-llm-rubric-calibration.md` (17 lines) added — in no phase table before. |
| audit.md | NFR-4 and the 60-day metric were mutually exclusive. Resolved. |
| audit.md | Expand/Contract described as both applied and not applied in four places. All removed; it is not used. |
| audit.md | E1 cited `plan-auditor.md:60`, a bare tag. Corrected to 61-63. |
| audit.md | E10 was false. Corrected, and the correction is the reason FR-2 changed. |
| audit.md | "three hand-listed paths" — the guard uses two literals plus a glob. |
| root cause | The inventory pattern matched `/40` but not `N/5`. Re-derived with a pattern proven against 7 known-positives and 4 known-negatives first. |

## Requirements

### Functional

**FR-1 (P0) — One verdict currency.** No tool that judges a plan emits a
numeric score, total, or colour band. Judgments are findings with evidence.

- *Given* a plan file, *when* `/toque:quick-audit` runs, *then* its output has
  findings with severity and evidence and no `X/40`, no colour band, no
  scorecard table.
- *Must not:* no tool substitutes a differently-named number for the removed
  score. Removal, not renaming.

**FR-2 (P0) — No stale citations in the live product.** No **shipped** file
claims a rubric, threshold, or `status.json` field the auditor no longer has.

*Revised.* Revision 1 required `score_history` to match nowhere but the guard.
That was unachievable: it legitimately appears in `CHANGELOG.md:105,288` and
`docs/specs/phase5-verifier-gate.md:317,364,502`, which describe past releases
truthfully in the past tense. Rewriting history to satisfy a grep would be the
falsification this project has twice refused.

- *Given* `plugins/toque/**` and `METHODOLOGY.md`, *when* grepped for
  `score_history`, *then* the only match is the guard's own pattern.
- *Given* the same set, *when* read, *then* no file cites a `32+/40` or `36/40`
  plan-auditor threshold.
- *Explicitly excluded, and this is a decision not an oversight:*
  `CHANGELOG.md`, `docs/specs/**`, and `docs/plans/**` are historical records.

**~~FR-3~~ / ~~FR-3a~~ — WITHDRAWN by CR-001.** Convergence and coverage
enforcement for `codex-challenge`. The tool is deleted; there is no loop.

**FR-4 (P0) — The guard covers every file that can violate FR-1.** The
`PH5-051` sweep's subject set is derived, not hand-listed.

*Correction:* revision 1 said "three hand-listed paths". The loop iterates two
literals plus one glob (`stages/*.md`).

- *Given* a new file under `plugins/toque/` containing `X/40` **or `N/5`**,
  *when* the suite runs, *then* Layer 1 fails. The `N/5` case is why revision 1
  failed: the old pattern would not have caught it.
- *Given* the guard, *when* read, *then* its subject set is derived with a floor
  so an empty derivation fails loudly rather than passing vacuously.

**FR-5 (P1) — A small plan can grow up.** `/toque:quick-plan` output can be
promoted into a plan workspace, following `quick-cleanup`'s existing pattern.

- *Given* a spec at `docs/specs/{name}.md` and no plan folder, *when* promotion
  runs, *then* a folder is created with `manifest.md`, `status.json`, and the
  spec placed where Stage 1 reads it.
- *Must not:* never overwrite an existing plan folder silently.

**FR-6 (P1) — Every command states its relationship to the centerpiece**, in one
line, in `/toque:help` and its own description.

**FR-7 (P0) — The repository stays releasable.** `tests/run-all.sh` passes
**7 of 7** layers (was 8; Layer 5 tested the deleted parser) and
`.github/release.sh check` is clean.

### Non-functional

| # | Requirement | Measure |
| --- | --- | --- |
| NFR-1 | No auth surface change | Zero diff touching credentials or permissions |
| NFR-2 | No data-scope change | No new network calls or user-data reads |
| NFR-3 | **Fewer** external dependencies | The Codex CLI dependency is removed with the tool. Nothing added. |
| NFR-4 | Existing plans keep resuming | The two existing plan folders resume without migration |
| NFR-5 | Release discipline | Version, tag, catalog pin only via `.github/release.sh` |
| NFR-6 | Breaking changes documented | A `CHANGELOG.md` entry naming the deleted command and the removed score outputs |

*NFR-4 revised.* Revision 1 froze `status.json` schema 2 outright while the
60-day success metric measured a `status.json` field that did not exist —
mutually exclusive, as the audit found. NFR-4 now requires **resumability**, not
immutability. FR-5 may add an additive, optional field; it may not change or
remove an existing one, and a plan folder written before this change must still
resume.

## Success metrics

| Metric | Target | Window | Method | Evaluated |
| --- | --- | --- | --- | --- |
| In-scope scoring lines | 40 → 0 | At merge | The FR-1/FR-2 greps, enforced by the guard | Merge day |
| Suite layers passing | 7 of 7 | At merge | `tests/run-all.sh` | Merge day |
| Guard catches a planted violation | Yes | At merge | Plant `3/5` in a scratch file; Layer 1 must redden | Merge day |
| Plans promoted from `quick-plan` | ≥1 without rework | 60 days | An additive `promoted_from` field in `status.json` (permitted by revised NFR-4) | 60 days |

*The "codex-challenge runs that terminate" metric is withdrawn with the tool.*

## Scope

**IN** — 40 lines across 12 files, re-derived with a validated pattern:

- Delete `/toque:codex-challenge` entirely (CR-001) and clean 10 referencing files
- `METHODOLOGY.md` §7 — retitle and rewrite; it still describes the scoring system
- `10-llm-rubric-calibration.md` (17 lines) · `02-evaluator-optimizer-loop.md` (2) · `09-multi-category-success-criteria.md` (1)
- `plan-scaffolder.md` (3) · `GUIDE.md` (2) · `quick-plan.md` (2) · `quick-audit.md` (1) · `help.md` (1)
- Two plan fixtures carrying `"score": 36, "rating": "GREEN"` and `"score": 28, "rating": "YELLOW"`
- Widen the `PH5-051` guard; add the promotion path and relationship labels

**OUT** — and each exclusion is reasoned, not assumed:

- **`METHODOLOGY.md` outside §7 (26 lines).** The readiness scan's letter grades.
  A different product, one being split to its own repository, which legitimately
  grades codebases. Stripping these would break a working feature.
- **`readability-score.sample.json` (1).** A readiness category score.
- **`wave5-guards.py:315` (1).** "BASELINE NOT GREEN" describes suite state, not
  a plan verdict. An unrelated sense of the word.
- `CHANGELOG.md`, `docs/specs/**`, `docs/plans/**` — historical records (FR-2).
- The `ai-scan` split; the design gate's own design; the readiness and audit
  plugins; publishing anything.

## Design

### Options analysis — superseded

Revision 1 compared four options for replacing `codex-challenge`'s score-driven
loop and chose findings-with-per-dimension-verdicts. **CR-001 supersedes all
four**: the tool is deleted, so there is no loop to redesign.

The analysis is retained at commit `f21f550` rather than deleted, because the
reasoning that produced it — and the Codex review that found a correctness hole
in it — is why deletion became the answer. Deleting a tool is not the same
decision as failing to design one.

*Would revisit if:* someone wants adversarial cross-model review back. That is a
new intent, not a revival of this design. CR-001 names the lost capability.

### Approach

**Deletion first, then cleanup, then the guard.** No staging pattern, no
Expand/Contract — there is no contract left to migrate, and the audit was right
that it was ceremony even when there was.

Ordering is forced by one constraint: **the guard lands last**. Widening
`PH5-051` before the scoring is gone reddens Layer 1 and leaves the repo
unreleasable between phases. That was revision 1's headline defect, and it was
caused by an inventory that missed eight sites, not by the ordering rule itself.

### Dependencies

- **Internal, hard:** `tests/layer1-repo.sh` (the guard), `tests/run-all.sh`
  (loses Layer 5), the ten files referencing the deleted tool.
- **External:** none after Phase 1. The Codex CLI dependency leaves with the tool.

## Standards applied

- The project's own no-score decision (8.0.0), extended from the gate path to
  the whole plugin. `METHODOLOGY.md` §7 is in scope precisely because it is the
  document that still contradicts it.
- Instrument self-test before measurement: any pattern used to derive an
  inventory is first proven against known-positives and known-negatives. This
  is the repo's own practice, applied after revision 1 failed for want of it.
- No brand, accessibility, or compliance standard applies.

## Gotchas

| # | Risk | Impact | Mitigation |
| --- | --- | --- | --- |
| 1 | Deleting a command breaks a user's muscle memory or a script that invokes it | MEDIUM | Major version and a `CHANGELOG.md` entry naming the removal. Nothing else can call it — the sweep found no programmatic caller. |
| 2 | Reference cleanup misses a file and `/toque:help` advertises a command that no longer exists | MEDIUM | A grep for `codex-challenge` returning only historical records is a Phase 1 exit condition, and Layer 1 already fails on a command reference that does not resolve. |
| 3 | `METHODOLOGY.md` §7 is a 227-line section, not a line edit. Rewriting it can introduce new claims that are themselves unverified. | MEDIUM | The rewrite describes what the gate does **now**, and every claim in it is checkable against `plan-auditor.md` and `tests/layer1-repo.sh`. No forward-looking statements. |
| 4 | The suite drops to 7 layers. A future reader may read the gap as an accident. | LOW | `run-all.sh`'s layer list is renumbered rather than left with a hole, and the CHANGELOG says why. |

**Withdrawn with CR-001:** the lazy-reviewer risk and the three-copies-of-the-wire-format risk.

## Evidence

Internal coherence change. External research skipped deliberately — no outside
source can say whether these tools should agree with each other.

| # | Claim | Evidence | Verified |
| --- | --- | --- | --- |
| E1 | The gate has no score; the 8 dimensions are lenses only | `plan-auditor.md:61-63` — *"They are lenses for finding gaps and locating evidence, not things to be rated"* | Read. **Corrected**: revision 1 cited line 60, which is the bare tag `<review_dimensions>`. |
| E2 | The guard's subject set is two literals plus a glob | `tests/layer1-repo.sh:855-858` | Read. **Corrected** from "three hand-listed paths". |
| E3 | `quick-audit` emits `X/40` and a colour band | `commands/quick-audit.md:59-60` | Read |
| E10 | `score_history` is documented but never written | `GUIDE.md:265`; 7 pre-existing occurrences repo-wide | Read. **Corrected**: revision 1 claimed exactly two. The grep covered three subtrees and was reported as the whole repo. This error made FR-2 unachievable and is why FR-2 changed. |
| E14 | `METHODOLOGY.md` §7 contradicts the decision it is cited for | `METHODOLOGY.md:1031` — *"## 7. The Plan Audit Scoring System"*; `:1037` — *"you get a numeric score across 8 dimensions"* | Read |
| E15 | The old inventory pattern missed `N/5` | `round-loop.md`: 4 `/40` hits found, 4 `N/5` missed | Run |
| E16 | The new pattern is proven | 11-assertion self-test, 7 positives and 4 negatives incl. the `REQUIRED`/`RED` trap, all passing before any count | Run |
| E17 | Deletion removes 46 of 114 in-scope lines | Inventory diff before and after excluding `codex-challenge` | Run |

**Known weaknesses**

- E17's in/out split for four test fixtures is judgment. Two carry plan-audit
  scores and are IN; two belong to the readiness product and are OUT. Documented
  in Scope so the reasoning is reviewable.
- Three pattern errors were made deriving this inventory — too broad, too narrow,
  and a tool mismatch where `awk` does not treat `\b` as a word boundary. Only
  the last derivation was self-tested first. Recorded because the same class of
  error is the most likely way this spec is still wrong.

## Open questions

1. **Does `METHODOLOGY.md` §7 get rewritten or removed?** It is the methodology
   document's account of plan auditing. With scoring gone it needs a new title
   and body, but the gap-detection and evidence content is still accurate.
   *Owner: Kyle. Blocks Phase 2.*
2. **Round cap / relationship-line wording.** Cosmetic. *Owner: agent.*

## Verification plan

| # | Deliverable | Methodology | Why |
| --- | --- | --- | --- |
| D1 | Delete `codex-challenge` + clean 10 references | **TDD** | The assertion is absence: a grep must return only historical records, and the suite must be green at 7 layers. |
| D2 | Stale citations, `score_history`, §7, rubric-calibration doc | **TDD** | Absence assertions again. |
| D3 | `quick-audit` scoring + two fixtures | **TDD** | Same shape. |
| D4 | Widen the `PH5-051` guard | **Mutation testing** | A guard that cannot fail is worse than none. Plant `3/5` — the case revision 1 missed — and confirm Layer 1 reddens. |
| D5 | `quick-plan` promotion path | **BDD** | Acceptance criteria already Given/When/Then in FR-5. |
| D6 | Relationship lines | **Snapshot / approval** | Rendered help text; review once by eye. |

**AI-specific.** Separate test authorship applies to D4: the pass that widens the
guard does not write the mutation proving it bites. Tautological tests remain the
named risk — an absence assertion that greps the same pattern the fix used proves
only that the fix ran, so D1-D3 assert against **independently written** expected
file lists.

**Two-tier split for Stage 4.** *Tier 1, automated:* suite 7/7, preflight clean,
FR-1/FR-2 greps empty, D4 mutation reddens Layer 1. *Tier 2, human:* read the
rendered `/toque:help` once; promote one real `quick-plan` spec; confirm no
plugin file still references the deleted command.

## Delivery

Five phases. The suite is green at every boundary, and the guard lands last.

| Phase | Risk | Est. | Depends on |
| --- | --- | --- | --- |
| 1 — Delete `codex-challenge` | MEDIUM | 1 | — |
| 2 — Citations, `score_history`, §7, rubric doc | LOW | 1 | — |
| 3 — `quick-audit` + fixtures | LOW | 0.5 | — |
| 4 — Widen the guard | LOW | 0.5 | 1, 2, 3 |
| 5 — Promotion path + labels | LOW | 1 | — |

No phase is HIGH risk. Revision 1's only HIGH phase was the Codex contract, and
CR-001 deleted it.

**Phase 1.** Delete the five skill files, the 447-line test, the seven fixtures.
Renumber `run-all.sh` to 7 layers. Clean ten referencing files. *Exit:* grep for
`codex-challenge` returns only `CHANGELOG.md`, `docs/specs/**`, `docs/plans/**`;
suite 7/7.

**Phase 2.** The four stale citations, `GUIDE.md:265`'s phantom field,
`METHODOLOGY.md` §7 (pending OQ1), and the three planning-technique docs.
*Exit:* FR-2's greps empty over `plugins/toque/**` and `METHODOLOGY.md`.

**Phase 3.** `quick-audit.md:59-60` and its front matter; the two plan fixtures.
*Exit:* no scorecard, no band.

**Phase 4.** Derived subject set with a floor, pattern covering `/40` **and**
`N/5`. *Exit:* the mutation reddens Layer 1, and removing it greens again.

**Phase 5.** Promotion following `quick-cleanup:7-25`; one relationship line per
command. *Exit:* a real promotion completes; help text approved.

### Go / no-go

| Boundary | Go requires | No-go |
| --- | --- | --- |
| 1 → 4 | Suite 7/7; no dangling references | Fix forward; deletion is reversible by revert |
| 2 → 4 | FR-2 greps empty | **Stop if §7's rewrite introduces unverifiable claims** |
| 3 → 4 | Suite 7/7 | Fix forward |
| 4 → 5 | Mutation proves the guard bites | **Stop.** A guard that cannot fail is worse than none |
| 5 → Stage 4 | Suite 7/7; preflight clean | Fix forward |

### Release

Breaking: a command is removed and two commands stop emitting scores. Major
version, `CHANGELOG.md` entry naming both, released only through
`.github/release.sh`.
