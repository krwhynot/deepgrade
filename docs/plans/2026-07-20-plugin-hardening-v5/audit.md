# Plan Audit — Plugin Hardening v5 (Phase 5)

Generated: 2026-07-29 · Auditor: Toque Plan Auditor
**Current audit version: v2** (revision iteration 1 of max 2) · v1 findings retained below as RESOLVED / UNRESOLVED
Primary target: [`docs/specs/plugin-hardening-v5.md`](../../specs/plugin-hardening-v5.md) — **spec v2** (working tree, `+76 / −9` vs committed v1)
Scored jointly with: [`approach.md`](approach.md) v17 · [`acceptance-matrix.md`](acceptance-matrix.md) · [`brainstorm.md`](brainstorm.md) · [`status.json`](status.json) · [`changes/CR-1.md`](changes/CR-1.md)
Verified against: HEAD `c183880` (plugin code unchanged since baseline `4fb4b64`, plugin v4.31.0)
Audit mode: **FULL**

---

## Executive Summary (v2)

The spec's v2 revision closes all three top-priority v1 gaps with verifiable, mechanism-level fixes rather than acknowledgements. Every new codebase citation the revision introduced resolves correctly at HEAD — `commands/help.md:16`, `:30–:52`, `:185–:189` bracket **every** `/toque:plan` occurrence in the file (16, 30, 32, 48, 49, 52, 185; the residual matches at 17/18/189 are `plan-status`/`plan-export`, which survive); `tests/layer1-config-wiring.sh:344-354` is the complete command-count assertion block, a **more accurate** range than the `:345-353` I cited in v1; and the new Wave-4b sweep `grep -rn "scripts/tq-.*\.sh"` demonstrably surfaces `METHODOLOGY.md:1811`, the one stale-reference site v1 flagged as unswept.

The regression check is clean. `git diff` against committed v1 is **+76 insertions / −9 deletions**, and all nine deleted lines are replaced by strictly stronger versions (the Wave 7 go/no-go gains a suite criterion; the activation ticket gains a file list; the critical-path sentence gains its reconciliation). **No acceptance criterion was weakened, no content dropped without replacement, and no previously-passing element now fails. Zero regressions.**

Five of the eight dimensions moved: Architecture 4→5, Phasing 3→4, Timeline 3→4, Team 2→3, with Testing holding at 4 because one v1 finding was not taken up. **All five failing lint rules flipped to PASS, each on evidence I verified independently.** The score moves **30 → 34 / 40, YELLOW → GREEN**, clearing the Build-gate bar.

One v1 finding remains open and it is the reason Testing did not reach 5: PHV5-002's `.gitattributes` acceptance criterion (`spec:44`) is still `git ls-files --eol -- '*.sh'` reports `w/lf`, which I re-verified is **already green at HEAD** with no `.gitattributes` present and `core.autocrlf=true`. It is a tautological gate in a plan whose own AI Failure Mode Checklist prohibits them. This does not block Build — it is a one-line spec edit that can ride Wave 0.

**Recommendation: GO.**

---

## Overall Score: **34 / 40 — GREEN** *(v1: 30/40 YELLOW)*

Thresholds: 32–40 GREEN · 24–31 YELLOW · 16–23 ORANGE · 1–15 RED.

Note carried from v1 on the relationship to the 40/40 Codex GO: that score was earned by `approach.md` v17 (the Phase 3 scope lock) against a different rubric with no team/capacity dimension and no schedule to score. The spec is a separate artifact, first reviewed here.

---

## Baseline Comparison — v1 → v2

### Regression check (HIGH priority — must be zero)

Method: `git diff HEAD -- docs/specs/plugin-hardening-v5.md`, isolating deleted lines as the regression surface.

| Deleted line (v1) | Replaced by (v2) | Verdict |
|-------------------|------------------|---------|
| PHV5-020 `…comma-separated. Custom grep guard required…` | Same text plus the measured 6-agent list (`spec:103-107`) | Strengthened |
| PHV5-071 `One commit: add skill, delete commands/plan.md; §10.4 review…` (2 lines) | Same plus the surface-update file list and tripwire citations (`spec:234-241`) | Strengthened |
| `**Wave 7 go/no-go:** all 7 staging-proof items… review GO.` (2 lines) | Same plus **full suite green after the activation commit** (`spec:243-245`) | Strengthened |
| `budgeted second rounds. Critical path: Wave 0 → 4 → 6 → 7 → 8…` (2 lines) | Same plus the solo=serial reconciliation (`spec:306-310`) | Strengthened |
| `- [ ] Activation commit; review → GO; recovery rehearsed…` | Three checklist items incl. suite-green and stale-reference sweep (`spec:396-398`) | Strengthened |

**Diffstat: 76 insertions, 9 deletions. Every deletion has a strictly stronger replacement.**

> **REGRESSIONS FOUND: 0.** No acceptance criterion weakened, no ticket removed, no verification class dropped, no previously-verified citation invalidated.

### v1 findings — disposition

