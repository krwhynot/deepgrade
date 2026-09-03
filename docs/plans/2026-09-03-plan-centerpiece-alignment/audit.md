# Design gate audit — plan-centerpiece-alignment

- Date: 2026-09-03
- Auditor: isolated plan-auditor agent, run against the canary-mutated copy
- Spec audited: `.canary/spec.md` (identical to `spec.md` except the planted row)

## Gate result: **NOT PASS**

```
CANARY_OK    true   - planted defect caught (see resolution below)
EVIDENCE_OK  false  - tq-evidence-validate.js exit 1, LINT-15 demoted
VERIFIED     false  - Gap-checked: NO
INFRA_OK     false  - tests/mutation/ is not invoked by run-all.sh; the spec
                      lists it under "Tier 1, automated". Claim overstated.

PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK  ->  false
```

Stage 3 (Build) does not open. The revision loop IS permitted, because the
canary was caught and the audit is therefore trustworthy.

## Canary resolution

Class `assumption-inject` -> LINT-08. Planted one row at `.canary/spec.md:330`:
*"Peak write throughput fits the current connection pool | Writes stall at
launch | unverified"*.

**Caught.** The auditor flagged it as an unverified HIGH-impact assumption with
no owner or verification method, and separately as foreign to a change that has
no runtime, no persisted state and no network calls.

**Resolved: LINT-08 is STRIPPED, not carried to the original.** Its evidence
record rests entirely on the planted row, and `grep "Peak write throughput"
spec.md` returns 0. The recheck against the original finds nothing, so the
finding drops with the artifact. The Assumption Register gaps in Output B are a
separate finding and DO stand against the original.

**Isolation was imperfect, disclosed by the auditor not by me.** `canary.json`
was written into the same directory as the spec the auditor was told to audit,
and it read the file. It reports having flagged the row on first read, before
that. The setup error is mine; the canary result is weaker than a clean run and
is recorded that way rather than claimed as clean.

## Verdict counts on the original spec

| | Count |
| --- | --- |
| MET | 10 |
| UNMET | 6 — LINT-02, 06, 09, 15, 16, 20 |
| N_A | 1 — LINT-14 (first audit, no baseline) |
| Stripped as canary | 1 — LINT-08 |

LINT-15 was MET as returned by the auditor and **demoted by the validator**
(`EVIDENCE-UNEXECUTED`): the record proves the eight test layers are wired but
retains no command showing they pass. Per the stage rule, a checkable claim with
no executed evidence is UNMET, not partial.

---

*Everything below is the auditor's report as written, unedited.*

---

# Plan Audit Report

- Generated: 2026-09-03
- Plan reviewed: "Make /toque:plan the centerpiece the rest of the toolkit agrees with — Specification"
- Artifact audited: `docs/plans/2026-09-03-plan-centerpiece-alignment/.canary/spec.md` (626 lines)
- Auditor: Toque Plan Auditor, isolated-judge mode
- Audit mode: **FULL** (`intent.md`, `research/findings.md`, `research/codex-design-review.md`, `manifest.md`, `status.json` all present alongside the spec)
- Evidence records: `docs/plans/2026-09-03-plan-centerpiece-alignment/evidence/` (18 files, all quotes re-sliced and byte-compared before this report was written)

## Input-hygiene disclosure

Two disclosures, made because concealing them would misrepresent how these findings were reached.

1. **I read `.canary/canary.json` while listing the plan folder.** It names an injected defect class. I had already flagged the anomalous risk row at spec line 330 during my first read of the spec, before opening that file — the row is a duplicate `| 2 |` in a table headed "Top 3 risks", with a mitigation cell containing the single word "unverified" and an impact about a connection pool in a change the spec itself says has no runtime. The finding is independent of the file; the file confirmed it. Every other finding in this report was derived from the spec and the repository only.
2. **I did not read** any generation transcript, any generator self-assessment, any previous audit or verdict for this plan, any pass threshold, or the non-canary copy of the spec. No such content was presented to me. I was not told what verdict count this plan needs, and I have not reasoned about whether the counts below are "enough" — the caller owns that gate.

---

## Criterion Verdicts

Registry: `plugins/toque/docs/planning-techniques/lint-registry.md`. Phase 5 set = LINT-01 through LINT-10, LINT-13 through LINT-20 (18 rules). LINT-11 and LINT-12 are Phase 7 and did not run. LINT-14 is recorded `N_A` per the registry's own gate behavior (first audit, no baseline).

Full records with byte-addressed evidence are in `evidence/{criterion_id}.json`. Summarised here.

| Criterion | Verdict | Basis |
|-----------|---------|-------|
| LINT-01 | MET | All six intent.md outcomes map to a delivery phase (spec 500-506; intent 34-44) |
| LINT-02 | **UNMET** | Risk row at spec:330 has impact "Writes stall at launch" and mitigation "unverified" |
| LINT-03 | MET | Five phases, five explicit rollback lines (spec 527, 565-566, 575, 586, 596) |
| LINT-04 | MET | One external dependency (Codex CLI); sole-maintainer ownership stated at spec 298-299 |
| LINT-05 | MET | Codex contract assigned Contract Testing with 8 named tests (spec 443, 552-561) |
| LINT-06 | **UNMET** | NFR-4 claims existing plan folders resume; no scenario or test exercises one (spec 98 vs 475-483) |
| LINT-07 | MET | D1-D7 each carry a test delta (spec 440-448) |
| LINT-08 | **UNMET** | Unverified HIGH-impact assumption at spec:330, contradicted by spec 96 and 300 |
| LINT-09 | **UNMET** | Widened guard will fire on ≥4 files no phase repairs; METHODOLOGY.md §7 unaddressed |
| LINT-10 | MET | Go/no-go table covers all five boundaries (spec 600-606) |
| LINT-13 | MET | Four options (A/B/C/D) with two comparison matrices and revisit triggers |
| LINT-14 | N_A | First audit; no baseline. Registry prescribes skip. |
| LINT-15 | MET | All cited test infra verified present (run-all.sh 8 layers, layer1-repo.sh wired, release.sh `check`) |
| LINT-16 | **UNMET** | 60-day metric needs a `status.json` promotion field that does not exist and NFR-4 forbids |
| LINT-17 | MET | Seven deliverables, seven named methodologies, none defaulted to unit tests |
| LINT-18 | MET | Separate test authorship specified three times, with the tautological-test counter-rule |
| LINT-19 | MET | Confidence brief exists; no `[SOURCE NEEDED]` / `[LINK DEAD]` / `[UNVERIFIED]` markers on HIGH entries |
| LINT-20 | **UNMET** | Evidence section has none of the three prescribed subsections and no per-entry required fields |

### Verdict Summary

- MET: 11
- UNMET: 6
- N_A: 1

### UNMET criteria

