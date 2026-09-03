# Make /toque:plan the centerpiece the rest of the toolkit agrees with — Specification

- Derived from: intent.md (Status: Accepted, Kyle, 2026-09-03)
- Author: agent draft; human reviewer Kyle
- Status: Draft
- Date: 2026-09-03

## Requirements

### Functional

**FR-1 (P0) — One verdict currency.**
No tool that judges a plan emits a numeric score, a total, or a colour band.
Judgments are findings with evidence, matching the design gate.

- *Given* a plan file, *when* `/toque:quick-audit` runs, *then* its output
  contains findings with severity and evidence and **no** `X/40`, no
  `GREEN|YELLOW|ORANGE|RED` band, and no scorecard table.
- *Given* a plan file, *when* `/toque:codex-challenge` runs a round, *then* the
  round report lists findings and **no** total or band.
- *Must not:* no tool substitutes a differently-named number (a percentage, a
  grade, a 0-10) for the removed score. Removal, not renaming.

**FR-2 (P0) — No stale citations.**
No shipped file claims a rubric, threshold, band, or `status.json` field that
the auditor no longer has.

- *Given* the repository, *when* grepped for `score_history`, *then* the only
  match is the guard that forbids it.
- *Given* `plan-scaffolder.md`, `quick-plan.md`, `codex-challenge/SKILL.md`,
  *when* read, *then* none cites a `32+/40` or `36/40` plan-auditor threshold.
- *Given* `GUIDE.md`, *when* read, *then* it does not describe a `score_history`
  field.

**FR-3 (P0) — `codex-challenge` converges without a score.**
The loop has a stop condition and a model-escalation trigger that are not
score expressions, and both are stated in one place.

- *Given* every dimension carries a PASS verdict, *when* the loop evaluates,
  *then* it stops and reports converged.
- *Given* any dimension carries a FAIL verdict, *when* the round cap is not
  reached, *then* it optimises and runs again.
- *Given* the round cap is reached with any dimension still FAIL, *when* the
  loop evaluates, *then* it stops and reports **not converged**, naming each
  failing dimension. It never reports success by exhaustion.
- *Must not:* the loop must not silently loop forever, and must not treat "no
  findings returned" as success when the response failed to parse.

**FR-3a (P0) — Coverage is enforced, not assumed.**
Silence must never read as approval. This closes the hole the Codex review
found in the first draft of this spec (`research/codex-design-review.md` Q4).

- *Given* a response, *when* validated, *then* it carries an explicit verdict
  and supporting evidence for **all eight** dimensions.
- *Given* a response missing any dimension, *when* validated, *then* the round
  is rejected as malformed — **not** treated as that dimension passing.
- *Must not:* the absence of a finding for a dimension must never be
  interpreted as that dimension being sound.

**FR-4 (P0) — The guard covers every file that can violate FR-1.**
The `PH5-051` sweep's subject set is derived, not a hand-listed trio.

- *Given* a new file under `plugins/toque/` containing `X/40`, *when* the suite
  runs, *then* Layer 1 fails.
- *Given* the guard, *when* read, *then* its subject set is derived from the
  tree with a floor, so the derivation cannot silently collapse to zero.
- *Must not:* the guard must not pass vacuously if the file list is empty.

**FR-5 (P1) — A small plan can grow up.**
`/toque:quick-plan` output can be promoted into a full plan workspace without
redoing the work, following the pattern `/toque:quick-cleanup` already uses.

- *Given* a spec at `docs/specs/{name}.md` and no plan folder, *when* the user
  asks to promote it, *then* a plan folder is created with `manifest.md`,
  `status.json`, and the spec placed where Stage 1 can consume it.
- *Must not:* promotion must not overwrite an existing plan folder silently.

**FR-6 (P1) — Every command states its relationship to the centerpiece.**
One line, in `/toque:help` and the command's own description.

- *Given* `/toque:help`, *when* run, *then* each command row says whether it is
  part of the plan workflow, feeds it, or stands alone.