| # | v1 finding | Status | Evidence |
|---|-----------|:------:|----------|
| 1 | Wave 7 deletes `commands/plan.md`; `layer4:48-54` + `layer1` command count go red; no owning ticket; no suite criterion | **RESOLVED** | `spec:234-241` names `commands/help.md` (`:16`, `:30–:52`, `:185–:189`), README `Commands (N)`, GUIDE counts, in the activation commit, citing both tripwires; `spec:243-245` adds *"full suite green after the activation commit (Layers 1–7 — the help.md/count assertions are the tripwire)"*; `spec:396-397` mirrors it in the checklist |
| 2 | F24 corpus requires in-field quoted-mention tolerance the extract-field-then-regex mechanism cannot deliver | **RESOLVED** | `spec:150-156` Mechanism requirement: *"field extraction alone is not sufficient… 4a's matcher must therefore be **corpus-driven, not bare-regex**: strip or tokenize quoted substrings before pattern matching (or equivalent), and the acceptance corpus is the falsifier — a mechanism that fails any corpus row fails PHV5-041"* |
| 3 | No BLOCKED branch, no buffer, no external-dependency lines; §7 "External: none" contradicted | **RESOLVED** | `spec:312-319` Contingency branches table (G0 BLOCKED, second rounds, reviewer policy-abort with round-14 precedent, **+20% ≈ 5–6 d → 28–34 day envelope**); `spec:321-328` External dependencies with owners and fallbacks |
| 4 | Serial 28 d contradicts the 23 d critical path | **RESOLVED** | `spec:306-309`: *"**Solo means serial: the cumulative column IS the schedule.** The 'critical path' (…≈ 23 d of it) governs *gating order*, not elapsed time"* — and 23 d is exactly the figure I computed independently in v1 |
| 5 | Command-count oscillation 17→16→15 unstated across Waves 3/5/7 | **RESOLVED (effect)** | Each wave now owns its edit: W3 `spec:118`, W5 F30 `spec:195` *"counts updated"*, W7 `spec:239` README `Commands (N)` + GUIDE. *Residual warning:* the trajectory is still not stated as such and Wave 3's target value (17) is unnamed |
| 6 | `G0 = BLOCKED` scope contested across four documents; class-C acceptance unsatisfiable without CI | **MOSTLY RESOLVED** | `spec:316`: *"Wave 0 pauses before CI-enable; Waves 1/3 may proceed; Wave 4 does not start"*; `spec:327` answers the class-C question — *"Local suite runs remain authoritative interim; CI-enable is Wave 0's *last* step by design"*. *Residual:* Waves 2 and 5 unmentioned (`approach.md:625` says 0/1/3/5 are unblocked), and the class-C answer sits in the dependency row rather than the BLOCKED row |
| 7 | Ticket count: 32 headers / 33 IDs vs `status.json:114` "27"; F05/F06 never named by ID | **RESOLVED (spec)** | `spec:437-459` Traceability table maps every matrix item to its owning ticket; `spec:453` *"F05 ledger (11 rows) \| PHV5-040"*, `spec:456` *"F06 F23 SubagentStop (4b) \| PHV5-043"*. Verified: **all 33 F-IDs now present**, 33 unique ticket IDs. `status.json:114` is orchestrator-owned — flagged, not scored |
| 8 | `tools:` flow arrays: 7 claimed, 6 measured | **RESOLVED** | `spec:103-106` records *"measured at HEAD: 6 agents carry flow arrays"* naming `characterization-generator`, `delta-scanner`, `plan-scaffolder`, `gate-generator`, `plan-auditor`, `security-scanner` — **the exact set my v1 measurement produced** — and classes it a measurement note flagged for the Wave 2 review, not a scope change |
| 9 | Stale-reference sweep missing at `METHODOLOGY.md:1811` (3 `scripts/tq-*.sh` GitHub links) | **RESOLVED** | `spec:376-377` adds a Wave-4b sweep `grep -rn "scripts/tq-.*\.sh"`. **Verified by execution:** that pattern returns exactly one live non-plan hit — `METHODOLOGY.md:1811` |
| 10 | External reviewer dependency unowned (round-14 policy abort precedent) | **RESOLVED** | `spec:326` owner Kyle, fallback *"§10.4: max 2 rounds → owner override CR, named in release notes"*; `spec:318` contingency branch cites the round-14 precedent and the de-escalated-prompt fix |
| 11 | npm retention of old client versions had no fallback | **RESOLVED** | `spec:328`: *"If a candidate is unpublished, the floor is the oldest *installable* version — recorded as such, honestly narrower claim"* |
| 12 | **`.gitattributes` AC is not falsifying at HEAD** | **UNRESOLVED** | `spec:44` unchanged. Re-verified at HEAD: no `.gitattributes` file, `core.autocrlf=true`, and **all 14 tracked `.sh` files already report `w/lf`**. The matrix's falsifying half (`acceptance-matrix.md:30`, *"fresh clone on a `core.autocrlf=true` host checks out LF"*) is still absent from the spec |
| 13 | R6 (`GUIDE.md` merge conflicts, 11 findings) has no ticket, gate, or acceptance row | **UNRESOLVED** | No ticket in v2; no row in the new Traceability table |
| 14 | No likelihood/impact ratings on R1–R15 | **UNRESOLVED** | `approach.md` §5 unchanged (locked artifact, orchestrator-owned) |
| 15 | Team: tech reviewer `TBD`; no skills inventory, capacity statement, or continuity plan | **PARTIALLY RESOLVED** | Work-mode capacity now explicit (`spec:306` solo=serial) and buffered (`spec:319`); external-dep owners named. Skills, other-work impact, continuity, and the Phase-1 `TBD` remain open |
| 16 | §8.5 scratch-channel/profile bootstrap consumed by 3 tickets, created by none | **UNRESOLVED** | No ticket in v2; no Traceability row |

**v1 findings: 11 RESOLVED · 1 MOSTLY · 1 PARTIALLY · 4 UNRESOLVED (all LOW–MEDIUM).**

### New items introduced by v2

| # | New item | Severity | Evidence |
|---|---------|:--------:|----------|
| N1 | PHV5-041's band is unchanged (*"medium (inside 040's lane band)"*, `spec:140`) despite the new tokenization / quote-stripping mechanism requirement added at `spec:150-156` — new work, unchanged size | MEDIUM | Band line and mechanism paragraph are in the same ticket |
| N2 | The BLOCKED contingency row (`spec:316`) says *"Waves 1/3 may proceed"* while `approach.md:625` says *"Waves 0, 1, 3, 5 are unblocked"* — Waves 2 and 5 unaddressed under BLOCKED | LOW | Cross-document comparison |
| N3 | `spec:459` claims every item carries *"exactly one owning ticket"*, but F12 maps to **two** (PHV5-070 build, PHV5-071 activation) and runtime proof maps to `PHV5-044 · PHV5-045` | LOW (precision nit) | `spec:449-450`, `spec:457` — deliberate decompositions, not ambiguity |
| N4 | `status.json:114` (`"tickets": 27`, `"estimate_working_days": "22-28"`) now diverges further from the spec (33 tickets; 28–34 envelope) | LOW — **orchestrator-owned** | Outside both the spec's and this audit's write scope; flagged for the consistency-sweep gate |

---

## CHECK 1 — Eight-Dimension Score (v2)

### Dimension 1: Problem Definition — **5/5** *(v1: 5/5, unchanged)*

Unchanged and still fully evidenced. `bash tests/run-all.sh` at HEAD reproduces **115 pass / 4 fail** (L1 84/4 · L2 15 · L3 9 · L4 7), exactly `approach.md:805`, including the documented `^`-anchored grep artifact that hides Layer 2's indented total. The sibling drift reproduces as `78 + 222 = 300` lines. `tests/layer2-hook-simulation.sh:214` asserts `exit 2` **and** stderr `"WARNING"`, literally enshrining F22; `:48-53` extract by positional index, enshrining F23. `brainstorm.md:11-37` states the problem with four concrete instances and full audit provenance. Success criteria remain measurable (`spec:471-473`).

Rubric match: 5/5.

### Dimension 2: Architecture & Design — **5/5** *(v1: 4/5 — +1)*

Both v1 gaps closed:
- HIGH [B]: The F24 mechanism gap is closed at the right level of abstraction. `spec:150-156` names the failure I reproduced (*"reproduced live: the current hook denies a read-only `grep` whose search *pattern* contains a DB-deploy string"*), states the requirement (*"strip or tokenize quoted substrings before pattern matching (or equivalent)"*), and — crucially — makes the corpus binding rather than the implementation: *"the acceptance corpus is the falsifier — a mechanism that fails any corpus row fails PHV5-041, whatever its implementation. Design freedom stays in 4a; the corpus does not."* That is the correct contract shape: it constrains the outcome, not the code, which is a stronger fix than the one I proposed.
- HIGH [A]: The count error is corrected with the measured set named, and I confirmed the six names match my measurement exactly.

Retained strengths: two independent options analyses (`approach.md` §2 weighted 20/11/17; §3.1.0 three lanes); Option C disqualified *"on correctness, not preference"*; ledger row 1 verified absent from `scripts/`; `scripts/tq-git-guard.sh:17` confirms F25 (`git\s+push.*--force\b` matches `--force-with-lease`, while line 18 recommends the flag it blocks); vendor-cited technology choice with honest Tier A/B sourcing in `confidence.md`.

Rubric match: 5/5 — mechanism-level closure with the falsifier pinned.

### Dimension 3: Phasing & Sequencing — **4/5** *(v1: 3/5 — +1)*