| Criterion | Location expected | Gap |
|-----------|-------------------|-----|
| LINT-02 | Gotchas → Top 3 risks table, spec:325-332 | Row 2 (line 330) has no mitigation; cell reads "unverified" |
| LINT-06 | Verification plan → Two-tier split, spec:475-483 | NFR-4's "existing plan folders resume" is claimed but never exercised |
| LINT-08 | Gotchas table / an assumption register that does not exist | Unverified HIGH-impact assumption about write throughput and a connection pool; no verification method, owner or date |
| LINT-09 | Delivery → Phase 1 file table (spec:519-523) and Phase 5 (spec:588-596) | `commands/help.md:28`, `commands/quick-plan.md:72,101,102`, `docs/planning-techniques/02-evaluator-optimizer-loop.md:76`, `GUIDE.md:113,124`, `round-loop.md:128`, and root `METHODOLOGY.md §7` all carry scoring vocabulary and are in no phase |
| LINT-16 | Success metrics table, spec:110 | Measurement method depends on a `status.json` field that does not exist; NFR-4 (spec:98) forbids adding it |
| LINT-20 | Evidence section, spec:345-404 | Zero of the three prescribed subsections; no entry carries "What it is" / "Why it works" / "Connection to this plan" |

Report ends at the counts. I have not been told where the cut is and do not state whether the plan passes.

---

## Codebase Verification

Every path and line the spec cites was opened and compared against the claim. `plugins/toque/` prefixes are implied where the spec uses repo-relative-to-plugin paths.

### Citations that check out

| Spec claim | Cited location | Result |
|---|---|---|
| E2 — guard enforces no-score | `tests/layer1-repo.sh:855-858` | **OK** — range holds `score_bad=0`, the `for sf in …` subject set, the grep and the `fail` call |
| E3 — `quick-audit` emits X/40 and a band | `commands/quick-audit.md:59-60` | **OK** — `1. Overall score (X/40) with color (Green/Yellow/Orange/Red)` / `2. The scorecard table (8 dimensions)` |
| E4 — stops at ≥36/40 | `phases/round-loop.md:113` | **OK** — `1. **Score >= 36/40** → GREEN achieved. Go to Step 5.` |
| E5 — escalates below 24/40 | `phases/round-loop.md:126` | **OK** — `**Model escalation**: If total score < 24/40 (RED) in Round 1 …` |
| E6 — prompt asks for scores | `phases/prompt-template.md:18,40` | **OK** — `:18` `Score this plan across 8 dimensions (1-5 each, max 40):`; `:40` `Respond with scores for all 8 dimensions, a total, and gaps …` |
| E7 — schema requires `scores`/`total`, `additionalProperties:false` | `tests/fixtures/codex-challenge/codex-review-schema.json` | **OK** — `"required": ["scores","total","gaps"]`, `"additionalProperties": false` |
| E8 — parser extracts `TOTAL: N/40`, validates 1-5 | `tests/codex-challenge-test.js:26-57` | **OK** — score bounds check and `/TOTAL:\s*(\d+)\/40/` both inside the range |
| E11 — `gaps` carries dimension/issue/fix | `codex-review-schema.json` | **OK**, but see "partly wrong" below |
| E12 — `quick-cleanup` is the promotion precedent | `commands/quick-cleanup.md:7-25` | **OK** — `<plan_homebase>` block with the resolution order and folder creation |
| E13 — Codex CLI 0.153.0 installed | run during the session | **OK** — `codex --version` returns `codex-cli 0.153.0` |
| Phase 1 row | `agents/plan-scaffolder.md:24` | **OK** — `4. Auditable (would score 32+/40 on the plan-auditor)` |
| Phase 1 row | `agents/plan-scaffolder.md:232` | **OK** — `1. Score against the 8 plan-auditor dimensions (target 32+/40)` |
| Phase 1 row | `commands/quick-plan.md:2` | **OK** — front matter contains "scores well on the plan auditor's 8 dimensions" |
| Phase 1 row | `codex-challenge/SKILL.md:27` | **OK** — `The loop targets **36/40** (upper GREEN threshold from Toque's plan-auditor rubric):` |
| Phase 1 row | `GUIDE.md:265` | **OK** at `plugins/toque/GUIDE.md:265` |
| Phase 2 rows | `report.md:20,21,25,79` | **OK** — all four are `/40` lines |
| Phase 2 rows | `SKILL.md:3,27,28,125,158` | **OK** — superset; `:28` is `- GREEN: 32-40 (plan is solid)` |
| Phase 2 row | `round-loop.md:62-64` | **OK** — `:64` is the `Score: {total}/40 ({GREEN\|YELLOW\|ORANGE\|RED})` line |
| Dependencies | `tests/codex-challenge-test.js` "447 lines" | **OK** — exactly 447 |
| D5 | "`tests/mutation/` exists" | **OK** — contains `README.md`, `wave5-guards.py` |
| FR-7 | `bash tests/run-all.sh` 8 layers | **OK** — `run-all.sh:110-117` wires layers 1-8; layer 1 sources `layer1-repo.sh` at `layer1-config-wiring.sh:48`, so a widened PH5-051 does land in Layer 1 |
| NFR-5 | `.github/release.sh check` | **OK** — `check)` at `.github/release.sh:176` |

### Citations that do NOT check out

**C1 — E1's line number is wrong. `HIGH [B]`**
Spec:358 cites `plugins/toque/agents/plan-auditor.md:60` for "The gate has no score; the 8 dimensions survive as lenses only." Line 60 is the bare string `<review_dimensions>`. The claim's actual support is lines 61-63: *"They are lenses for finding gaps and locating evidence, not things to be rated."* The claim is true; the byte-address is not. This is the spec's single HIGH-impact foundational citation, and it does not resolve.

**C2 — E10's second clause is false, and it breaks FR-2's acceptance criterion. `HIGH [A]`**
Spec:367 says of `score_history`: *"only other match is the guard."* A repo-wide grep returns, outside this plan folder:

- `CHANGELOG.md:105`, `CHANGELOG.md:288`
- `docs/specs/phase5-verifier-gate.md:317`, `:364`, `:502`
- `plugins/toque/GUIDE.md:265` (the one being deleted)
- `tests/layer1-repo.sh:857` (the guard)

`docs/specs/phase5-verifier-gate.md:317` states in the present tense that "`status.json` gains a `score_history` array" — a live stale claim in a shipped spec that no phase touches. Consequently FR-2's criterion (spec:28-29, *"grepped for `score_history`, then the only match is the guard"*) and Phase 1's Done-when (spec:525, *"`grep -rn "score_history" .` matches only the guard"*) are **not achievable by the work Phase 1 schedules**. Run literally from the repo root, that grep also matches the plan's own spec eleven times.

**C3 — "three hand-listed paths" mischaracterises the guard. `HIGH [B]`**
FR-4 (spec:61) says the subject set is a "hand-listed trio"; Phase 4 (spec:579) says "the three hand-listed paths." The actual loop is `for sf in plugins/toque/skills/plan/SKILL.md plugins/toque/skills/plan/stages/*.md plugins/toque/agents/plan-auditor.md` — two literals and one **glob**. One third of the current subject set is already derived. Small, but it is the premise the whole of FR-4 rests on.

**C4 — `METHODOLOGY.md §7` is cited as authority for a decision it contradicts. `HIGH [B]`**
Spec:313-314: *"The project's own no-score decision (8.0.0). … `METHODOLOGY.md §7` is the reference."* `METHODOLOGY.md:1031` is titled **"## 7. The Plan Audit Scoring System"**, and `:1037` reads: *"you get a numeric score across 8 dimensions."* The section goes on to render an ASCII "8-Dimension Scorecard" totalling `/40` and a "Score Thresholds" subsection describing four colour zones. The spec cites, as the canonical statement of the no-score decision, the canonical statement of the scoring system. `METHODOLOGY.md` is a shipped root document and appears in no phase.