**FR-7 (P0) — The repository stays releasable.**

- *Given* the change set, *when* `bash tests/run-all.sh` runs, *then* 8 of 8
  layers pass.
- *Given* the change set, *when* `.github/release.sh check` runs, *then*
  preflight is clean.

### Non-functional

| # | Requirement | Measure |
| --- | --- | --- |
| NFR-1 | No auth surface change | Zero diff touching credentials, permissions, tokens |
| NFR-2 | No data-scope change | Zero new persisted fields, network calls, or user-data reads |
| NFR-3 | No new external dependency | `codex-challenge` keeps its existing Codex CLI dependency; nothing new is added |
| NFR-4 | Backwards compatible with existing plans | `status.json` schema 2 unchanged; the two existing plan folders resume without migration |
| NFR-5 | Release discipline | Version bump, tag, and catalog pin only via `.github/release.sh` |
| NFR-6 | Breaking changes documented | A `CHANGELOG.md` entry naming the removed score output and the changed Codex contract |

## Success metrics

| Metric | Type | Target | Window | Method | Evaluated |
| --- | --- | --- | --- | --- | --- |
| Scoring sites in `plugins/toque/` | Leading | 0 | At merge | The FR-1 grep, run by the guard | Merge day |
| Stale rubric citations | Leading | 0 | At merge | The FR-2 greps | Merge day |
| Suite layers passing | Leading | 8 of 8 | At merge | `tests/run-all.sh` | Merge day |
| `codex-challenge` runs that terminate | Lagging | 100% terminate with a stated reason | First 10 real runs | Manual observation of the round report | 30 days post-release |
| Plans promoted from `quick-plan` | Lagging | ≥1 promotion completed without rework | 60 days | Plan folders whose `status.json` records a promotion source | 60 days post-release |

## Scope

**IN**

- Remove scoring output from `quick-audit` and `codex-challenge`
- Replace `codex-challenge`'s stop condition and model-escalation trigger
- The Codex request/response contract: prompt, output schema, fixtures, parser
- Fix four stale rubric citations and the false `score_history` claim
- Widen the `PH5-051` guard to a derived subject set
- Add a promotion path from `quick-plan` output to a plan folder
- One relationship line per command in help and front matter

**OUT** (from intent.md, plus what options analysis ruled out)

- The `ai-scan` split — paused, separate plan
- Redesigning the design gate, canary classes, or evidence validator
- Removing any command
- The readiness and audit plugins
- Publishing or releasing anything
- *(added here)* Changing the eight review dimensions themselves. They survive
  as lenses in the auditor and stay as lenses in Codex's prompt; only the
  numbers attached to them are removed.
- *(added here)* Replacing the Codex CLI with another reviewer.

## Design

### Options analysis

The decision to strip is made (intent.md OQ1). The open design question is what
`codex-challenge`'s loop uses instead, since its stop condition and model
escalation are both score expressions today
(`phases/round-loop.md:113` and `:126`).

**Option A — Severity-classified findings, stop at zero blocking**

Codex returns findings only. Each carries a severity. The loop stops when a
round returns no findings at or above BLOCKING, or when a round cap is hit.
Escalation triggers on a round returning any CRITICAL finding.

- Pros: matches the gate's own vocabulary; reuses the `gaps` array that already
  exists in the schema with `dimension`/`issue`/`fix`; escalation gets a
  meaningful trigger rather than an arbitrary threshold.
- Cons: severity is still a judgment by the reviewer, so it is a softer signal
  than a number; requires defining the severity ladder once, clearly.
- Risk: **MEDIUM** · Rollback: **LOW** (the schema change is additive-then-
  subtractive and fixtures are versioned)

**Option B — Codex boolean verdict (LGTM / CONCERNS)**

Codex returns a single verdict plus rationale. The loop stops on LGTM.

- Pros: simplest possible stop condition; the fixture names
  (`valid-lgtm.json`, `valid-concerns.json`) suggest this was the original
  intent before scoring was layered on.