Resolved: the Wave 7 suite break (v1's most serious finding), the count-edit ownership across Waves 3/5/7, the ticket-count/traceability drift, and the BLOCKED wave scope.

- HIGH [A]: `spec:234-241` now folds the surface updates into the activation commit and cites both tripwires. I verified the citations are not merely plausible but **complete**: every `/toque:plan` occurrence in `commands/help.md` (lines 16, 30, 32, 48, 49, 52, 185) falls inside the cited ranges `{16} ∪ [30,52] ∪ [185,189]`. The three matches outside the concern (17, 18, 189) are `plan-status`/`plan-export`, whose files survive — correctly excluded.
- HIGH [A]: `tests/layer1-config-wiring.sh:344-354` is the complete assertion block (`readme_cmd_count=0` through the closing `fi`). v2's range is **more precise than my v1 citation** of `:345-353`.
- HIGH [B]: `spec:243-245` adds the missing gate criterion; `spec:396-397` mirrors it in the working checklist with a dedicated stale-reference sweep.
- HIGH [B]: `spec:316` resolves the BLOCKED scope and `spec:327` answers the class-C acceptance question.

Retained strengths: §9 as single sequencing authority; Wave 0's mandatory internal order; the 4a/4b/4c split with *"4b activates what 4a proved; it authors no new logic"*; explicit `Blocks:`/`Depends:` on every ticket; the Wave 7 activation contract.

Residual gap (minor): the BLOCKED row names Waves 1/3 while `approach.md:625` names 0/1/3/5 — Waves 2 and 5 unaddressed under BLOCKED; and the class-C answer is placed in the GitHub Actions dependency row rather than the BLOCKED branch row, so a reader following the BLOCKED path will not find it.

Rubric match: 4/5 — solid evidence with one minor gap.

### Dimension 4: Risk Assessment — **4/5** *(v1: 4/5, unchanged)*

Improved but not enough to move a band:
- HIGH [B]: The three unregistered external risks are now carried with owners and fallbacks (`spec:324-328`), and the reviewer-availability risk gains a contingency branch citing its own precedent (`spec:318`: *"Round-14 precedent (Codex policy filter)… De-escalated prompt framing (proven fix)"*). This closes v1's largest risk gap and my v1 Risk #1.
- The reconciliation with `approach.md` §7 is honest rather than contradictory: `spec:321-322` distinguishes *"no vendor timeline gates the work"* from *"operational dependencies, each with a fallback so none can block indefinitely."*

Retained strengths: fifteen registered risks with executable mitigations; highest-risk waves labelled; R10 honestly downgraded — *"until U6 runs, R10's mitigation is an accepted design, not a demonstrated control"* (`approach.md:555`); contingency for the top risks via CR-1 §Return path, the F26 fallback chain, and the F24/F23 public dispositions.

Residual gaps: no likelihood/impact ratings on R1–R15 (a stated rubric criterion); R6 still has no ticket, no gate, and no Traceability row. Both live in `approach.md`, an orchestrator-owned locked artifact.

Rubric match: 4/5 — holds.

### Dimension 5: Rollback & Safety — **5/5** *(v1: 5/5, unchanged)*

Unchanged and still the plan's strongest dimension. `approach.md:642-690` separates revert from rollback mechanically (*"There is no unpublish"*); the kill switch carries honest limits with a vendor-corrected disable procedure; every wave states a rollback (`spec:32, 128, 201, 240`); 4a is inert until 4b and 4b is one commit; Wave 7 recovers by single revert; and PHV5-082 **executes** the rehearsal (0.0.1→0.0.2, `dist/` restore, uninstall + `/reload-plugins` hook-silence check) rather than assuming it — *"A rollback path that has never been executed is not a rollback path."* Blast radius is stated per host and per lane. Corroborated externally: rollback scored 5/5 in every scored Codex round from 4 through 17.

Rubric match: 5/5.

### Dimension 6: Timeline & Effort — **4/5** *(v1: 3/5 — +1)*

All four v1 gaps closed:
- HIGH [B]: The serial/critical-path contradiction is resolved by distinguishing the two quantities (`spec:306-309`), and the plan's ≈23 d critical-path figure matches the value I computed independently in v1.
- HIGH [A]: A buffer now exists — `spec:319`: *"**Buffer** | Unknown unknowns | +20% ≈ 5–6 d → **realistic envelope 28–34 working days (6–7 calendar weeks)**"*. Arithmetic checks: 20% of 28 = 5.6.
- HIGH [B]: The BLOCKED branch now has a schedule effect (`spec:316`), and reviewer second rounds and policy-aborts each have a row.
- HIGH [B]: External dependencies are on the page with owners and fallbacks.

Retained strength: the sizing basis is measured, not guessed — `approach.md:756-790` bands all 33 findings plus ~30 rows of introduced work, and I reproduced **847** input blocks, **304 blocks / max 22 lines** over a **1,528**-line `commands/plan.md`, and the 22-source arithmetic, all exactly.

Residual gap (N1): PHV5-041's band is still *"medium (inside 040's lane band)"* while the same ticket gained a tokenization requirement. Shell-aware tokenisation or quote-span stripping is not free, and the plan's own §9.3 discipline is that introduced work gets banded.

Rubric match: 4/5 — one minor unsized addition keeps it off 5.

### Dimension 7: Testing & Validation — **4/5** *(v1: 4/5, unchanged)*

Two of three v1 gaps closed — the Wave 7 suite criterion (`spec:243-245`) and the F24 corpus mechanism, which is now explicitly *the falsifier* (`spec:154-156`), strengthening the contract-testing story rather than merely patching it.

Retained strengths: the per-deliverable methodology table (`spec:415-424`) with rationale per class — Characterization/Golden Master for the port (*"The 11-row behavior ledger IS the golden master"*), TDD + Contract for new guard semantics, Snapshot/Approval for the renderer, Characterization + ATDD for the split, Shadow/Parallel for release; Expand/Contract marked N/A **with a verified reason**; separate test authorship addressed head-on (`spec:426-428`); the AI Failure Mode Checklist applied per wave review; seven verification classes; baseline pinned with an expected-red comparator and `continue-on-error` prohibited.

Unresolved gap (v1 finding #12) — the reason this dimension does not reach 5:
- HIGH [A]: `spec:44` still reads *"AC: `git ls-files --eol -- '*.sh'` reports `w/lf` for every script."* Re-verified at HEAD: `.gitattributes` **absent**, `core.autocrlf=true`, and all **14** tracked `.sh` files already report `w/lf`. The criterion is green before the fix. This directly violates the spec's own rule at `spec:431-432`: *"tautological tests (every test must fail on the pre-fix tree or a mutated fixture)."* The falsifying half exists in `acceptance-matrix.md:30` and was not carried across.

Rubric match: 4/5 — a verified tautological acceptance gate is exactly "one minor gap".

### Dimension 8: Team & Resources — **3/5** *(v1: 2/5 — +1)*

Improved on two of five criteria:
- HIGH [B]: Work mode is now an explicit capacity statement — `spec:306`: *"**Solo means serial: the cumulative column IS the schedule.**"* That converts an implicit assumption into a stated constraint.
- HIGH [B]: A capacity buffer exists (`spec:319`, 28–34 days).
- HIGH [B]: External-dependency ownership is now named (`spec:326-328`, owner Kyle for all three) with fallbacks that prevent indefinite blocking — closing v1's gap 5.
- Retained: a single unambiguous accountable owner (`brainstorm.md:104`), and R5's acknowledgement that *"one maintainer reviews their own highest-risk work"* with §10.4 as the compensating control.

Remaining gaps: `brainstorm.md:105` still reads *"Tech reviewer | TBD"* with no recorded solo-mode waiver; no skill-set inventory for work spanning Node/JS authoring, first-ever GitHub Actions workflows, PowerShell variants, and a segmenter/checker implementation; no statement of what other work pauses across 6–7 calendar weeks; and no continuity plan for a bus factor of 1, where in-flight state (scratch profiles, probe plugins, credentialed channels) exists on one machine only.

Rubric match: 3/5 — section exists with notable gaps; no longer critically incomplete.

---

## CHECK 2 — Devil's Advocate Premortem (v2 delta)

The v1 premortem stands except where the revision changed the answer. Re-running the four questions against v2:

**"If this fails in production, what is the most likely reason?"** — Unchanged: a node-less install silently loses the guard layer. v2 does not add a post-release feedback loop, so the observability warning persists. The plan's controls (CR-1's U6 condition, the BLOCKED branch, the migration-note prerequisite, the 4c node-less installed-copy case) remain pre-release. **[VERIFY WITH AUTHOR]** — still worth one post-release signal.