**C5 — Phase 2's `round-loop.md` line list is incomplete. `HIGH [A]`**
Cited: `:62-64, :113, :126`. Also carrying scoring vocabulary: `:60` (`gaps[]` includes `score`) and `:128` (`"Escalating to gpt-5.4 due to RED score ({score}/40)."`).

**C6 — E9 is in tension with the spec's own words. `MEDIUM [B]`**
E9 (spec:366) claims "Nothing consumes the score programmatically." The Dependencies block (spec:305-306) calls `tests/codex-challenge-test.js` "447 lines, **score-coupled**", and that file computes `computedTotal` and compares it to the parsed total at `:52-57`; `round-loop.md` branches on the score in four separate exit conditions. The spec's own "Known weaknesses" bounds E9 to a grep over `plugins/toque/`, which is honest, but the unqualified sentence in the evidence table is not accurate as written.

---

## Devil's Advocate

I take each load-bearing assumption in turn and try to break it.

### DA-1 — "The affected surface is 10 files / 31 lines." **Broken.**
I re-ran the widened guard's own regex (`score_history|/40\b|[0-9]+-[0-9]+ = (GREEN|YELLOW|ORANGE|RED)`) over `plugins/toque/` and diffed the hits against the phase tables. Files that will trip Phase 4's derived guard and that **no phase repairs**:

| File:line | Content | Scheduled? |
|---|---|---|
| `commands/help.md:28` | `Codex scores your plan (8 dimensions, max 40), Claude optimizes until 36/40 GREEN.` | No — Phase 5 only *adds* a relationship line to help.md |
| `commands/quick-plan.md:72` | `- Overall score (X/40), reported only — it does not gate anything` | No — Phase 1 fixes `:2` only |
| `commands/quick-plan.md:101-102` | `\| v1 \| 24/40 \| …` / `\| v2 \| 35/40 \| …` | No |
| `docs/planning-techniques/02-evaluator-optimizer-loop.md:76` | `v1 (score: 24/40, gaps: 7) -> audit1 -> v2 (score: 35/40, gaps: 1) …` | No |
| `GUIDE.md:113` | `The X/40 score in the report is reported for trend-watching only …` | No — Phase 1 fixes `:265` only |
| `GUIDE.md:124` | `… Claude revises until the score converges at 36/40 or the round limit is hit.` | No |
| `round-loop.md:128` | `"Escalating to gpt-5.4 due to RED score ({score}/40)."` | No — omitted from Phase 2's line list |
| `METHODOLOGY.md` §7 (root) | Whole section: `/40` scorecard + colour thresholds | No — outside `plugins/toque/`, so the guard misses it too, but FR-2 covers it |

That is **at least eight repair sites across seven files** the delivery plan does not name. `research/findings.md` R4 already listed three of them (`commands/help.md`, and the two `docs/planning-techniques/` files); the spec dropped them when it turned R4 into phases.

### DA-2 — "The suite is green at every phase boundary." **Broken by DA-1.**
Spec:489-492 makes this the *reason* the guard lands last. But Phase 4's derived guard fires on the files above, so the boundary `4 → 5` goes red. The no-go action for that boundary is **"Stop. A guard that cannot fail is worse than none"** (spec:605) — which is the wrong instruction for this failure. The guard will be working correctly; the repair list is short. The plan has no branch for "the guard bites something we did not schedule."

### DA-3 — "Only the numbers attached to the eight dimensions are removed; the dimensions survive." **Broken — there are two different sets of eight.**
The Codex schema's eight keys are `problem_definition, architecture, sequencing, risk, rollback, timeline, testing, **omissions**`. The auditor's and `METHODOLOGY.md`'s eight are Problem Definition, Architecture & Design, Phasing & Sequencing, Risk Assessment, Rollback & Safety, Timeline & Effort, Testing & Validation, **Team & Resources**. The eighth differs. Phase 2 (spec:548) says only *"`required` becomes the eight dimension names"* and never enumerates them. FR-3a's "all eight dimensions" therefore has no referent, and the atomic contract commit will silently pick one set. If it picks the auditor's, the reviewer's coverage surface changes; if it picks the schema's, `omissions` remains a dimension the auditor has no lens for. Either way, spec:131-133's "not changing the eight dimensions" is not the outcome.

### DA-4 — "The new loop replaces the stop condition and the model-escalation trigger." **Incomplete.**
`round-loop.md:113-124` has **six** exit conditions, not two:

1. `Score >= 36/40` — replaced by the new design
2. Max rounds reached — survives
3. `No score improvement between rounds AND all dimensions >= 3/5` — **a score expression; the spec never mentions it**
4. `Any dimension at 1/5 or 2/5 persists after Round 2` → halt for human review — **a score expression; the spec never mentions it**
5. Budget checkpoint at 3 minutes of a 15-minute ceiling — **not in the new architecture diagram**
6. Total elapsed > 15 minutes → abort — **not in the new architecture diagram**

The architecture diagram (spec:268-290) has four branches. Conditions 3 and 4 cannot survive — they are `/5` expressions the guard will flag. Condition 4 is the *human-escalation* path, and losing it silently is a behavioural regression FR-3 does not authorise. Conditions 5 and 6 are the only actual runaway protection and the diagram drops them, which sits badly against FR-3's *"must not silently loop forever."*

### DA-5 — "Expand/Contract is deliberately NOT used." **The spec says both things.**

- Spec:315-317, Standards applied: *"**Expand/Contract** for the schema change — methodology 11 … chosen because the response contract has existing consumers (parser, fixtures, tests)."*
- Spec:372-376, Evidence → Standards and methods used: *"Expand/Contract for the schema change … Applied here to a tool contract rather than a database."*
- Spec:250-261, Approach: *"The first draft of this spec staged the change as Expand/Contract. The Codex review rejected that as ceremony, correctly."*
- Spec:450-453, Verification plan: *"**Expand/Contract is deliberately NOT used** for D2."*

Two sections say applied, two say not applied, and the two that say applied give the *exact justification* ("existing consumers: parser, fixtures, tests") that the other two explicitly refute ("Tests and fixtures are not independent consumers"). This is unremoved first-draft residue in a document intended to be executed by an agent that may read either half.

### DA-6 — "`status.json` schema 2 unchanged" and "plan folders whose `status.json` records a promotion source." **Mutually exclusive.**
NFR-4 (spec:98) freezes the schema. The 60-day success metric (spec:110) measures promotions by a `status.json` field that does not exist in schema 2. One of the two must give, and the spec does not say which.

### DA-7 — "One atomic change, so no compatibility window." **Holds for the wire format, not for the docs.**
The argument at spec:256-264 is correct and well made for the prompt/schema/parser/fixture quartet. But the same commit does not touch `help.md:28`, `GUIDE.md:124` or `SKILL.md`'s remaining prose, all of which describe the *old* convergence behaviour to users. There is a documentation-versus-behaviour window even if there is no wire-format one, and FR-2 is the requirement that was supposed to close it.