- Cons: one bit carries the whole judgment, so a plan with one trivial nit and
  a plan with a fatal flaw both return CONCERNS; no escalation signal at all;
  loses the per-dimension structure that makes the output actionable.
- Risk: **MEDIUM** · Rollback: **LOW**

**Option C — Round budget with a no-new-findings delta**

Fixed N rounds. Stop early when a round surfaces nothing the previous round did
not.

- Pros: guaranteed termination; no severity ladder to define.
- Cons: converges on *repetition*, not on *quality* — a reviewer stuck in a rut
  reports success; says nothing about whether the plan is actually sound.
- Risk: **HIGH** (silently passes bad plans) · Rollback: **LOW**

**Comparison**

| Criterion | A: severity findings | B: boolean verdict | C: round delta |
| --- | --- | --- | --- |
| Implementation ease | Medium | High | High |
| Timeline | Medium | Short | Short |
| Strategic value — matches the gate | **High** | Medium | Low |
| Risk profile | Medium | Medium | **High** |
| Rollback complexity | Low | Low | Low |
| Gives escalation a real trigger | **Yes** | No | No |
| Keeps output actionable | **Yes** | No | Partly |

**Option D — Non-compensating scorecard (proposed by the Codex review)**

Keep the scores. Require `total >= 36 AND every dimension >= PASS_FLOOR`. One
regression test for `[5,5,5,5,5,5,5,1] → NOT CONVERGED`.

- Pros: smallest change that fully closes the defect; keeps the scorecard's
  enforced coverage of all eight dimensions; no contract change at all.
- Cons: leaves two verdict currencies in the product, which is the Problem
  intent.md names. The Codex review acknowledges this and defers it explicitly.
- Risk: **LOW** · Rollback: **LOW**

**Comparison**

| Criterion | A: severity findings | B: boolean verdict | C: round delta | D: non-compensating score |
| --- | --- | --- | --- | --- |
| Implementation ease | Medium | High | High | **High** |
| Strategic value — matches the gate | High | Medium | Low | Low |
| Risk profile | Medium | Medium | **High** | **Low** |
| Escalation trigger | Yes | No | No | Yes |
| **Enforces coverage of all 8** | **No** | No | No | **Yes** |
| Closes the 36/40 defect | Yes | Yes | Partly | **Yes** |
| Resolves two-currency problem | Yes | Yes | Yes | **No** |

**Decision: Option A, amended — findings with an explicit per-dimension verdict.**
Confirmed at scope lock by Kyle, 2026-09-03.

The first draft of this spec chose bare Option A. An adversarial review by the
Codex CLI (`research/codex-design-review.md`) found a defect in it: a
findings-only response cannot distinguish *"this dimension is sound"* from
*"the reviewer never examined this dimension."* Silence was being read as
approval — a worse bug than the one being fixed.

The amendment is the review's own repair, from its answer to Q4: *"require an
explicit verdict and evidence for every dimension — not merely emitted
findings."* Every dimension returns PASS or FAIL with evidence. Coverage is
enforced by the schema rather than hoped for. This is now FR-3a.

**Why not D**, which the review recommended: it closes the defect but leaves
the two currencies intact, and the two-currency inconsistency — not the 36/40
arithmetic — is the Problem intent.md names and the owner accepted. The review
optimised for the narrower question it was asked. Its technical findings are
absorbed; its scope preference is not adopted, and that is an owner decision
recorded here rather than a disagreement about facts.

Option B loses the per-dimension structure entirely. Option C converges on
repetition rather than quality — a stuck reviewer reads as success, the failure
mode the canary exists to prevent elsewhere in this product.

*Would revisit D if:* the per-dimension verdict proves unstable across rounds
in real use, making the numeric floor the more reliable coverage mechanism.
*Would revisit C if:* runaway loops become the dominant failure in practice.

### Approach and pattern

**One atomic change.** The prompt, the response schema, the four fixtures, and
the parser ship in a single commit.