**"What did we assume would be true but isn't?"** — v1's answer (the F24 corpus is satisfiable by field extraction) is now the spec's own stated problem, with the corpus made binding. The assumption is retired. The *new* soft assumption is N1: that adding quote-tokenisation to the matcher fits inside an unchanged "medium" band.

**"What changed in one layer but not another?"** — v1's two instances are both closed and I verified the sweeps actually bite: `grep -rn "scripts/tq-.*\.sh"` returns exactly one live non-plan hit (`METHODOLOGY.md:1811`), so the Wave-4b checklist item will surface it; and Wave 7's file list plus its own `commands/plan.md` sweep (`spec:397`) covers the command-surface layer. The residual asymmetry is N2 — the BLOCKED branch enumerates Waves 1/3 while the sequencing authority enumerates 0/1/3/5.

**"What works in tests but fails at runtime?"** — v1's answer is **still live**. The `.gitattributes` criterion is green at HEAD and would be green in CI both before and after the fix, proving nothing about the behaviour it guards (what a fresh clone on an autocrlf host checks out). Of all v1 findings this was the cheapest to fix and it is the one that did not land.

**Solo timeline (22–28 → 28–34).** The revision's honesty here is the single largest improvement: it abandons the interleaving optimism, states that solo means serial, and adds a 20% buffer. 28–34 working days at 6–7 calendar weeks is a defensible envelope for this scope. The remaining strain is that three external review cycles still sit on the critical path with turnaround absorbed into the buffer rather than itemised — acceptable now that the fallback (owner override CR after two rounds) guarantees they cannot deadlock.

**G0 BLOCKED branch.** Materially better: it now has a schedule effect, a stated wave scope, and an answer for interim verification (*"Local suite runs remain authoritative interim"*). Two residuals: Waves 2/5 are unenumerated, and the interim-verification answer is filed under the GitHub Actions dependency rather than the BLOCKED branch, so it is reachable only by a reader who thinks to look there.

**CR-1's U6 condition.** Unchanged and still correctly structured: lane-N PASS requires the visibility evidence (`spec:67-69`), the failure branch is defined (CR-1 §Return path, three enumerated owner options), and v2 now attaches a schedule consequence to it.

**Wave 6 reconciliation workload.** Unchanged by v2. Against the verified 847-block corpus, round 10's ratified 275 auto-seeded matches leave ≈572 blocks to the manual pass — 68%, larger than *"keeps the manual pass tractable"* implies. **[VERIFY WITH AUTHOR]** — was the 275/45 split measured over all 22 sources or over the nine technique pairs only? This remains the plan's most likely overrun and the +20% buffer is now its cover.

**Could the spec's compressed criteria drift from their matrix rows?** v2 substantially reduces this: the new Traceability table (`spec:437-459`) makes the spec↔matrix mapping explicit and I verified all 33 F-IDs and all 33 ticket IDs now appear. One drift survives — the `.gitattributes` AC, where the spec still carries half of the matrix row.

---

## CHECK 3 — Codebase Verification (v2)

v1's 26 checks stand (25 confirmed, 96%): `tq-git-guard.sh:27`, `run-all.sh` 4-layer structure, the unwired `codex-challenge-test.js`, `marketplace.json` duplicate version + missing description, `plan.md` 1,528 lines, `security-scanner.md:11`, `README.md:84`, `GUIDE.md:5`, `help.md:144`, the 4 templates, the 115/4 baseline, the 300-line drift, the 22 sources, 304 blocks/max 22, 847 blocks, F17/F01/F25, the Layer 2 enshrinements, ledger row 1, absent `.gitattributes`/`.github`/`dist`/`hooks`, and every spec §-reference resolving into `approach.md`.

Seven **new** checks were run against citations the revision introduced:

| # | v2 claim (source) | Verification | Result |
|---|------------------|-------------|--------|
| 27 | `commands/help.md` `/toque:plan` refs at `:16`, `:30–:52`, `:185–:189` (`spec:237-238`) | All `/toque:plan` occurrences are at 16, 30, 32, 48, 49, 52, 185 — **every one inside the cited ranges**. Matches at 17/18/189 are `plan-status`/`plan-export` (files survive), correctly excluded | **EXACT & COMPLETE** HIGH [A] |
| 28 | `tests/layer4-behavioral-smoke.sh:48-54` fails on a help.md command without a file (`spec:238`) | `:50-51` — `if [[ ! -f "$PLUGIN_ROOT/commands/$CMD_NAME.md" ]]; then fail …` | **EXACT** HIGH [A] |
| 29 | `tests/layer1-config-wiring.sh:344-354` compares README count to `commands/` file count (`spec:239`) | `:344` `readme_cmd_count=0` … `:354` `fi`; assertion at `:350-353` | **EXACT — more precise than v1's `:345-353`** HIGH [A] |
| 30 | 6 agents carry `tools:` flow arrays, named (`spec:103-105`) | `grep -l '^tools: \[' agents/*.md` → exactly the six named files | **EXACT** HIGH [A] |
| 31 | Wave-4b sweep `grep -rn "scripts/tq-.*\.sh"` catches retired-path references (`spec:376-377`) | Returns exactly one live non-plan hit: `METHODOLOGY.md:1811` (three GitHub links) — the v1 gap site | **CONFIRMED — sweep bites** HIGH [A] |
| 32 | Traceability covers all 33 findings + additions + gates (`spec:459`) | All 33 F-IDs present in the spec (F05/F06 added); 33 unique `PHV5-NNN` IDs; every matrix row maps to a named ticket | **CONFIRMED** (nit N3: F12 → two tickets) HIGH [A] |
| 33 | `.gitattributes` AC still falsifiable? (`spec:44`, unchanged) | `.gitattributes` **absent**; `core.autocrlf=true`; all **14** tracked `.sh` report `w/lf` — AC green before the fix | **STILL NON-FALSIFYING** HIGH [A] |

**Cumulative codebase verification: 32 of 33 checks confirmed (97%).** The one non-confirmation is finding #12, an unresolved spec defect rather than a false claim.

---

## CHECK 4 — Gap Verification (v2)

### OUTPUT A — Coverage Matrix

**Goals** (`brainstorm.md:39-58`)

