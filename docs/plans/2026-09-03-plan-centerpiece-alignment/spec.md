# Make /toque:plan the centerpiece the rest of the toolkit agrees with — Specification

- Derived from: intent.md (Accepted, Kyle, 2026-09-03; amended by CR-001)
- Author: agent draft; human reviewer Kyle
- Status: Draft (revision 3)
- Date: 2026-09-03

## Revision history

**Revision 3 — 2026-09-03.** Rewritten after the design gate returned NOT PASS a
second time and CR-002 was ratified. Revision 2 is at commit `38e55ad`.

The second audit's finding was about method: *"the instrument is asserted, not
shipped."* Revision 2's inventory was a claim. CR-002 inverts the plan so the
inventory is an artifact the repository produces.

| Source | Change |
| --- | --- |
| CR-002 | Scope no longer states a hand-counted table. It cites `inventory.txt`, the committed output of `tools/scoring-sweep.sh`. |
| CR-002 | Phase order inverted: instrument first (report mode), enumerate, fix, then flip to enforce. |
| CR-002 | FR-2 restated as **zero matches in scope**. Its revision-2 form was unsatisfiable — it required the only match to be a guard living outside the scoped set. |
| CR-002 | FR-4 restated: two modes, derived subject set, self-tested exclusions. |
| CR-002 | NFR-4's relaxation of `intent.md:70-71` authorised retroactively — revision 2 changed a constraint inside the spec instead of in a change record. |
| audit-2 | intent OQ4 answered: `/toque:documentation` is part of the workflow **and** standalone. |
| audit-2 | `10-llm-rubric-calibration.md` reclassified from a 17-line edit to a rewrite-or-retire decision. |
| audit-2 | `confidence.md` written; its absence failed LINT-19 and LINT-20. |
| audit-2 | S14 rollback flaw dissolved by report mode, not patched. |


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

*Restated again by CR-002.* Revision 2's form was unsatisfiable in a new way: it
required the only `score_history` match in `plugins/toque/**` + `METHODOLOGY.md`
to be "the guard's own pattern", but the guard lives at `tests/layer1-repo.sh`,
outside that set. A criterion that names an impossible witness can never be met.

- *Given* `tools/scoring-sweep.sh` in enforce mode, *when* run, *then* it
  reports **zero** violations and exits 0.