The first draft of this spec staged the change as Expand/Contract. The Codex
review rejected that as ceremony, correctly: *"The prompt, schema, parser, and
fixtures ship together. Unless external consumers or mixed plugin versions
exchange these payloads, make any eventual contract change atomically. Tests and
fixtures are not independent consumers."*

Expand/Contract exists for contracts with **independent** consumers that deploy
on separate schedules. Here every consumer lives in this repository and moves in
the same commit. There is no window in which an old and a new shape coexist, so
there is nothing for the staging to protect. Staging it would have added two
intermediate states, each needing its own tests, to guard against a
compatibility problem that cannot occur.

The old shape is not supported after the change. `codex-challenge` is invoked
fresh each run and holds no persisted responses, so there is nothing to migrate.

### Architecture and data flow

```
  plan file
     |
     v
  prompt-template.md  --asks for-->  a verdict + evidence for EACH of 8
     |                               dimensions, plus a fix for each FAIL
     v                               (no scores, no total)
  Codex CLI
     |
     v
  output-schema.json  --validates-->  { dimensions: [ 8 x {name, verdict,
     |                                    evidence, issue?, fix?} ] }
     |
     +-- fewer than 8 dimensions ----------> REJECT round as malformed
     |                                       (never read as passing)
     v
  round-loop.md
     |
     +-- all 8 PASS ----------------------> STOP: converged
     +-- any FAIL, cap not reached -------> optimise, next round
     +-- >= N FAIL in one round ----------> escalate model, next round
     +-- cap reached with any FAIL -------> STOP: not converged, name them
```

The malformed-response branch is the load-bearing one. It is what makes silence
mean "ask again" rather than "approved", and it is the reason coverage is a
schema property rather than a convention.

### Constraints

- Timeline: no external deadline. Sole maintainer.
- Team: one person; no cross-team coordination.
- Technology: Markdown, Bash, Node 18+. No new runtime.
- The design gate's expression is fixed and out of scope.

### Dependencies

- **Internal, hard:** `tests/layer1-repo.sh` (the guard), `tests/codex-challenge-test.js`
  (447 lines, score-coupled), the four Codex fixtures.
- **External, soft:** the OpenAI Codex CLI. Not required to make the change;
  required to exercise `codex-challenge` end to end.
- **Blocker:** none identified.

## Standards applied

- **The project's own no-score decision (8.0.0).** This work extends it from
  the gate path to the whole plugin. `METHODOLOGY.md §7` is the reference.
- **Expand/Contract** for the schema change — methodology 11 in the plugin's own
  testing framework, chosen because the response contract has existing
  consumers (parser, fixtures, tests).
- **Separate test authorship** — the agent that edits the parser must not write
  the parser's tests.
- No brand, accessibility, or compliance standard applies; this surface is
  developer-facing text and test code.

## Gotchas

**Top 3 risks**

| # | Risk | Impact | Mitigation |
| --- | --- | --- | --- |
| 1 | The strip is larger than the intent recorded. intent.md says 10 files / 31 lines, measured on documentation. The change also touches the prompt, the JSON schema, four fixtures, and a 447-line score-coupled test. | MEDIUM — was HIGH before the review | Raised and accepted at scope lock, 2026-09-03. Reduced by dropping the Expand/Contract staging, which removed two intermediate states and their tests. Any further growth is a Change Record, not a silent expansion. |
| 2 | A reviewer marks every dimension PASS without examining them — the "lazy reviewer" failure the canary exists to catch on the gate path. Per-dimension verdicts force *coverage*, not *diligence*. | MEDIUM | Partly mitigated: FR-3a requires evidence with every verdict, so a bare PASS with no supporting citation is a malformed round. Not fully solved, and stated as a known limitation in the same plain terms the design gate uses for its own. Candidate for a later intent. |
| 3 | The parser, the prompt, and the two `.txt` fixtures encode the same wire format in three places. Change one and the tests pass against a format nothing produces. | MEDIUM | They ship in one commit (see Approach). Stage 4 adds a test asserting a fixture round-trips through the real parser rather than a hand-written copy of it. |