| # | Goal | Wave(s) | Ticket(s) | Test | v1 | v2 |
|---|------|---------|-----------|------|:--:|:--:|
| G1 | Correctness first | 1, 2 | PHV5-010/011/012/020/021 | L1 uniqueness + reverse sweep [U, G] | COVERED | COVERED |
| G2 | One source of truth for hooks | 4a/4b/4c | PHV5-040…044 | F05/F06/F23 rows [U, R, I] | COVERED | COVERED |
| G3 | No phantom references | 1, 4b, 5, 6, 7 | PHV5-010, 043, 050, 053, 061, 071 | sweeps [G] + installed-copy [I] | PARTIAL | **COVERED** — W4b/W5/W7 sweeps added |
| G4 | Honest self-description | 3, 5, 7, 8 | PHV5-030/031/053/071/080 | L1 version+count [U] | PARTIAL | **COVERED** — each wave owns its count edit |
| G5 | Resolve plugin/skill duplication | 6 | PHV5-060…063 | L6 + exact-consumption [U, C] | COVERED | COVERED |
| G6 | Prove it | 0 + interleaved | PHV5-002/005 + per-wave | L5/L6/L7 + comparator [U, C] | COVERED | COVERED |

**Risks** — all fifteen carry mitigations. Change from v1: **R6 remains the sole GAP** (*"Serialize through one branch"* has no ticket, gate, acceptance row, or Traceability row). R5/R12/R14 additionally strengthened by the new external-dependency fallbacks.

**Dependencies**

| Dependency | Type | Owner | Fallback | v1 | v2 |
|-----------|------|-------|----------|:--:|:--:|
| Internal wave order | internal | §9 authority | — | COVERED | COVERED |
| Non-Claude reviewer (Codex CLI) | external | **Kyle** (`spec:326`) | §10.4 max 2 rounds → owner override CR | **GAP** | **COVERED** |
| GitHub Actions availability | external | **Kyle** (`spec:327`) | local suite authoritative interim; CI-enable is Wave 0's last step | **GAP** | **COVERED** |
| npm retention of old client versions | external | **Kyle** (`spec:328`) | floor = oldest *installable*, recorded as a narrower claim | **GAP** | **COVERED** |
| GitHub push/tag access | external | owner implicitly | — | WARNING | WARNING |
| Claude Code client behavior | external, vendor | resolved by G0/U6/U7 | BLOCKED branch | COVERED | COVERED |

**Gates** — G0 (PHV5-004, incl. BLOCKED branch **now with a schedule effect and wave scope**), G1 (PHV5-004 + PHV5-084), U7 (PHV5-003 + PHV5-005). All COVERED; G0's residual is N2.

**Non-Goals** — re-verified clean: no backlog item appears in any ticket; `approach.md:752` holds prose rewriting out of scope; identifiers stay stable; `skills/plan/` is a net-zero-surface replacement justified at §3.2.

**Coverage Matrix result: 40 items traced · v1 3 GAPs + 2 PARTIALs → v2 1 GAP (R6) · 0 PARTIALs.**

### OUTPUT B — Assumption Register

| # | Assumption | Impact if false | How to verify | By when | Owner | Status |
|---|-----------|----------------|---------------|---------|-------|--------|
| A1 | Node exec-form fires on this host | Lane falls to B or I; no scope loss | PHV5-004 probe from PowerShell | Wave 0 | Kyle | UNVERIFIED — HIGH, **by design**, BLOCKED branch defined |
| A2 | U6 shows node-absent failure user-visibly (CR-1 condition) | CR-1 void → G0 BLOCKED → Wave 4 does not start | PHV5-004, node hidden from PATH | Wave 0 | Kyle | UNVERIFIED — HIGH, **by design**, branch now schedules the pause (`spec:316`) |
| A3 | Old client versions remain npm-installable | U7 floor undiscoverable | PHV5-003 bisection, ≤8 probes | Wave 0 | Kyle | UNVERIFIED — HIGH, **fallback added v2** (`spec:328`) |
| A4 | The 22 sources still exist to snapshot | Wave 6 loses its baseline; R9/R11 unmitigable | Verified by audit: 9 pairs + 4 sibling-only; 300-line drift reproduced | — | auditor | **VERIFIED** HIGH [A] |
| A5 | Solo capacity fits the envelope | Slippage concentrates at the end (Waves 6/7 are largest and last) | `spec:306` states solo=serial; `spec:319` buffers +20% → 28–34 d | — | Kyle | **PARTIALLY VERIFIED v2** — stated and buffered, not measured |
| A6 | Independent reviewer available for 3 waves × ≤2 rounds | Waves 4/6/7 cannot GO → release blocked | Owner + fallback + policy-abort branch (`spec:318`, `:326`) | per wave | **Kyle** | **RESOLVED v2** — was the un-designed HIGH-impact gap |
| A7 | GitHub Actions available on `krwhynot/toque` | Wave 0 GO unreachable; class-C rows unsatisfiable | Owner + interim fallback (`spec:327`) | Wave 0 | Kyle | **RESOLVED v2** |
| A8 | F24 corpus satisfiable by field extraction + regex | Corpus row unpassable or silently dropped | Falsified by audit (live grep denial) | — | auditor | **RETIRED v2** — `spec:150-156` replaces the assumption with a mechanism requirement |
| A9 | `.gitattributes` AC fails at HEAD | A green-before-and-after gate ships | Falsified by audit — 14/14 `.sh` already `w/lf` | — | auditor | **STILL FALSIFIED — UNRESOLVED** |
| A10 | Wave 6 auto-seeding leaves a tractable remainder | Wave 6 overruns on the critical path | 275/45 vs 847 ⇒ ≈572 manual | Wave 6 | Kyle | UNVERIFIED — MEDIUM; `[VERIFY WITH AUTHOR]`; now covered by the +20% buffer |
| A11 | Waves 1–3/5 proceed under BLOCKED | Plan stalls, or waves proceed unacceptable | `spec:316` (Waves 1/3) + `spec:327` (local suite interim) | Wave 0 | Kyle | **MOSTLY RESOLVED v2** — Waves 2/5 unenumerated (N2) |
| A12 | Deleting `commands/plan.md` leaves the suite green | Layer 4 + Layer 1 red, no owning ticket | Falsified in v1 | — | auditor | **RESOLVED v2** — `spec:234-245` |
| A13 | *(new)* Quote-tokenisation fits PHV5-041's unchanged "medium" band | Wave 4a overruns | none defined | — | Kyle | UNVERIFIED — MEDIUM (N1) |

**Unverified HIGH-impact assumptions: A1, A2, A3 — all three verified by PHV5-003/004 in Wave 0, with a named by-when, a named owner, a defined BLOCKED branch, and (new in v2) a fallback for A3.** The v1 outlier — A6, HIGH-impact with no owner, no method and no by-when — is closed.

### OUTPUT C — Scenario Matrix

| Scenario | Planned? | Wave / ticket | Tested? | Monitored? | v1 | v2 |
|----------|:--------:|---------------|---------|-----------|:--:|:--:|
| Happy path | YES | 4c PHV5-044; 8 PHV5-083 | Layer 7 + installed copy [R, I]; Flows A/B un-simulated | CI + canary | COVERED | COVERED |
| Failure path | YES | 4a PHV5-041 | malformed → fail-closed; no-parser → static JSON; node-absent → vendor notice [U, C, R] | hook-error notice | COVERED | COVERED |
| Partial rollout / mixed state | YES | 4a PHV5-040 row 8; §8.4 | tolerant read of both tracker keys; 0.0.1→0.0.2 rehearsal | — | PARTIAL | PARTIAL (unchanged — mid-session state still procedural) |
| Backward compatibility | YES | 0 PHV5-003/005; 8 PHV5-080 | floor + current CI; migration note; §8.4 | CI floor job | COVERED | COVERED |
| Scale / volume edge | YES | 6 PHV5-060/061; 7 PHV5-070(f) | exact-consumption over 847/~513; manifest over 1,528 lines | Layer 6 | COVERED | COVERED (A10 warning; now buffered) |
| Auth / permission edge | YES | 0 PHV5-005; 8 PHV5-083 | R15 no secrets in required jobs; profile split; Flow B authenticates in place | job classification | COVERED | COVERED |
| Config / environment difference | YES | 0 PHV5-004/005; 4c PHV5-044 | host matrix 4×3; windows+ubuntu × floor+current; parser-degradation jobs | CI matrix | COVERED | COVERED |
| Rollback path | YES | 8 PHV5-082 | **executed**: forward rollback, `dist/` restore, hook-silence check [B, I] | — | COVERED | COVERED |