- *Explicitly excluded by the instrument's own exclusion list, each with a
  reason the self-test covers:* `CHANGELOG.md`, `docs/specs/**`,
  `docs/plans/**` (historical records, true in the past tense);
  `METHODOLOGY.md` outside §7, `*readability-score*`, `*readiness*`
  (the readiness product's letter grades, a different product);
  `tests/mutation/*` ("BASELINE NOT GREEN" is suite state);
  the guard and the sweep themselves (they are the instrument, not defects).

**~~FR-3~~ / ~~FR-3a~~ — WITHDRAWN by CR-001.** Convergence and coverage
enforcement for `codex-challenge`. The tool is deleted; there is no loop.

**FR-4 (P0) — The guard covers every file that can violate FR-1.** The
`PH5-051` sweep's subject set is derived, not hand-listed.

*Correction:* revision 1 said "three hand-listed paths". The loop iterates two
literals plus one glob (`stages/*.md`).

*Restated by CR-002.* The guard has **two modes**, and that is what makes it
safe to build first:

- **report** — enumerates violations, exits 0. Ships before the fixes, so the
  suite stays green while violations still exist.
- **enforce** — exits 1 on any violation. The final commit flips to this.

- *Given* a new file under `plugins/toque/` containing `X/40`, `N/5`, or a
  colour band, *when* the suite runs in enforce mode, *then* Layer 1 fails. All
  three forms are in the self-test because all three were missed by hand.
- *Given* the guard, *when* run, *then* its self-test executes **first** and a
  failure reports nothing about the tree — an unproven instrument producing a
  confident number is the failure this replaces.
- *Given* the guard, *when* read, *then* its subject set is derived and its
  exclusions are self-tested, not asserted in a comment.

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
| Violations reported by the instrument | 39 → 0 | At merge | `tools/scoring-sweep.sh enforce` exits 0 | Merge day |
| Suite layers passing | 7 of 7 | At merge | `tests/run-all.sh` | Merge day |
| Guard catches a planted violation | Yes | At merge | Plant `3/5` **and** `X/40` in a scratch file; Layer 1 must redden on each | Merge day |
| Instrument self-test | 20/20 | Every run | The sweep runs it before counting; failure suppresses all output | Continuous |
| Plans promoted from `quick-plan` | ≥1 without rework | 60 days | An additive `promoted_from` field in `status.json` (permitted by revised NFR-4) | 60 days |

*The "codex-challenge runs that terminate" metric is withdrawn with the tool.*

*The "40 → 0" target is withdrawn by CR-002 — 40 was the unfalsifiable
hand-count. The figure above is the instrument's, and the instrument is the
measurement method rather than a claim about one.*

## Scope

**IN** — defined by `inventory.txt`, the committed output of
`tools/scoring-sweep.sh`. Re-derive it by running the script; do not read a
number here and trust it.

```
deleted by CR-001 :  49 lines /  7 files
remaining to fix  :  39 lines / 11 files
instrument total  :  88 lines / 18 files
```

Against hand-counts of 31/10 (revision 1) and 40/12 (revision 2). The value is
not the figure but that anyone can reproduce it. Summarised:

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

1. **`10-llm-rubric-calibration.md` — rewrite or retire?** The load-bearing one,
   and the reason it is now first. Revision 2 booked it as a 17-line edit. It is
   a **157-line document whose thesis is that plan scoring should be made
   consistent via 1-5 rubrics.** Strip 17 lines and 140 remain arguing for
   exactly what FR-1 abolishes.

   - *Rewrite* — keep the calibration reasoning, recast it for verdicts and
     evidence rather than rubrics. Preserves genuinely useful content about
     inter-rater consistency; a substantial writing job.
   - *Retire* — delete it. Its subject no longer exists in the product.

   Revision 2 applied "this is a rewrite, not a line edit" to METHODOLOGY §7 and
   failed to apply it here. Audit-2 caught that.
   **Owner: Kyle. Blocks Phase 5.**

2. **Does `METHODOLOGY.md` §7 get rewritten or removed?** 227 lines. The
   gap-detection and evidence content is still accurate; only the scoring frame
   is dead. Leaning rewrite, but the same question as OQ1 and it should get the
   same answer for the same reason. *Owner: Kyle. Blocks Phase 3.*

3. ~~**`/toque:documentation` — part of the centerpiece or standalone?**~~
   **ANSWERED by CR-002.** Both. It writes Stage 2 ADRs and the Stage 5 runbook,
   and is usable alone. Its FR-6 relationship line says exactly that. This was
   `intent.md` OQ4, marked "deferred to design" and then absent from the design
   until audit-2 found the hole.

4. **Relationship-line wording.** Cosmetic. *Owner: agent.*

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

**Inverted by CR-002.** The instrument is built first and ships in report mode;
its output defines the work; enforce mode is the last commit.

| Phase | What | Risk | State |
| --- | --- | --- | --- |
| 0 | Build `tools/scoring-sweep.sh` + its 20-assertion self-test, report mode | LOW | **DONE** (`d459cb2`) |
| 1 | Run it; commit `inventory.txt` as the artifact defining scope | LOW | **DONE** (`d459cb2`) |
| 2 | Delete `/toque:codex-challenge`; clean 10 referencing files; renumber `run-all.sh` to 7 layers | MEDIUM | blocked on the gate |
| 3 | The four stale citations, `GUIDE.md:265`'s phantom field, METHODOLOGY §7 | LOW | blocked on the gate |
| 4 | `quick-audit` scoring + the two plan fixtures | LOW | blocked on the gate |
| 5 | `10-llm-rubric-calibration.md` — rewrite or retire (OQ1) | LOW | blocked on OQ1 |
| 6 | `quick-plan` promotion path + relationship lines | LOW | blocked on the gate |
| 7 | Move the sweep into `tests/layer1-repo.sh`; flip report → enforce; mutation test | LOW | last commit |

**Phases 0 and 1 are already complete, and that is legitimate rather than a
jumped gate.** Both wrote only to `docs/plans/{plan}/`, which the approval tiers
place at *document write — no approval*. Nothing under `plugins/` or `tests/`
has been touched. Phase 7 moves the sweep into `tests/`, which is a **codebase
write** and waits for a passed gate like every other phase below.

**Phase 2 exit:** `grep -rn codex-challenge` returns only historical records;
suite 7/7.
**Phase 3-6 exit:** the sweep's report count falls; suite stays green each time,
because report mode cannot redden it.
**Phase 7 exit:** the sweep reports zero in enforce mode; planting `3/5` and
`X/40` each redden Layer 1; removing them greens it again.

### Go / no-go

| Boundary | Go requires | No-go |
| --- | --- | --- |
| 2 → 3 | Suite 7/7; no dangling references | Fix forward; revert is safe — nothing enforces yet |
| 3 → 4 | Sweep count fell; suite green | **Stop if METHODOLOGY §7's rewrite introduces unverifiable claims** |
| 5 | OQ1 answered before starting | Do not guess at a 157-line document's fate |
| 7 | Sweep reports zero; both mutations bite | **Stop.** A guard that cannot fail is worse than none |

**Rollback is unconstrained until Phase 7.** This is the direct fix for audit-2's
S14 finding — with the guard in report mode, reverting any earlier phase cannot
redden a suite that nothing is enforcing yet. Only Phase 7 makes revert order
matter, and it is the last commit.

### Release

Breaking: a command is removed and two commands stop emitting scores. Major
version, a `CHANGELOG.md` entry naming both, released only through
`.github/release.sh`.