**Conflict points**

- The `.txt` fixtures encode Codex's *raw* output format (`TOTAL: 40/40`). They
  change with the prompt, and the parser's regex changes with them. These three
  must move together or the tests pass against a format nothing produces.

**What to watch during build**

- `additionalProperties: false` in two places (`output-schema.md` and
  `tests/fixtures/codex-challenge/codex-review-schema.json`). They must not drift.

## Evidence

**Nature of the evidence base.** This is an internal coherence change. The
decisions rest on what this repository already does and already decided, not on
external practice. Stated plainly so a reviewer does not mistake absence of
external citations for an unresearched plan: **external research was skipped
deliberately** (research/findings.md), because no outside source can answer
whether these particular tools should agree with each other.

Every load-bearing claim below was read from the file cited during this session.

| # | Claim | Evidence | Impact | Verified |
| --- | --- | --- | --- | --- |
| E1 | The gate has no score; the 8 dimensions survive as lenses only | `plugins/toque/agents/plan-auditor.md:60` | HIGH | Read |
| E2 | A guard enforces no-score, over exactly 3 hand-listed paths | `tests/layer1-repo.sh:855-858` | HIGH | Read |
| E3 | `quick-audit` emits `X/40` and a colour band | `commands/quick-audit.md:59-60` | HIGH | Read |
| E4 | `codex-challenge` stops at `>= 36/40` | `skills/codex-challenge/phases/round-loop.md:113` | HIGH | Read |
| E5 | It escalates models below `24/40` | `skills/codex-challenge/phases/round-loop.md:126` | HIGH | Read |
| E6 | The prompt asks Codex for scores | `skills/codex-challenge/phases/prompt-template.md:18,40` | HIGH | Read |
| E7 | The response schema *requires* `scores` and `total`, `additionalProperties: false` | `tests/fixtures/codex-challenge/codex-review-schema.json` | HIGH | Read |
| E8 | The parser extracts `TOTAL: N/40` and validates 1-5 per dimension | `tests/codex-challenge-test.js:26-57` | HIGH | Read |
| E9 | Nothing consumes the score programmatically | 23 references swept, research/findings.md R1 | HIGH | Read |
| E10 | `score_history` is documented but never written | `GUIDE.md:265`; only other match is the guard | MEDIUM | Read |
| E11 | The `gaps` array already carries `dimension`/`issue`/`fix` | `codex-review-schema.json` | MEDIUM | Read |
| E12 | `quick-cleanup` is the working promotion precedent | `commands/quick-cleanup.md:7-25` | MEDIUM | Read |

**Standards and methods used**

- Expand/Contract for the schema change — the plugin's own methodology 11,
  `skills/plan/stages/stage-2-design.md`, prescribed for contract changes with
  existing consumers. Applied here to a tool contract rather than a database,
  which is an extension of its stated scope and is noted as such.
- Separate test authorship — the plugin's own AI-specific testing rule.

**Known weaknesses in this evidence base**

- **E9 is a negative claim from a bounded sweep.** "Nothing consumes the score"
  was established by grep over `plugins/toque/`. A consumer outside that tree
  would have been missed. No plausible location exists, but the claim is
  bounded, not exhaustive.
- **Correction, 2026-09-03.** An earlier draft of this section said "the Codex
  CLI was not run" and Gotcha 2 said it was unavailable. Both were wrong. Codex
  CLI **0.153.0 is installed** and was run against this design — see E13. The
  claim was asserted without checking `PATH`.
- **E13 — the design was adversarially reviewed.** `codex exec --sandbox
  read-only`, 2026-09-03, full transcript at `research/codex-design-review.md`.
  It found a correctness defect in the first draft (silence read as approval),
  which became FR-3a, and rejected the Expand/Contract staging as ceremony,
  which was removed. Impact: HIGH. Verified: run.