**Scenario Matrix result: 8 scenarios · 0 GAPs · 1 PARTIAL (unchanged from v1).**

### OUTPUT D — Cross-Cutting Concern Sweep

| Concern | v1 | v2 | Where |
|---------|:--:|:--:|-------|
| API contract (hook payload) | PARTIAL | **ADDRESSED** | `spec:150-156` mechanism requirement; corpus binding |
| UI behavior | N/A | N/A | CLI plugin; only `systemMessage` + doc text, both in scope |
| Auth / authz | ADDRESSED | ADDRESSED | R15; §8.5 profile kit; PHV5-083 Flow A/B isolation |
| Config | ADDRESSED | ADDRESSED | `plugin.json`, `marketplace.json`, `hooks.json`, `.claude/settings.json`, `.gitattributes`, `TQ_*` |
| CORS / network / browser | N/A | N/A | Only npm (PHV5-003) and GitHub (PHV5-083), both covered |
| Data model / query limits | N/A (DB) | N/A (DB) | No database — Expand/Contract N/A verified; `tq-*` tracker governed by §8.4 |
| Pagination | N/A | N/A | No list/API surface |
| **Caching (plugin cache semantics)** | ADDRESSED | ADDRESSED | §8.1 versioned cache; *"the version is the cache key"*; PHV5-044 installed-copy; PHV5-083 excludes `.in_use`; §8.3 `/reload-plugins` |
| Observability | PARTIAL | PARTIAL | `spec:463-465` — CI + comparator + canary + hook-error notices. **Warning persists: no post-release feedback loop** |
| Migration / backward compat | ADDRESSED | ADDRESSED | PHV5-080 migration note; §8.4 |
| Rollout / rollback | ADDRESSED | ADDRESSED | §8.1–8.5; PHV5-082; PHV5-083; per-wave rollback |
| Tests | ADDRESSED | ADDRESSED | 7 layers, methodology table, comparator (A9 defect persists) |
| **String path references (Waves 4/6/7)** | **GAP ×2** | **ADDRESSED** | W4b `spec:376-377` (verified to catch `METHODOLOGY.md:1811`); W5 F30 `spec:385`; W6 F16; W7 `spec:397` |

**Cross-Cutting result: 13 concerns · v1 2 GAPs + 2 PARTIALs → v2 0 GAPs · 1 PARTIAL · 4 N/A (all with reasons).**

### Plan Lint Results (v2)

| Rule | Description | v1 | v2 | Evidence for the v2 result |
|------|-----------|:--:|:--:|---------------------------|
| LINT-01 | Every goal has a mapped ticket | PASS | **PASS** | All 6 goals map to ≥1 wave and ≥1 ticket; G3/G4 strengthened |
| LINT-02 | Every HIGH risk has a mitigation | PASS | **PASS** | R1–R15 each carry a named mitigation |
| LINT-03 | Every deployment has a rollback | PASS | **PASS** | Every wave states rollback; Wave 8 rehearses it (PHV5-082) |
| LINT-04 | Every external dependency has an owner | **FAIL** | **PASS** | `spec:321-328` — three dependencies, owner Kyle, each with a named fallback; reconciled against §7 rather than contradicting it |
| LINT-05 | Every new endpoint has a contract/test | PASS | **PASS** | §3.1.6 payload contract + PHV5-044 observes every event **and matcher** |
| LINT-06 | Backward compat has a mixed-state scenario | PASS (warn) | **PASS** (warn) | §8.4 + ledger row 8; mid-session state remains procedural |
| LINT-07 | Every new behavior has a test delta | PASS | **PASS** | Falsifying positive+negative per matrix row; L5/L6/L7 added |
| LINT-08 | No unverified HIGH-impact assumptions | **FAIL** | **PASS** | v1's FAIL rested on A6 being the *un-designed* case; A6 now has owner + fallback + contingency (`spec:318`, `:326`), and A3 gained a fallback (`spec:328`). A1–A3 remain unverified **by design** with named verification tickets, a by-when (Wave 0), and a defined BLOCKED branch — the rule's intent |
| LINT-09 | No unaddressed cross-cutting concern | **FAIL** | **PASS** | Both stale-reference gaps closed; the W4b sweep verified by execution to surface `METHODOLOGY.md:1811` |
| LINT-10 | Every phase has go/no-go criteria | PASS | **PASS** | All 9 waves; Wave 7's now includes full-suite-green |
| LINT-13 | Options analysis with ≥2 alternatives | PASS | **PASS** | §2 (3 options, weighted) + §3.1.0 (3 lanes) |
| LINT-15 | "Tested" claims have verified test infra | PASS (warn) | **PASS** (warn) | Every not-yet-existing artifact names a creating ticket; §8.5 scratch bootstrap still unowned |
| LINT-16 | "Monitored" claims have verified monitoring infra | PASS (warn) | **PASS** (warn) | CI + canary via PHV5-005; in-product notice contingent on U6 |
| LINT-17 | Every spec ticket resolves to a matrix row *(local rule)* | **FAIL** | **PASS** | `spec:437-459` Traceability table; all 33 F-IDs and 33 ticket IDs verified present; F05/F06 now named. Nit N3 (F12 → two tickets) is a decomposition, not ambiguity |
| LINT-18 | Every numeric claim reproducible at HEAD *(local rule)* | **FAIL** | **PASS** | `spec:103-105` records the measured **6** with all six named, matching my measurement exactly. The locked docs' "7" is now an explicitly flagged measurement note, not an active claim |

**Lint: v1 10/15 → v2 15 / 15 passed · 0 failed · 4 carrying warnings.**

### Infrastructure Verification (v2)

All 14 artifacts re-checked. Every not-yet-existing artifact still names a creating ticket (`tests/layer6-drift-check.sh` → PHV5-062; `layer7-runtime-proof.sh` → PHV5-044; `.github/workflows/` → PHV5-005; `dist/` → PHV5-062; `hooks/hooks.json` → PHV5-043; snapshots → PHV5-001; `research/` U6/U7 artifacts → PHV5-003/004; `reviews/` → PHV5-045/063/071; `expected-failures.txt` → PHV5-002).

**INFRA-GAP: 0. WARNING: 1 (unchanged)** — the §8.5 scratch-channel/credentialed-profile bootstrap is a prerequisite of PHV5-044, PHV5-082 and PHV5-083, is sized in `approach.md:780`, but has no creating ticket and no row in the new Traceability table.

### Gap Summary (v2)