### DA-8 — "`tests/mutation/` exists, so D5 is Tier 1 automated." **Overstated.**
The directory holds `README.md` and `wave5-guards.py` and is not invoked by `run-all.sh`. Listing "the D5 mutation proves the guard bites" under **Tier 1, automated** (spec:475-477) classifies a manual harness as automated. Phase 4's go/no-go depends on it.

### DA-9 — The unverified connection-pool assumption. **Foreign to the change and unmitigated.**
Spec:330 asserts "Peak write throughput fits the current connection pool", impact "Writes stall at launch", mitigation "unverified". The spec elsewhere states there is no runtime (`:300`), no new persisted state or network calls (`:96`), and no deployment or monitoring surface (`:610`). It sits inside a table headed "Top 3 risks" that has four rows numbered 1, 2, 2, 3. Whether read as a real assumption or as content that does not belong, it is an unverified HIGH-impact assumption with no verification method, owner, or date.

### DA-10 — Two decisions are recorded as simultaneously open and closed.
Open question 1 (spec:408-409) asks *"Does the true scope change the decision?"* while Gotcha 1 (spec:329) says it was *"Raised and accepted at scope lock, 2026-09-03."* Open question 2 (spec:410-412) says the severity ladder *"Blocks Part B"* while the Verification plan (spec:418-434) resolves it. Open question 3 (round cap value) is marked "Non-blocking" but Phase 2's required test 6 ("Cap reached with a FAIL open") cannot be written deterministically without it.

### Premortem: if this fails, the most likely reason

**Most likely (I would put this first by a clear margin): Phase 4 turns Layer 1 red on files nobody scheduled, and the maintainer resolves it the wrong way.** The plan has trained itself to read a red Layer 1 at that boundary as "the guard is broken" (spec:605 says Stop, a guard that cannot fail is worse than none). The actual condition will be the opposite — the guard working, on real violations, in `help.md`, `quick-plan.md`, `GUIDE.md` and a planning-techniques doc. The two available responses are both bad: narrow the guard's subject set to make it green, which is precisely the vacuous-pass failure FR-4 exists to eliminate; or absorb seven files of unplanned edits mid-flight, which Gotcha 1 says must become a Change Record and which re-opens Open question 1.

**Second most likely: the eight dimension names get chosen during the Phase 2 commit rather than decided.** The contract is atomic by design, so there is no second commit in which to notice that `omissions` and `Team & Resources` are not the same dimension. FR-3a's coverage enforcement then enforces coverage of whichever eight the implementer typed.

**Third: the two Expand/Contract passages survive into the build**, and an agent reading the Standards section stages a change the Approach section already ruled out — spending the two intermediate states the Codex review was thanked for removing.

**What changed in one layer but not another**

| Layer that changes | Layer that does not | Consequence |
|---|---|---|
| Codex wire format (prompt, schema, fixtures, parser) | `round-loop.md` exit conditions 3, 4, 5, 6 | Two `/5` expressions and all runaway protection are left undefined |
| `quick-audit` and `codex-challenge` stop scoring | `help.md:28`, `GUIDE.md:113,124`, `02-evaluator-optimizer-loop.md:76`, `METHODOLOGY.md §7` | User-facing docs still teach a scoring system the tools no longer have — the exact defect FR-2 names |
| The guard's subject set widens to all of `plugins/toque/` | The repair list stays at the Phase 1/2/3 files | Layer 1 red at boundary 4 → 5 |
| Success metric wants a promotion field in `status.json` | NFR-4 freezes schema 2 | The metric is unmeasurable as specified |
| The Codex schema's dimension keys | The auditor's / METHODOLOGY's dimension names | "All eight" means two different things |

---

## What the Plan Gets Right

Recorded because an audit that only lists faults is not a measurement either.

1. **The Codex review is absorbed as fact and rejected as scope, on the record.** Spec:230-235 adopts the reviewer's Q4 repair (silence-as-approval → FR-3a) and separately declines its Option D recommendation, labelling that an owner decision rather than a factual disagreement. Spec:400-404 keeps the disagreement visible instead of averaging it away. `HIGH [B]`
2. **FR-3a is the right fix for the right bug.** Requiring an explicit verdict *and* evidence for all eight dimensions, and rejecting a short response as malformed rather than as passes, converts coverage from a convention into a schema property. The architecture diagram (spec:281-282, 292-294) correctly identifies the malformed branch as the load-bearing one.
3. **Expand/Contract is refused with a real argument.** Spec:256-261 states the precondition (independent consumers on separate deploy schedules), shows it does not hold, and names the cost of the ceremony. This is better reasoning than most plans apply *for* a methodology. (That two other sections contradict it is DA-5's problem, not this one's.)
4. **Phase ordering is justified by a mechanism, not a preference.** Spec:489-492 explains that the guard lands last because widening it first would redden Layer 1 — a correct and specific reason, even though the plan then fails to apply it to its own uncovered files.
5. **Testing methodologies are selected, with the non-selection recorded.** Spec:450-453 explicitly notes why Expand/Contract's absence is a decision rather than an oversight — that sentence is exactly what LINT-17 is trying to elicit.
6. **The evidence base is candid about its own limits.** Spec:381-384 bounds E9 as a negative claim from a bounded sweep; spec:385-388 records a correction to an earlier draft that had wrongly asserted the Codex CLI was unavailable, and names the cause ("asserted without checking `PATH`"); spec:394-398 states plainly that reviewer behaviour under the new contract is unverified and routes it to a manual Tier 2 check.
7. **Estimates are honest about their unit.** Spec:495-498 estimates in working sessions and states why calendar weeks would be invented precision.
8. **Rollback is trivially true and says so.** Every phase is one `git revert`, and spec:565-566 gives the reason it is sufficient (the tool persists no responses), rather than asserting it.

---

## Gaps That Must Be Addressed

Ordered by severity.