- **Still no evidence about real reviewer behaviour under the new contract.**
  Codex reviewed the *design*; it has not been run against the *new response
  schema*, which does not exist yet. Whether a real reviewer reliably returns
  eight verdicts with evidence is **unverified** and is Gotcha 2. Stage 4 makes
  the first real run an explicit manual check, not an assumed pass.
- **No external benchmark** exists for whether verdict-based convergence beats
  score-based convergence. The decision rests on internal consistency with the
  gate plus the coverage argument, not on measured superiority. Stated so it is
  not read as an empirical claim. The Codex review explicitly disputes the
  premise — it prefers the numeric floor — and that disagreement is recorded in
  the options analysis rather than averaged away.

## Open questions

1. **Does the true scope change the decision?** Gotcha 1: the accepted intent
   understates the work. *Owner: Kyle. Raised at scope lock, below.*
2. **What exactly is the severity ladder?** CRITICAL / BLOCKING / ADVISORY, or
   reuse the audit plugin's existing severity vocabulary for consistency?
   *Owner: Kyle. Blocks Part B.*
3. **Round cap value?** Currently governed by a `max rounds` setting.
   *Owner: agent, resolvable from the existing config. Non-blocking.*

## Verification plan

### Vocabulary decision (was Open question 2)

**Verdicts are `PASS` / `FAIL` per dimension. A `FAIL` carries a severity of
`HIGH` / `MEDIUM` / `LOW`.**

Decided on evidence rather than preference. The planning plugin already uses
HIGH/MEDIUM/LOW **83 / 42 / 39 times** for assumption impact, risk levels, and
finding severity. The audit plugin's richer CRITICAL/HIGH/MEDIUM/LOW/INFO ladder
was the other candidate, and was rejected for a structural reason: that plugin is
being split into a separate repository, so adopting its vocabulary would make the
planning plugin's convergence logic depend on a ladder defined in another
product. A coherence change should not create a cross-repo coupling.

Model escalation triggers on **any `HIGH`** in a round.

*Kyle: this is the one Part B decision made without asking. Say so if you want it
reversed — it is confined to naming and costs one search-and-replace.*

### Methodology per deliverable

Selected from the framework, not defaulted to unit tests.

| # | Deliverable | Methodology | Why this one |
| --- | --- | --- | --- |
| D1 | Fix 4 stale rubric citations + the phantom `score_history` | **TDD** | The assertion is a grep that must find nothing. Write the failing check, then delete the text. Red-to-green is literal here. |
| D2 | `codex-challenge` request/response contract (prompt, schema, 4 fixtures) | **Contract Testing** | This *is* an API contract with an external program. Both directions need proving: a conforming response parses, and a short response is rejected. |
| D3 | `codex-challenge` loop logic (stop, escalate, malformed, cap) | **TDD** | Pure decision logic with enumerable inputs. Tests are writable before the implementation and each maps to one FR-3 criterion. |
| D4 | Remove scoring from `quick-audit` | **TDD** | Same shape as D1 — an absence assertion. |
| D5 | Widen the `PH5-051` guard to a derived subject set | **Mutation Testing** | A guard that cannot fail is worse than no guard. Prove it by planting `X/40` in a scratch file and confirming Layer 1 goes red, then removing it. The repo already does this — `tests/mutation/` exists. |
| D6 | `quick-plan` promotion path | **BDD** | User-facing workflow whose acceptance criteria are already written Given/When/Then in FR-5. |
| D7 | One relationship line per command | **Snapshot / Approval** | The deliverable is rendered help text. Capture it, review it by eye once, approve it. |

**Expand/Contract is deliberately NOT used** for D2, though the framework
nominates it for contract changes. See Approach: no independent consumers exist,
so the staging protects against nothing. Recorded here so its absence reads as a
decision rather than an oversight.

### AI-specific requirements

- **Separate test authorship.** The agent that edits `tests/codex-challenge-test.js`
  must not also write the assertions that prove the new parser correct. D2 and
  D3's tests are authored before, and independently of, the parser edit.
- **Higher scrutiny on generated code.** The loop logic (D3) is the only real
  logic in this change; every branch of FR-3 gets a named test.