```
Lint:                15 / 15 passed · 0 failed  (v1: 10/15)      [+5]
Coverage Matrix:     40 items · 1 GAP (R6) · 0 PARTIALs          (v1: 3 GAPs + 2 PARTIALs)
Assumption Register: 13 assumptions · 3 unverified HIGH-impact,
                     ALL by design with owner + by-when + branch (v1: 4, one un-designed)
                     · 1 still FALSIFIED (A9, .gitattributes AC)
Scenario Matrix:      8 scenarios · 0 GAPs · 1 PARTIAL            (unchanged)
Cross-Cutting Sweep: 13 concerns · 0 GAPs · 1 PARTIAL · 4 N/A     (v1: 2 GAPs + 2 PARTIALs)
Infrastructure:      14 artifacts · 0 INFRA-GAPs · 1 WARNING      (unchanged)

REGRESSIONS:            0
Total distinct gaps:    4   (v1: 11)
Total warnings:         8   (v1: 9)
Gap-checked:          YES   (all four structured outputs produced)
```

---

## Calibration (v2)

- Contradictions found and resolved: **1.** I initially flipped LINT-08 to PASS on the strength of the whole assumption register; on re-reading my own v1 wording (*"FAIL (by design)… A6 is the un-designed failure"*) I confirmed the v1 FAIL rested specifically on A6, which v2 closes. A1–A3 are unchanged and were always designed-unverified, so the flip is driven by new evidence, not by re-reading old evidence more generously. Recorded explicitly in the lint table rather than flipped silently.
- Score adjustments after calibration: **1.** Dimension 2 was provisionally held at 4/5 pending whether the mechanism requirement was real or decorative; `spec:154-156` makes the corpus the falsifier and binds any implementation to it, which is a stronger contract than the fix I recommended, so it moved to 5/5.
- Anchoring check against upward drift: three dimensions deliberately did **not** move. Testing held at 4/5 because a verified tautological AC still ships; Risk held at 4/5 because no likelihood/impact ratings were added and R6 is still ungated; Team moved only 2→3, not higher, because four of five rubric criteria remain unmet. Score spread is **3–5** across eight dimensions.
- Cross-check: 15/15 lint against 34/40 dimensions is consistent — lint rules are binary structural checks that v2 targeted directly, while dimension scores weigh residual quality (the unsized band, the tautological AC, the missing continuity plan) that no lint rule captures.

---

## Scorecard (v2)