| # | Severity | Gap | Suggested addition |
|---|---|---|---|
| G1 | **HIGH** | Seven files / eight sites carry scoring vocabulary and are in no phase; Phase 4's derived guard will fire on them (DA-1) | Replace Phase 1's hand-written file table with the output of the guard's own regex over `plugins/toque/`, run at planning time and pasted in. Add `METHODOLOGY.md §7` as its own row with a note that it is outside the guard's reach and therefore needs a separate check |
| G2 | **HIGH** | FR-2's acceptance and Phase 1's Done-when are unachievable: `score_history` also lives in `CHANGELOG.md:105,288` and `docs/specs/phase5-verifier-gate.md:317,364,502` | Either scope the grep (`grep -rn score_history plugins/ tests/`) with a written CHANGELOG/historical-spec exemption mirroring `layer1-repo.sh`'s own 16R exemption, or add those files to Phase 1 |
| G3 | **HIGH** | "All eight dimensions" resolves to two different sets of eight (DA-3) | Enumerate the eight names verbatim in Phase 2, and state which of `omissions` / `Team & Resources` wins and why |
| G4 | **HIGH** | Four of `round-loop.md`'s six exit conditions are unaddressed, including the human-escalation path and both runaway guards (DA-4) | Add a table to Phase 2 mapping all six current exit conditions to keep / replace / delete, with a reason per row. Restore the elapsed-time abort to the architecture diagram |
| G5 | **HIGH** | Expand/Contract is described as both applied and not applied (DA-5) | Delete spec:315-317 and the first bullet of spec:372-376; keep the Approach and Verification-plan treatment |
| G6 | **HIGH** | Unverified HIGH-impact assumption at spec:330 with no mitigation, in a "Top 3" table with four rows | Remove the row, or convert it into an assumption-register entry with impact-if-false, verification method, owner and date. Renumber the table |
| G7 | MEDIUM | NFR-4's compatibility claim is never exercised (LINT-06) | Add to Tier 1: open the two existing plan folders under `docs/plans/` with the changed tooling and confirm resume; assert `schema_version == 2` unchanged |
| G8 | MEDIUM | The 60-day metric needs a `status.json` field NFR-4 forbids (DA-6) | Either amend NFR-4 to permit an additive optional `promoted_from` key and say so, or change the metric's method to something observable without a schema change |
| G9 | MEDIUM | Phase 4's no-go instruction is wrong for the failure that will actually occur (DA-2) | Split boundary `4 → 5` into two rows: "guard does not bite → Stop" and "guard bites unscheduled files → fix forward under a Change Record" |
| G10 | MEDIUM | The Evidence section is not the prescribed confidence-brief format (LINT-20) | Restructure under `### Dependencies & Tools` / `### Methods & Patterns` / `### Best Practices & Standards`, each entry with What it is / Why it works / Connection to this plan. Keep the claims table as a separate verification appendix — it is good and the format does not have a slot for it |
| G11 | MEDIUM | FR-6 requires a relationship line "in `/toque:help` **and** the command's own description", but its only acceptance criterion covers help, and Phase 5 delivers only help | Add a second Given/When/Then for front matter and a Phase 5 sub-step listing the six command files |
| G12 | MEDIUM | E1's citation does not resolve; E10's second clause is false (C1, C2) | Repoint E1 to `plan-auditor.md:61-63`; rewrite E10's evidence cell to the real match set |
| G13 | LOW | No timeline buffer. 4.5-5.5 sessions with no allowance for unknowns, on a plan whose own Gotcha 1 says the scope was understated once already | Add 20-30% or state explicitly that a sole maintainer with no deadline does not need one |
| G14 | LOW | Bus factor 1, unaddressed. Spec:298-299 identifies a single maintainer and no continuity plan | One line: either "single-maintainer risk accepted, the change is fully described in this spec" or a named fallback |
| G15 | LOW | NFR-6 requires a `CHANGELOG.md` entry; no phase delivers it | Add it to Phase 5 or to a named release step |
| G16 | LOW | Open questions 1 and 2 are listed as open and answered elsewhere; OQ3's round cap blocks required test 6 (DA-10) | Strike the answered ones; resolve the cap value before Phase 2 |
| G17 | LOW | "three hand-listed paths" is wrong — one of the three is a glob (C3) | Correct FR-4 and Phase 4's wording |
| G18 | LOW | D5 classified as Tier 1 automated but `tests/mutation/` is not wired into `run-all.sh` (DA-8) | Move it to Tier 2, or wire it |

---

## Top 5 Risks

| # | Risk | Likelihood | Impact | In Plan? | Mitigation |
|---|------|-----------|--------|----------|-----------|
| 1 | Phase 4's derived guard fails Layer 1 on files no phase repairs, and the documented no-go says "Stop, the guard is broken" | **HIGH** | HIGH | **NO** | Derive the Phase 1 file list from the guard's own regex now; split the boundary-4 no-go into guard-fault vs coverage-fault |
| 2 | The eight dimension names are chosen inside the atomic Phase 2 commit rather than decided, silently changing the review surface | MEDIUM | HIGH | **NO** | Enumerate the eight verbatim in Phase 2 before any edit |
| 3 | `round-loop.md`'s unaddressed exit conditions are deleted along with the scores, removing the human-escalation path and both runaway guards | MEDIUM | HIGH | **PARTIAL** — FR-3 says the loop must not loop forever, but the diagram drops the time budget | Six-row keep/replace/delete table in Phase 2; restore the elapsed-time abort |
| 4 | An implementer reads the Standards section, stages the schema change as Expand/Contract, and reintroduces the two intermediate states the review removed | MEDIUM | MEDIUM | **NO** — the contradiction is unflagged | Delete the two stale passages |
| 5 | A live Codex reviewer does not reliably return eight verdicts with evidence, so every real round is malformed and the loop never converges | MEDIUM | HIGH | **YES** — Gotcha 2, spec:331, routed to Tier 2 manual | Already handled honestly. Consider adding a bounded retry-on-malformed before the round counts, so one bad response does not consume the cap |

---

## Gap Verification (CHECK 4)

### A. Coverage Matrix

Every goal, requirement, non-goal, risk, dependency and metric traced to an implementation site.