- **AI failure-mode checklist**, applied to D2/D3 at review:
  - *Tautological tests* — the sharpest risk here. A test asserting the parser
    returns what the parser produced proves nothing. Every fixture assertion
    compares against a **hand-written expected value**, not against parser output.
  - *Happy-path-only* — explicitly countered: the malformed-response and
    cap-exhaustion paths carry as many tests as the success path.
  - *Logic drift* — the stop condition exists in exactly one place; a second
    copy is a review rejection.
  - *Stale dependencies* — n/a, nothing added.
  - *Hidden rule violations* — the guard (D5) is the mechanical check.

### Two-tier split (Stage 4 will use this)

**Tier 1, automated:** `bash tests/run-all.sh` 8/8 · `.github/release.sh check`
clean · the FR-1 and FR-2 greps return empty · the D5 mutation proves the guard
bites · fixtures round-trip through the real parser.

**Tier 2, manual, human-confirmed:** one **real `codex-challenge` run against a
real plan** using the installed Codex CLI 0.153.0 — the only way to learn whether
a live reviewer returns eight verdicts with evidence, which no fixture can prove
(Gotcha 2). Plus: read the rendered `/toque:help` output once (D7), and promote
one real `quick-plan` spec into a plan folder (D6).

---

## Delivery

Five phases, ordered so **the suite is green at every phase boundary**. That
ordering is the reason the guard lands last rather than first: widening
`PH5-051` before the scoring is gone would turn Layer 1 red and leave the repo
unreleasable between phases.

### Timeline

Estimated in **working sessions**, not calendar weeks — one maintainer, no
external deadline, no coordination cost. Calendar estimates would be invented
precision.

| Phase | Risk | Est. | Depends on | Critical path |
| --- | --- | --- | --- | --- |
| 1 — Stale citations | LOW | 0.5 | — | no |
| 2 — Codex contract + loop | **HIGH** | 2-3 | — | **yes** |
| 3 — `quick-audit` scoring | MEDIUM | 0.5 | — | no |
| 4 — Widen the guard | LOW | 0.5 | 1, 2, 3 | **yes** |
| 5 — Promotion path + labels | LOW | 1 | — | no |

Phase 2 is the critical path and the only one carrying real risk. Phases 1, 3,
and 5 are independent and can land in any order.

### Phase 1 — Stale citations and the phantom field · LOW

Detail level: LOW risk, so goals and success criteria.

**Goal.** Remove every claim about a rubric or field that no longer exists.

| File | Line | Change |
| --- | --- | --- |
| `agents/plan-scaffolder.md` | 24 | drop "would score 32+/40 on the plan-auditor" |
| `agents/plan-scaffolder.md` | 232 | drop "target 32+/40" |
| `commands/quick-plan.md` | 2 | drop "scores well on the plan auditor's 8 dimensions" |
| `skills/codex-challenge/SKILL.md` | 27 | drop "upper GREEN threshold from Toque's plan-auditor rubric" |
| `GUIDE.md` | 265 | delete the `score_history` sentence entirely |

**Done when:** `grep -rn "score_history" .` matches only the guard, and no file
cites a `32+/40` or `36/40` auditor threshold.
**Rollback:** `git revert` one commit. No behaviour depends on this text.

### Phase 2 — The Codex contract and loop · HIGH

Detail level: HIGH risk, so exact files and test requirements.

**Files, all in one commit:**

```
plugins/toque/skills/codex-challenge/phases/prompt-template.md   (:18, :40)
plugins/toque/skills/codex-challenge/phases/output-schema.md
plugins/toque/skills/codex-challenge/phases/round-loop.md        (:62-64, :113, :126)
plugins/toque/skills/codex-challenge/phases/report.md            (:20, :21, :25, :79)
plugins/toque/skills/codex-challenge/SKILL.md                    (:3, :27, :28, :125, :158)
tests/fixtures/codex-challenge/codex-review-schema.json
tests/fixtures/codex-challenge/valid-lgtm.json  · valid-lgtm.txt
tests/fixtures/codex-challenge/valid-concerns.json · valid-concerns.txt
tests/codex-challenge-test.js                                    (447 lines)
```