| # | Dimension | v1 | **v2** | Δ | Confidence | Key strength (evidence) | Remaining gap |
|---|-----------|:--:|:------:|:-:|:----------:|------------------------|---------------|
| 1 | Problem Definition | 5/5 | **5/5** | — | HIGH [A] | Baseline 115/4 and 300-line drift reproduced exactly | None |
| 2 | Architecture & Design | 4/5 | **5/5** | **+1** | HIGH [A] | `spec:154-156` — *"the acceptance corpus is the falsifier… Design freedom stays in 4a; the corpus does not"* | None |
| 3 | Phasing & Sequencing | 3/5 | **4/5** | **+1** | HIGH [A] | Wave 7 file list + tripwire citations verified **complete** against help.md | BLOCKED row omits Waves 2/5 (N2) |
| 4 | Risk Assessment | 4/5 | **4/5** | — | HIGH [B] | External risks registered with owners and fallbacks (`spec:324-328`) | No likelihood/impact ratings; R6 ungated |
| 5 | Rollback & Safety | 5/5 | **5/5** | — | HIGH [B] | Rehearsal executed, not assumed (PHV5-082) | None |
| 6 | Timeline & Effort | 3/5 | **4/5** | **+1** | HIGH [A] | Solo=serial reconciliation + 20% buffer → 28–34 d envelope | PHV5-041 band unsized for new mechanism (N1) |
| 7 | Testing & Validation | 4/5 | **4/5** | — | HIGH [A] | Corpus made the binding falsifier; Wave 7 suite criterion added | **`.gitattributes` AC still green at HEAD** (v1 #12) |
| 8 | Team & Resources | 2/5 | **3/5** | **+1** | HIGH [B] | Solo=serial capacity statement; external-dep owners named | Reviewer `TBD`; no skills / other-work / continuity plan |

## Overall Score: **34 / 40 — GREEN** *(v1: 30/40 YELLOW · Δ +4)*

---

## Top 3 Remaining Gaps

1. **The `.gitattributes` acceptance criterion is still not falsifying** (v1 finding #12, unresolved). `spec:44` asserts `git ls-files --eol -- '*.sh'` reports `w/lf`; re-verified at HEAD that all 14 tracked scripts already satisfy it with no `.gitattributes` and `core.autocrlf=true`. A gate that is green before and after the fix violates the spec's own rule at `spec:431-432`.
   *Fix (one line):* append the matrix's falsifying half — *"and a fresh clone on a `core.autocrlf=true` host checks out LF"* (`acceptance-matrix.md:30`). Can ride Wave 0; does not block Build.

2. **Team continuity and skills remain undocumented; the Phase-1 tech-reviewer `TBD` is still open.** `brainstorm.md:105` is unchanged. With a bus factor of 1 and in-flight state (scratch profiles, probe plugins, credentialed channels) living on one machine across Waves 0–4, and a 6–7 calendar-week envelope, no document states what other work pauses or what happens if the maintainer is unavailable.
   *Fix:* record the solo-mode waiver with its documented reason, add a one-line capacity statement, and commit the §8.5 scratch-channel bootstrap as a script so the environment is reproducible rather than resident.

3. **PHV5-041's band was not re-sized for the mechanism it gained** (N1). The ticket is still *"Band: medium (inside 040's lane band)"* while now requiring quote-tokenisation or equivalent — non-trivial work in the plan's highest-risk wave, and `approach.md` §9.3's own discipline is that introduced work gets banded.
   *Fix:* re-band PHV5-041 (or state explicitly that the mechanism is absorbed by 040's large band and why), and add a §9.3 row.

Two lesser residuals, both LOW: the BLOCKED contingency row enumerates Waves 1/3 while the sequencing authority enumerates 0/1/3/5 (N2), and `spec:459`'s *"exactly one owning ticket"* is imprecise for F12 (N3). Separately, `status.json:114`'s `"tickets": 27` / `"estimate_working_days": "22-28"` now diverge from the spec's 33 tickets and 28–34 envelope — **orchestrator-owned**, outside this audit's and the spec's write scope, flagged for the consistency-sweep gate.

---

## Top 5 Risks (v2)

| # | Risk | Likelihood | Impact | In plan? | Change from v1 |
|---|------|:----------:|:------:|:--------:|----------------|
| 1 | Wave 6 manual reconciliation (≈572 of 847 blocks) overruns on the critical path | MEDIUM | MEDIUM | PARTIAL — sized from occurrence volume; auto-seed ratio not stated | **Now #1** (was #4). Mitigated by the new +20% buffer; still the most likely overrun |
| 2 | Solo maintainer unavailable mid-project; bus factor 1, no continuity plan | LOW | **HIGH** | **NO** | Unchanged — the largest unhedged risk after v2's fixes |
| 3 | A node-less install loses the guard layer and no post-release signal reveals it | MEDIUM | MEDIUM | PARTIAL — CR-1 + U6 + migration note are all pre-release | Unchanged; observability remains PARTIAL |
| 4 | PHV5-041's tokenisation work exceeds its unchanged band, extending the highest-risk wave | MEDIUM | LOW–MEDIUM | **NO** (N1) | **New in v2** — introduced by the gap-2 fix |
| 5 | `G0 = BLOCKED` stalls the plan pending owner decision | LOW–MEDIUM | MEDIUM | **YES** | **Downgraded from v1 #2** — now has a schedule effect, a wave scope, and an interim-verification answer |
| — | *Reviewer availability blocks Waves 4/6/7* | — | — | **RESOLVED** | v1 #1 — closed by `spec:318`, `:326` |
| — | *Wave 7 activation reds the suite* | — | — | **RESOLVED** | v1 #3 — closed by `spec:234-245` |

---

## Go / No-Go Assessment (v2)

**GO if:** score ≥ 32 and gap-checked YES. **Both conditions are met — 34/40 GREEN, gap-checked YES, 15/15 lint, zero regressions.**

**NO-GO if:** a regression is found, or a top-3 gap is a blocker. Neither applies: the three remaining gaps are a one-line AC edit, a documentation/continuity item, and a band re-estimate — none gates the start of Wave 0, which is pure additions with a clean revert path.

### Recommendation: **GO**

The revision did what a good revision does: it fixed mechanisms rather than adding assurances. The Wave 7 fix does not merely promise to update the help text — it names the exact line ranges and the two test assertions that will catch the omission, and I verified those ranges bracket every affected occurrence. The F24 fix does not merely acknowledge the reproduction — it makes the acceptance corpus the falsifier and leaves implementation free, which is a stronger contract than the one I proposed. The timeline fix does not merely add a buffer — it reconciles the two figures that were in tension, states the solo=serial constraint explicitly, and gives every external dependency an owner and a fallback that prevents indefinite blocking.

Three gaps remain and all three are cheap. The `.gitattributes` criterion should be corrected before Wave 0 executes it, since it is the only place in the plan where a gate would report success without testing anything. The team-continuity items are worth an hour of writing before a 6–7 week solo commitment. The PHV5-041 band should be revisited when Wave 4 is scheduled, not now. **Proceed to the Build gate.**

---

## Leadership Presentation Outline

1. **The problem, in one number.** A 33-defect plugin whose own test suite covers 2 of them and asserts 2 as correct — verified by re-running the suite (115 pass / 4 fail).
2. **What we are shipping.** v5.0.0 closes all 33 plus 3 conformance additions, with every shortfall (F24 PARTIAL, F23 under lane I) recorded publicly rather than claimed away.
3. **Why we believe the plan.** A 17-round adversarial external review converging 19 → 40/40, plus an independent audit that reproduced 32 of 33 codebase claims — including three measured figures to the digit.
4. **The two empirical gates.** G0 and U7 resolve in Wave 0 *before* any risky work, and a BLOCKED outcome now has a defined pause, wave scope, and interim-verification answer.
5. **What the audit changed.** Three gaps found and fixed in one revision cycle: a wave that would have broken the test suite, a security criterion that outran its mechanism, and a schedule with no buffer. Score 30 → 34 / 40, YELLOW → GREEN, zero regressions.
6. **The ask.** Approve the Build gate. Ship decision remains Wave 8's gate, behind three independent review GOs. Realistic envelope: 28–34 working days, 6–7 calendar weeks, solo.

---

## Suggested Modifications (v2, priority order)

1. Append the falsifying half to PHV5-002's `.gitattributes` AC (`spec:44`) — *"and a fresh clone on a `core.autocrlf=true` host checks out LF"*.
2. Resolve `brainstorm.md`'s `Tech reviewer: TBD` (assign, or record the solo-mode waiver with its reason); add a one-line capacity/other-work statement and a minimal continuity note.
3. Re-band PHV5-041 for the tokenisation mechanism, or state explicitly that 040's large band absorbs it; add the §9.3 row.
4. Give the §8.5 scratch-channel/profile bootstrap its own ticket and Traceability row — three tickets consume it and none creates it.
5. Extend the BLOCKED contingency row to enumerate Waves 2 and 5 alongside 1 and 3 (`approach.md:625`), and move the *"local suite runs remain authoritative interim"* answer into the BLOCKED row where a reader following that branch will find it.
6. Add a ticket or gate for R6 (`GUIDE.md` serialized through one branch) — 11 findings touch that file across five waves.
7. Add likelihood/impact ratings to R1–R15 so the register is sortable *(orchestrator: `approach.md` is a locked artifact)*.
8. Soften `spec:459` from *"exactly one owning ticket"* to *"exactly one owning ticket (F12 and the 4c proof are deliberately decomposed across two)"*.
9. Define one post-release signal beyond CI — even an issue-template question ("do you have node on PATH?") converts the node-less risk from invisible to reportable.
10. **Orchestrator:** sync `status.json` `tickets` (27 → 33) and `estimate_working_days` ("22-28" → "28-34") to the spec, through the consistency-sweep gate.

---

## Confidence Summary (v2)

| Tier | Count | Meaning |
|------|:-----:|---------|
| HIGH [A] (deterministic) | 41 | File existence, line content, executed commands, reproduced counts, `git diff` |
| HIGH [B] (verified) | 26 | Direct quotes from plan text with file:line |
| MEDIUM [B] (inferred) | 4 | Cross-document reading, count reconciliation |
| LOW [C] (speculated) | 3 | Tagged `[PLAN-GAP-INFERRED]` / `[VERIFY WITH AUTHOR]` (skills, continuity, Wave 6 auto-seed ratio) |
| UNVERIFIED | 0 | — |

## Verification Statistics (cumulative)

- Codebase claims verified: **32 of 33 (97%)** — 26 from v1, 7 new v2 citations, one unresolved defect
- Numeric claims reproduced exactly: **9 of 9 (100%)** after v2's flow-array correction *(v1: 8/9)*
- Regression surface examined: **9 deleted lines, all with strictly stronger replacements — 0 regressions**
- v1 candidate findings: 19 → 11 confirmed, **5 dropped as false positives (26% FP prevention)**
- v1 findings disposition: **11 RESOLVED · 1 MOSTLY · 1 PARTIALLY · 4 UNRESOLVED**
- v2 new items: **4 (1 MEDIUM, 3 LOW)**

---

## Revision History

| Ver | Date | Trigger | Result | Principal changes |
|-----|------|---------|--------|-------------------|
| v1 | 2026-07-29 | Phase 5 audit of spec v1 (`c183880`) | **30/40 YELLOW** · gap-checked YES · lint 10/15 | Initial audit. Four gap-verification outputs produced. 26 codebase checks, 25 confirmed. Top 3 gaps: Wave 7 suite break (`layer4:48-54`, `layer1:345-353`); F24 in-field-quotation mechanism (reproduced live); timeline BLOCKED branch / buffer / external dependencies. Recommendation: CONDITIONAL-GO → auto-revision triggered (score < 32). |
| **v2** | 2026-07-29 | Re-audit of spec v2 (revision iteration 1 of 2; `+76/−9` vs v1) | **34/40 GREEN** · gap-checked YES · lint **15/15** · **regressions 0** | All three top-priority v1 gaps RESOLVED with verified mechanisms; all 5 failing lint rules flipped to PASS on independently verified evidence; 7 new codebase citations checked, all exact (`help.md` ranges bracket every `/toque:plan` occurrence; `layer1:344-354` more precise than v1's citation; the W4b sweep confirmed to catch `METHODOLOGY.md:1811`). Dimensions moved: Architecture 4→5, Phasing 3→4, Timeline 3→4, Team 2→3; Testing held at 4 on the unresolved `.gitattributes` AC. v1 findings: 11 resolved, 1 mostly, 1 partially, 4 unresolved. 4 new LOW/MEDIUM items. Recommendation: **GO — clears the Build gate.** |