| Item | Type | Covered By | Status |
|------|------|-----------|--------|
| Intent outcome 1 — one verdict currency | Goal | FR-1 → Phases 2, 3 | **GAP** — `quick-plan.md:72` still emits `X/40` and is in no phase; FR-1's scope names only quick-audit and codex-challenge |
| Intent outcome 2 — no stale citations | Goal | FR-2 → Phase 1 | **GAP** — see G1, G2 |
| Intent outcome 3 — guard covers what it claims | Goal | FR-4 → Phase 4 | OK (mechanism), **GAP** on the collateral (G1) |
| Intent outcome 4 — a small plan can grow up | Goal | FR-5 → Phase 5 | OK |
| Intent outcome 5 — relationship line in help *and* front matter | Goal | FR-6 → Phase 5 | **GAP** — front-matter half has no AC and no phase step (G11) |
| Intent outcome 6 — suite green, preflight clean | Goal | FR-7 → go/no-go table | **GAP** — will not hold at boundary 4 → 5 (DA-2) |
| FR-1 no numeric score | Requirement | Phases 2, 3 | **GAP** — scope excludes quick-plan, which scores |
| FR-2 no stale citations | Requirement | Phase 1 | **GAP** — acceptance criterion unachievable (G2) |
| FR-3 score-free convergence | Requirement | Phase 2 | **GAP** — 4 of 6 exit conditions unaddressed (G4) |
| FR-3a coverage enforced | Requirement | Phase 2, tests 3 and 4 | **GAP** — "all eight" undefined (G3) |
| FR-4 derived guard subject set | Requirement | Phase 4 | OK as designed; **GAP** on premise wording (C3) |
| FR-5 promotion path | Requirement | Phase 5 | OK |
| FR-6 relationship lines | Requirement | Phase 5 | **GAP** (G11) |
| FR-7 releasable | Requirement | Go/no-go table | **GAP** (DA-2) |
| NFR-1 no auth surface change | Requirement | Nothing needed — no phase touches credentials | OK |
| NFR-2 no data-scope change | Requirement | Implicit in all phases | **GAP** — the 60-day metric needs a new persisted field (DA-6) |
| NFR-3 no new dependency | Requirement | Scope OUT line 134 | OK |
| NFR-4 backwards compatible | Requirement | — | **GAP** — never tested (LINT-06); contradicted by the 60-day metric |
| NFR-5 release discipline | Requirement | Release section, spec:620-625 | OK — `.github/release.sh check` verified to exist |
| NFR-6 CHANGELOG entry | Requirement | Release section only | **GAP** — no phase owns it (G15) |
| Metric: scoring sites = 0 | Success metric | FR-1 grep via the guard | **GAP** — target unreachable given G1 |
| Metric: stale citations = 0 | Success metric | FR-2 greps | **GAP** — see G2 |
| Metric: 8/8 layers | Success metric | `tests/run-all.sh` | OK — 8 layers verified present |
| Metric: 100% runs terminate | Success metric | Manual observation, 10 runs | **GAP** — no capture mechanism named |
| Metric: ≥1 promotion in 60 days | Success metric | `status.json` promotion source | **GAP** — field does not exist, NFR-4 forbids it |
| Risk 1 — scope larger than intent | Risk | Gotcha 1, accepted at scope lock | OK — and DA-1 shows it was still understated |
| Risk 2 — connection pool / write throughput | Risk | — | **GAP** — no mitigation, foreign to the change (G6) |
| Risk 2b — lazy reviewer marks all PASS | Risk | Gotcha 2 → FR-3a evidence requirement | OK — partial mitigation, honestly labelled |
| Risk 3 — wire format encoded in three places | Risk | Gotcha 3 → one commit + round-trip test 8 | OK |
| Dep: `tests/layer1-repo.sh` | Dependency (internal, hard) | Phase 4 | OK — verified wired into Layer 1 |
| Dep: `tests/codex-challenge-test.js` | Dependency (internal, hard) | Phase 2 | OK — 447 lines verified |
| Dep: four Codex fixtures | Dependency (internal, hard) | Phase 2 | OK |
| Dep: OpenAI Codex CLI | Dependency (external, soft) | Tier 2 manual run | OK — 0.153.0 verified installed |
| Non-goal: `ai-scan` split | Non-goal | Scope OUT | OK — nothing in the plan touches it |
| Non-goal: redesign the design gate | Non-goal | Scope OUT + Constraints | OK |
| Non-goal: remove any command | Non-goal | Scope OUT | OK |
| Non-goal: readiness/audit plugins | Non-goal | Scope OUT | OK — and the OQ2 vocabulary decision explicitly avoids coupling to the audit plugin's ladder |
| Non-goal: publish/release | Non-goal | Scope OUT | **Minor tension** — the Release section (spec:620-625) prescribes a major version bump. Reads as instruction for a later stage, but it sits inside a plan whose intent excludes releasing |
| Non-goal: change the 8 dimensions | Non-goal | Scope OUT line 131-133 | **GAP** — unenforceable while two sets of eight exist (G3) |
| Non-goal: replace the Codex CLI | Non-goal | Scope OUT line 134 | OK |

**Coverage Matrix: 40 items, 19 GAP.**

### B. Assumption Register

The spec has no assumption register. This one is reconstructed from assumptions the spec makes, whether or not it labels them as such.