**New response shape.** Eight entries, each `{name, verdict, evidence, issue?,
fix?}`. `required` becomes the eight dimension names; `scores` and `total` are
removed; `additionalProperties: false` is restored in **both** copies of the
schema (`output-schema.md` and the fixture) — they must not drift.

**Required tests** (authored before the parser edit, per Separate Test Authorship):

1. All 8 PASS → converged
2. 7 PASS + 1 FAIL → **not** converged *(the direct descendant of the 36/40 defect)*
3. Response with 7 dimensions → **malformed**, not "7 passed"
4. `FAIL` with no evidence → malformed
5. Any `HIGH` → escalate
6. Cap reached with a FAIL open → NOT CONVERGED, names the dimension
7. Unparseable output → malformed, never success
8. Both `.txt` fixtures round-trip through the real parser

**Go/no-go to Phase 4:** all eight pass; suite 8/8; no `/40` remains under
`skills/codex-challenge/`.
**Rollback:** one `git revert`. The tool is invoked fresh each run and persists
no responses, so there is no state to unwind.

### Phase 3 — `quick-audit` scoring · MEDIUM

`commands/quick-audit.md:59-60` — replace the score line and scorecard table with
findings ordered by severity, each citing evidence. Update the front-matter
description, which also advertises scoring.

**Done when:** no `X/40`, no colour band, no scorecard table.
**Rollback:** one `git revert`.

### Phase 4 — Widen the guard · LOW, but it is the proof

`tests/layer1-repo.sh` PH5-051. Replace the three hand-listed paths with a
derived subject set over `plugins/toque/`, plus a floor so an empty derivation
fails loudly instead of passing vacuously — the same vacuous-pass lesson the file
already applies elsewhere.

**Done when:** planting `X/40` in a scratch file turns Layer 1 red, and removing
it turns it green. This phase is what makes phases 1-3 permanent.
**Rollback:** one `git revert`; the guard reverts to the narrower list.

### Phase 5 — Promotion path and relationship labels · LOW, P1

`quick-plan` gains promotion following `quick-cleanup:7-25`'s existing pattern:
create the plan folder, write `manifest.md` and `status.json`, place the spec
where Stage 1 reads it, and **refuse to overwrite an existing folder**. Each
command gains one line in `/toque:help` saying whether it is part of the plan
workflow, feeds it, or stands alone.

**Rollback:** one `git revert` per deliverable; both are additive.

### Go / no-go criteria at each boundary

| Boundary | Go requires | No-go action |
| --- | --- | --- |
| 1 → any | Suite 8/8; the two greps empty | Fix forward; the phase is text-only |
| 2 → 4 | All 8 loop tests pass; suite 8/8 | **Stop.** Phase 2 is the risk. Revert and reconsider Option D |
| 3 → 4 | Suite 8/8; no scorecard remains | Fix forward |
| 4 → 5 | Mutation proves the guard bites | **Stop.** A guard that cannot fail is worse than none |
| 5 → Stage 4 | Suite 8/8; preflight clean | Fix forward |

### Operational readiness

No deployment, no runtime, no monitoring surface — this ships as a plugin
version, not a service. What replaces monitoring:

- **First real use is the signal.** The Tier 2 manual `codex-challenge` run is
  the only evidence the new contract works against a live reviewer.
- **Incident fallback:** the plugin is versioned and pinned by SHA in the
  catalog. A bad release is undone by pinning the previous tag — the mechanism
  already used for every release.
- **Success metric review** at 30 and 60 days, per the Success metrics table.

### Release

Version bump, tag, and catalog pin only through `.github/release.sh`. This is a
**breaking** change — the Codex response contract changes shape and two commands
stop emitting scores — so it takes a major version and a `CHANGELOG.md` entry
naming both.