| # | Assumption | Impact If False | How to Verify | By When | Owner | Status |
|---|-----------|----------------|---------------|---------|-------|--------|
| A1 | Peak write throughput fits the current connection pool | "Writes stall at launch" (spec's own words) | Nothing stated | Not stated | Not stated | **GAP — unverified, HIGH impact, no mitigation. Also inapplicable: no runtime exists (spec:300, 610)** |
| A2 | The affected surface is 10 files / 31 lines | Phase 4 reddens Layer 1; scope re-opens mid-flight | Run the guard's regex over `plugins/toque/` and diff against the phase tables | Before Phase 1 | Kyle | **GAP — FALSIFIED by this audit (DA-1)** |
| A3 | Nothing consumes the score programmatically | Removing it breaks a consumer | Grep beyond `plugins/toque/` | Before Phase 3 | Kyle | **GAP — partially falsified; the parser and four loop conditions consume it (C6). Spec bounds the claim honestly but the table sentence overstates** |
| A4 | "The eight dimensions" denotes one agreed set | The atomic commit silently changes the review surface | Diff the schema's keys against `plan-auditor.md` / `METHODOLOGY.md` | Before Phase 2 | Kyle | **GAP — FALSIFIED (DA-3)** |
| A5 | Only two of `round-loop.md`'s conditions are score-driven | Human-escalation and runaway guards are deleted unnoticed | Read `round-loop.md:113-128` | Before Phase 2 | Kyle | **GAP — FALSIFIED; four are (DA-4)** |
| A6 | `score_history` appears only in GUIDE.md and the guard | FR-2's acceptance can never be satisfied | `grep -rn score_history .` | Before Phase 1 | Kyle | **GAP — FALSIFIED (C2)** |
| A7 | `METHODOLOGY.md §7` supports the no-score decision | The plan cites its own contradiction as authority | Read `METHODOLOGY.md:1031-1090` | Before Phase 1 | Kyle | **GAP — FALSIFIED (C4)** |
| A8 | No external consumer exchanges the Codex payload, so atomic is safe | A stale consumer breaks | Enumerate consumers of the schema | Done in-spec (spec:256-264) | Kyle | OK — argued explicitly and correctly |
| A9 | A live Codex reviewer will return eight verdicts with evidence | The loop never converges; every round malformed | One real `codex-challenge` run, Tier 2 | Stage 4 | Kyle | OK — labelled unverified, verification scheduled. **This is how A1 should have been written** |
| A10 | `status.json` schema 2 can stay frozen and still record a promotion source | The 60-day metric is unmeasurable | Inspect schema 2 | Before Phase 5 | Kyle | **GAP — self-contradictory (DA-6)** |
| A11 | The two existing plan folders resume without migration | Existing plans break | Open both with the changed tooling | Before release | Kyle | **GAP — asserted, never tested (LINT-06)** |
| A12 | `tests/mutation/` gives D5 an automated proof | Phase 4's go/no-go rests on a manual step labelled automated | Check `run-all.sh` for a mutation layer | Before Phase 4 | Kyle | **GAP — not wired (DA-8)** |
| A13 | HIGH/MEDIUM/LOW is the right ladder because the plugin uses it 83/42/39 times | Vocabulary churn | Counted in-spec | Done | agent, flagged to Kyle | OK — decided on evidence, reversibility stated, flagged for owner reversal |
| A14 | Every phase is revertible with one `git revert` | Rollback fails | Text-and-test-only changes | Done | Kyle | OK |

**Assumption Register: 14 assumptions, 10 GAP, 6 of them falsified by this audit. Unverified HIGH-impact assumptions present: A1 (LINT-08 hard gate).**

### C. Scenario Matrix

| Scenario | Planned? | Which Phase? | Tested? | Monitored? | Status |
|----------|----------|-------------|---------|-----------|--------|
| Happy path | Yes | Phase 2 | Yes — required test 1 (all 8 PASS → converged) | n/a, no runtime | OK |
| Failure path | Yes | Phase 2 | Yes — tests 2, 4, 7 (1 FAIL; FAIL without evidence; unparseable) | n/a | OK |
| Partial rollout (mixed state) | Yes, argued away | Approach, spec:256-264 | No test — deliberately, because no window exists | n/a | OK for the wire format. **GAP** for docs: `help.md`, `GUIDE.md` and the planning-techniques doc will describe the old behaviour after Phase 2 lands (DA-7) |
| Backward compatibility | Claimed (NFR-4) | — | **No** | n/a | **GAP** — no phase or test opens an existing plan folder (LINT-06) |
| Scale / volume edge | Partly | Phase 2 | Partly — test 6 covers cap exhaustion | n/a | **GAP** — the round cap value is unresolved (OQ3), so test 6 has no deterministic bound; the 15-minute ceiling is dropped from the new design |
| Auth / permission edge | Not applicable | — | — | — | **N/A with reason** — NFR-1 forbids any diff touching credentials, permissions or tokens; verified no phase file list contains an auth surface |
| Config / environment difference | Partly | Tier 2 | **No** | n/a | **GAP** — the Codex CLI is an external soft dependency whose absence changes behaviour, and no scenario covers "Codex CLI not installed or a different version". Spec:387 notes the last such assumption was wrong precisely because `PATH` was not checked |
| Rollback path | Yes | All five phases | **No** | n/a | **Partial GAP** — every phase names `git revert` but no phase's go/no-go includes exercising it. Low severity given text-only changes |

**Scenario Matrix: 8 scenarios, 4 GAP, 1 partial GAP, 1 N/A with reason.**

### D. Cross-Cutting Concern Sweep

| Concern | Addressed? | Where? | Status |
|---------|-----------|--------|--------|
| API contract | Yes | Phase 2; D2 Contract Testing; 8 required tests; `additionalProperties:false` in both copies (spec:549-550) | **Partial GAP** — the eight `required` key names are never enumerated (G3) |
| UI behavior | Yes | D7 Snapshot/Approval on rendered `/toque:help`; Tier 2 read-once | **GAP** — FR-6's front-matter half is unimplemented (G11); `help.md:28`'s scoring text is unscheduled |
| Auth / authz | Not applicable | NFR-1, spec:95 | **N/A with reason** — zero diff touching credentials, permissions or tokens; no phase file list includes an auth surface |
| Config | Partly | OQ3 (round cap "governed by a `max rounds` setting") | **GAP** — the setting is never located, its value never resolved, and required test 6 depends on it |
| CORS / network / browser | Not applicable | NFR-2, spec:96 | **N/A with reason** — zero network calls; the only external process is a local CLI invocation |
| Data model / query limits | Not applicable | NFR-2 | **N/A with reason** — no database, no persisted user data. Note: the spec's own risk row at :330 asserts otherwise, which is why it is flagged (G6) |
| Pagination | Not applicable | — | **N/A with reason** — no list surface, no result set. The nearest analogue, the old schema's `"maxItems": 7` cap on `gaps`, disappears with the array; the new shape is a fixed eight entries, so no bounding is needed |
| Caching | Not applicable | Approach, spec:263-264 | **N/A with reason** — "`codex-challenge` is invoked fresh each run and holds no persisted responses" (verified as the plan's stated basis for zero-state rollback) |
| Observability | Partly | Operational readiness, spec:608-618 | **GAP** — "first real use is the signal" is a plan, not a mechanism; the 10-run and 60-day metrics have no capture method (LINT-16) |
| Migration / backward compat | Claimed | NFR-4 | **GAP** — untested (LINT-06), and contradicted by the 60-day metric's field requirement (DA-6) |
| Rollout / rollback | Yes | Per-phase `git revert`; catalog SHA pin as incident fallback (spec:615-617) | OK |
| Tests | Yes | D1-D7 methodologies; 8 required Phase 2 tests; separate test authorship; AI failure-mode checklist | **Partial GAP** — D5's mutation is not automated (DA-8) |

**Cross-Cutting Sweep: 12 concerns, 5 GAP, 2 partial GAP, 5 N/A with reason.**

### Plan Lint Results

Rule ids and descriptions copied verbatim from `plugins/toque/docs/planning-techniques/lint-registry.md`. Phase 5 set, Full mode. LINT-14 skipped per instruction and per the registry's own gate behavior; LINT-11 and LINT-12 are Phase 7 and did not run.

| Rule | Description | Result |
|------|-------------|--------|
| LINT-01 | Every goal has at least one mapped ticket | PASS |
| LINT-02 | Every HIGH risk has a mitigation | **FAIL** |
| LINT-03 | Every deployment phase has a rollback plan | PASS |
| LINT-04 | Every external dependency has an owner | PASS |
| LINT-05 | Every new endpoint/API has a contract or test entry | PASS |
| LINT-06 | Backward compatibility claimed but no mixed-state scenario | **FAIL** |
| LINT-07 | Every new behavior has a test or test delta | PASS |
| LINT-08 | No unverified HIGH-impact assumption exists | **FAIL** |
| LINT-09 | No unaddressed cross-cutting concern for in-scope features | **FAIL** |
| LINT-10 | Every phase has go/no-go criteria | PASS |
| LINT-13 | Approach has options analysis with min 2 alternatives evaluated | PASS |
| LINT-14 | No regressions from previous baseline | SKIPPED (first audit, no baseline) |
| LINT-15 | All "Tested" claims have verified test infrastructure | PASS |
| LINT-16 | All "Monitored" claims have verified monitoring infrastructure | **FAIL** |
| LINT-17 | Every deliverable in Phase 4 spec must have a testing methodology assigned | PASS |
| LINT-18 | AI-generated code deliverables must specify a separate test writer | PASS |
| LINT-19 | Confidence brief exists with no unresolved HIGH-impact markers | PASS |
| LINT-20 | Confidence brief has all 3 sections and each entry has required fields | **FAIL** |

### Gap Summary

- Lint: 11/17 passed (18-rule Phase 5 set, LINT-14 skipped as instructed)
- Coverage Matrix: 40 items, 19 gaps
- Assumptions: 14 total, 1 unverified high-impact (A1), 10 gaps of which 6 falsified against the repository
- Scenarios: 8 total, 4 gaps (+1 partial, 1 N/A with reason)
- Cross-Cutting: 12 concerns, 5 gaps (+2 partial, 5 N/A with reason)
- **Gap-checked: NO**

---

## Go / No-Go Assessment

### GO if
- G1 is closed: the Phase 1 file list is regenerated from the guard's own regex and covers every site the widened guard will flag
- G2 is closed: FR-2's grep is either scoped with a written exemption or the remaining `score_history` sites are added to Phase 1
- G3 is closed: the eight dimension names are enumerated verbatim before Phase 2 opens
- G4 is closed: all six current exit conditions have a stated disposition
- G5 is closed: one of the two Expand/Contract positions is deleted
- G6 is closed: the unverified connection-pool assumption is removed or given a verification plan and owner

### NO-GO if
- Phase 4's guard is narrowed to make Layer 1 green — that is the vacuous pass FR-4 exists to eliminate, and it converts the plan's own proof phase into theatre
- The eight dimension names are decided inside the Phase 2 commit rather than before it
- A1 is left standing: LINT-08 is the registry's hard gate at Phase 6 entry, and an unverified HIGH-impact assumption blocks Build

### CONDITIONAL-GO
Phases 1, 3 and 5 are independent, text-only, and individually revertible; nothing in this audit argues against starting Phase 1 once G1 and G2 are folded into its file list. Phase 2 should not open until G3 and G4 are resolved, because it is the atomic commit — there is no second commit in which to notice either problem.

I am not stating an overall verdict. The counts and gaps above are the measurement; the gate is the caller's.

---

## Leadership Presentation Outline

1. **The problem, in one slide.** Two commands grade plans out of 40 with colour bands. The centerpiece stopped grading in 8.0.0. Run both on one plan and you get two verdicts in two currencies, and nothing says which is authoritative.
2. **The decision and why it survived challenge.** Strip, not relabel. Four options compared; the adversarial reviewer preferred keeping the numbers and was overruled on scope, not on facts — recorded on the record. The reviewer's correctness finding (silence read as approval) was adopted and became FR-3a.
3. **What changes.** Five phases, ~5 working sessions, one maintainer. Every phase is one `git revert`. Phase 2 is the only real risk and is the critical path.
4. **What the audit found.** Six of seventeen applicable checks fail. The one that matters: the guard that is supposed to make this permanent will fire on seven files the plan does not schedule, and the plan's own instruction at that moment is to stop and blame the guard.
5. **What must change before Phase 2.** Six items, all editorial (G1-G6). None requires new design work; five are the result of the plan being edited more than once and the earlier draft not being fully removed.
6. **Ask.** Approve Phase 1 with the corrected file list. Hold Phase 2 pending the dimension-name enumeration and the exit-condition disposition table.

---

## Suggested Modifications, in priority order

1. Regenerate Phase 1's file table from `grep -rnE 'score_history|/40\b|[0-9]+-[0-9]+ = (GREEN|YELLOW|ORANGE|RED)' plugins/toque/` and add `METHODOLOGY.md §7` explicitly (G1, G2, and it also closes A2).
2. Add an eight-row table to Phase 2 enumerating the dimension names that become `required`, with the `omissions` vs `Team & Resources` decision stated (G3).
3. Add a six-row keep/replace/delete table for `round-loop.md`'s exit conditions; restore the elapsed-time abort to the architecture diagram (G4).
4. Delete spec:315-317 and the Expand/Contract bullet at spec:372-376 (G5).
5. Delete or rewrite the risk row at spec:330; renumber the table to three rows (G6).
6. Split the `4 → 5` go/no-go row into guard-fault and coverage-fault branches (G9).
7. Add "open both existing plan folders with the changed tooling" to Tier 1 (G7).
8. Resolve the NFR-4 / promotion-metric contradiction in one sentence, either direction (G8).
9. Restructure the Evidence section into the three prescribed subsections, keeping the claims table as an appendix (G10).
10. Add the FR-6 front-matter acceptance criterion and Phase 5 sub-step (G11).
11. Repoint E1 to `plan-auditor.md:61-63`; correct E10's evidence cell (G12).
12. Sweep the remaining LOW items: buffer, bus factor, CHANGELOG ownership, the answered open questions, "hand-listed trio", D5's tier (G13-G18).

---

## Confidence Summary

| Tier | Count | Meaning |
|------|-------|---------|
| HIGH [A] (Deterministic) | 14 | grep/glob/`wc -l`/file-existence results, and the byte-for-byte evidence revalidation |
| HIGH [B] (Verified) | 21 | Direct read of the cited plan text or source file |
| MEDIUM [B] (Inferred) | 5 | Indirect: DA-3's consequence, DA-4's condition-3/4 fate, DA-7's doc window, C6's tension, G13's buffer |
| LOW [C] (Speculated) | 2 | Premortem ranking; the "Scope OUT: publishing" tension. Both `[VERIFY WITH AUTHOR]` |
| UNVERIFIED | 0 | — |

Tier C share: 2/42 ≈ 5%, below the 30% downgrade threshold in the self-audit framework.

Cascade classification: G1/DA-1 is **CASCADE** — the derived-guard finding is an input to G2, G9, A2, the Coverage Matrix, and the Scenario Matrix. It is Tier A (a reproducible grep), which is the safest combination for a cascading finding. G3/DA-3 is **CASCADE + Tier B**, spot-checked twice by reading both dimension lists directly.

`[Confidence: 93%]` — Basis: 35 of 37 checkable claims verified by direct read or command (95%); all 18 evidence records re-sliced and byte-compared, 3 line-range errors found and corrected before publication. Remaining 7% headroom, itemised:
- I did not execute `bash tests/run-all.sh`, so "8/8 currently passing" is a structural claim (8 layers are wired) rather than an observed one. To close: run it.
- DA-4's claim that exit conditions 3 and 4 *will be deleted* is inference from the guard regex matching `/5`-free text — those lines contain `>= 3/5` and `1/5 or 2/5`, which the guard's `/40\b` pattern does **not** match. So they may survive as orphaned score expressions rather than being deleted. Either outcome is a gap; which one is unverified. To close: state their disposition in Phase 2.
- `research/findings.md` R4 lists `docs/planning-techniques/09-multi-category-success-criteria.md` as carrying one scoring line; my sweep found none under either the guard's regex or R4's broader pattern. R4 may be stale, or the pattern differs. Not load-bearing for any verdict.

Assumption I am labelling rather than hiding: **Assumption —** I treated the spec's `## Evidence` section as the confidence brief for LINT-19/20, on the basis of `stage-2-design.md:13` ("Part A: Evidence section (the confidence brief, folded into spec.md)"). If the project intends a separate `confidence.md`, LINT-20 fails for absence instead of format, and LINT-19 would need re-evaluation. Verified the routing claim; did not find a competing definition.

## Verification Statistics

- Candidate findings generated: 31
- Confirmed after the verification pass: 26
- Dropped as false positives: 5 — LINT-04 (owner present via the sole-maintainer constraint at spec:298-299, WORK-009 applies), LINT-10 (go/no-go initially read as missing for Phase 5; boundary `5 → Stage 4` covers it), LINT-19 (marker rule stretched to cover a citation error, then withdrawn as the exact `[PLAN-GAP-INFERRED]` failure mode this framework names), "no CHANGELOG mechanism" (the Release section covers it; downgraded to G15 ownership only), "no incident fallback" (spec:615-617 gives the catalog SHA pin)
- False positive prevention rate: 5/31 = 16%
- Codebase claims verified: 35/37 = 95%. The 2 unverified: live suite result, and R4's `09-multi-category` line count
- Evidence records validated byte-for-byte: 18/18, after correcting 3 line-range errors caught by re-slicing

## Failure-mode flags applied

- `[PLAN-GAP-INFERRED]` — none in the final report. One candidate (LINT-19 stretched to a marker it does not carry) was caught in the verification pass and dropped.
- `[SCOPE-ASSUMED]` — applied to the "Scope OUT: publishing anything" tension in the Coverage Matrix. The Release section may be intended as instruction for a later stage rather than in-scope work; I did not assume either reading. `[VERIFY WITH AUTHOR]`
- `[CODEBASE-CLAIM-NOT-VERIFIED]` — applied to R4's `09-multi-category-success-criteria.md` line count, which I could not reproduce.
- `[ENUMERATION-MAY-BE-INCOMPLETE]` — applied to DA-1's uncovered-file list. It is derived from the guard's *current* regex. If Phase 4 widens the pattern as well as the subject set (the spec does not say whether it will), the list grows.
