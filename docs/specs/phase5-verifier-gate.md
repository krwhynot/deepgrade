# Phase 5 Verifier-First Audit Gate

**Status:** DRAFT — awaiting owner review
**Target version:** 6.0.0 (breaking change to Phase 5 gate semantics)
**Baseline:** `df8ac58` (v5.0.1), tree clean
**Author:** design session 2026-08-02
**Supersedes:** the Phase 5 gate described in `commands/plan.md:941-1003` and
`docs/planning-techniques/02-evaluator-optimizer-loop.md`

---

## 1. Problem

Phase 5 currently authorizes passage on a number the audited model assigns to
itself. `commands/plan.md:945` reads:

```
IF score >= 32 AND gap-checked = YES (GREEN + gap-checked):
  -> "Plan is solid. Ready to start building."
```

Seven properties of the current design make that number cheap to obtain without
improving the plan.

| # | Property | Location | Consequence |
|---|----------|----------|-------------|
| 1 | The full rubric — 5-point anchors, band thresholds, every LINT rule verbatim — lives in the file the Phase 4 generator reads | `commands/plan.md:651-659`, `:810-841` | The generator is given the answer key before the exam. It can write text shaped like each rule rather than text that satisfies it. |
| 2 | The auditor runs in the session that produced the spec | Phase 5 has no isolation clause | The evaluator sees intent, not just artifact, and evaluates what the generator meant to write. |
| 3 | ~34 of 40 points are unfalsifiable prose scores | `commands/plan.md:651-657` | "Adequate coverage, 4/5" cannot be disproven, so nothing resists inflation. |
| 4 | Codebase verification is self-reported | `commands/plan.md:669-670` — *"Confirm file paths… exist"* | Nothing requires the command to run or its output to be retained. The audit may claim verification it never performed. |
| 5 | Revision feedback names the failing **dimension** | `commands/plan.md:951-953` | The cheapest response is prose that reads like the missing thing. Score rises; plan does not change. |
| 6 | Two iterations, then proceed regardless | `commands/plan.md:959-966` | Surviving two rounds is a viable strategy. |
| 7 | The one ungameable check is waivable | `commands/plan.md:992` | Solo mode removes the only external signal. |

This is not hypothetical for this repository. The plugin-hardening-v5 plan
recorded three instances of the same species:

- **PHV5-044** is `PARTIAL` because part 2 has no artifact —
  `research/layer7-runtime-evidence.md` has never existed in any commit, while
  the result was asserted in a commit message.
- **Wave 5 shipped with zero assertions and passed everything**, because the
  suite looked for the fixes rather than for the acceptance rows' artifacts.
- **F30 was recorded MET at the moment it was NOT MET, twice.**

Every one is the same failure: a claim of verification with no retained evidence
that verification occurred. The current Phase 5 gate cannot detect it.

### 1.1 What this spec does not address

It makes the **judge** honest about the rubric. It does not make the **rubric**
complete. A plan can satisfy all criteria and still be bad in a way no criterion
covers — *rubric-design failure* as distinct from *verifier failure*. §5.6
adds an advisory mechanism for surfacing that class; it deliberately does not
gate on it.

---

## 2. Ticket zero: the lint registry is not a single source of truth

`docs/planning-techniques/lint-registry.md:3` claims to be the "Single source of
truth for all plan lint rules." It is not. Three files disagree on both the
content and the count of the rules.

| Source | LINT-17 | LINT-18 | Count |
|--------|---------|---------|----------------------|
| `lint-registry.md:25-26`, `:31` | Every deliverable has a testing methodology assigned | AI-generated code specifies a separate test writer | 16 |
| `commands/plan.md:827-828`, `:849`, `:862` | Confidence brief exists, no unresolved HIGH-impact markers | Confidence brief has all 3 sections, entries have required fields | 14 |
| `agents/plan-auditor.md:486-491`, `:254`, `:494` | (confidence-brief variant) | (confidence-brief variant) | 15 in one place, 14 in another |

Two distinct rules occupy IDs 17 and 18. Four different counts are in print
(14, 15, 16, 18). `plan.md:862` says "All lint rules pass (including LINT-14,
LINT-15, and LINT-16)" — enumerating three of them as if the set were smaller
than it is.

Under the current design this is a documentation defect. Under a verifier-first
gate, the LINT set **is** the gate, so an ambiguous set means an ambiguous gate.
**No other ticket in this spec may land before this is resolved.**

Resolution (PH5-001): renumber the confidence-brief rules to **LINT-19** and
**LINT-20**, keep the registry's testing-methodology definitions at 17/18, and
make the registry the only file that states rule text or counts.

### 2.1 What the guard actually found

Writing the guard before the fix revised the scope sharply. The collision at
17/18 was the visible tip; the guard found **59 restatements across 7 files**, and
*every one* of the rules had drifted into at least one alternate wording — the
same rule read as "Every deployment phase has a rollback plan" in one file and
"Every deployment has rollback" in another. A judge given the second is checking a
weaker rule than the registry defines, and nothing would have reported the
difference.

The fix is therefore split by whether a file is loaded into agent context:

| Set | Files | Rule |
|-----|-------|------|
| Machine-read | `commands/**`, `agents/**` | **Bare ids only.** Text that drifts here is text a judge applies. 38 restatements removed. |
| Human-facing | `METHODOLOGY.md`, `docs/planning-techniques/**` | **May restate, must match the registry verbatim.** Bare ids would make these unreadable. 21 checked, 14 corrected. |
| Definition site | `docs/planning-techniques/lint-registry.md` | The only file that may state rule text or a rule count. |
| Historical records | `docs/plans/**` | Out of subject. These record what ran at the time; rewriting them to satisfy a guard would falsify a record rather than fix a defect. |

Both halves are decided by text comparison. Neither asks the guard whether a
sentence "expresses" a rule — an earlier draft did, and it produced false
positives on the registry's own gate-behaviour table and on range references like
`LINT-01 through LINT-10`. That is the intent-detection species this repository has
been bitten by repeatedly; the absence/equality formulation avoids it entirely.

---

## 3. Design summary

| Layer | Before | After |
|-------|--------|-------|
| Gate | `score >= 32 AND gap-checked` | All falsifiable criteria MET, zero INFRA-GAPs, every MET carries a validated evidence record, canary found |
| Score | Authorizes passage | Computed and reported; appears nowhere in the PASS expression. Retained as a trend signal and as one input to the **waiver** condition only |
| Rubric location | `commands/plan.md` (generator-readable) | `agents/plan-auditor.md` + `lint-registry.md` only |
| Threshold visibility | Stated to generator and judge | Stated to neither; the harness computes totals |
| Judge input | Session context | An explicit file manifest; enumerated forbidden inputs |
| Judge output | Numeric scores | Per-criterion `MET`/`UNMET`/`N_A` + evidence records. No total field in the schema |
| Verification | Self-reported prose | Quotes byte-validated against the artifact and pinned by hash; a retained command is provenance for a human, never proof |
| Audit trustworthiness | Assumed | Measured by a seeded canary defect |
| Revision feedback | "Dimension 4 scored 2" | "LINT-03 UNMET: Phase 2 migration has no rollback step (spec.md:142)" |
| Human waiver | Unconditional in solo mode | Blocked when `infra_gaps > 0` OR score in guard band OR canary missed |

---

## 4. The gate

```
CANARY_OK   = canary_criterion ∈ audit.unmet_set
EVIDENCE_OK = ∀ c ∈ criteria where c.verdict == MET :
                validate_evidence(c) == true
VERIFIED    = ∀ c ∈ applicable_criteria : c.verdict ∈ {MET, N_A}
INFRA_OK    = infra_gaps == 0

PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

`score` does not appear. It is computed after the gate resolves, written to
`audit.md` and `status.json`, and used for two things only: trend monitoring
(§5.7) and the waiver band (§5.8).

**Non-compensable by construction.** There is no weighted sum, so a strong
showing on seven criteria cannot offset a failure on the eighth. This is the
property the 40-point total structurally cannot have.

---

## 5. Mechanisms

### 5.1 Judge isolation (PH5-010 … PH5-013)

The `plan-auditor` agent is invoked with an explicit input manifest — a list of
file paths and nothing else.

**Permitted inputs.** The spec under audit; `brainstorm.md`, `approach.md`,
`confidence.md` where they exist; the codebase; the criterion set from
`agents/plan-auditor.md` and `lint-registry.md`.

**Forbidden inputs, enumerated in the agent file so the constraint is auditable:**

| Forbidden | Why |
|-----------|-----|
| The Phase 4 generation transcript | Carries intent; the judge would evaluate what was meant, not what was written |
| Generator rationale or self-assessment | Direct import of the generator's conclusions |
| Prior iteration scores or prior `audit.md` | Anchors iteration 2 on iteration 1's number |
| The numeric threshold and band table | Naming the desired outcome is the sycophancy signal; the judge should not know what "passing" costs |
| Plan author identity | Removes an authority cue |

Each re-audit in the revision loop gets a **fresh** judge with no score history.
`commands/plan.md:955` currently re-runs the audit inside the same loop; it must
spawn a new agent instance per iteration.

**Rubric relocation.** `commands/plan.md` Phase 5 loses the 5-point anchors
(`:651-659`) and the verbatim LINT list (`:810-841`), replaced by a pointer to
the agent and the registry. The Phase 4 generator retains the *requirements* —
it must still be told to write a rollback plan — but not the *scoring function*,
the thresholds, or the rule text it will be measured against.

> **Known limitation, recorded honestly.** The judge holds `Read`/`Grep`/`Glob`
> over the repository and can therefore reach `agents/plan-auditor.md` and
> `lint-registry.md` on its own. Isolation is enforced by instruction, not by
> capability. The mechanism raises the cost of leakage; it does not make it
> impossible. Closing it properly requires either scoping the judge's tool
> access to the manifest or moving criteria out of the repo — neither is in
> scope here, and the residual risk is stated rather than papered over.

### 5.2 Criterion verdicts, not scores (PH5-014)

The judge emits, per criterion:

```json
{
  "criterion_id": "LINT-03",
  "verdict": "MET | UNMET | N_A",
  "reasoning": "...",
  "evidence": [ /* see 5.3 */ ],
  "n_a_justification": "required iff verdict == N_A"
}
```

There is no `score`, `points`, `total`, or `threshold` field. Evidence is
serialized **before** reasoning, and reasoning before verdict, so the verdict is
conditioned on located evidence rather than the evidence being assembled to
justify a verdict already emitted.

The 8 dimension scores are still produced, by a separate pass, after the gate
has resolved. They are reporting output.

### 5.3 Evidence records (PH5-020 … PH5-023)

Every `MET` verdict carries at least one record:

```json
{
  "artifact": "docs/specs/plugin-hardening-v5.md",
  "sha256": "9f2c…",
  "line_start": 81,
  "line_end": 87,
  "exact_quote": "Rollback: revert migration 0043 via `npm run db:down 0043`.",
  "command": "sed -n '81,87p' docs/specs/plugin-hardening-v5.md",
  "exit_code": 0
}
```

A new validator, `scripts/tq-evidence-validate.js`, enforces four rules:

1. **Quote equality.** Re-read `artifact`, confirm its hash equals `sha256`,
   slice `line_start..line_end`, assert byte-equality with `exact_quote`.
   Mismatch → verdict forced to `UNMET`, flagged `EVIDENCE-INVALID`.
2. **No bare MET.** `verdict == MET` with an empty `evidence` array → forced
   `UNMET`, flagged `EVIDENCE-MISSING`.
3. **Executable criteria need a citation, not a claim.** Criteria whose check is
   executable (file existence, grep count, test invocation) must carry at least
   one citation that survives re-checking — a real file, at real lines, quoted
   byte-for-byte and pinned. Absent → forced `UNMET`, flagged
   `EVIDENCE-UNSUPPORTED`.

   **Revised in 11.0.0.** This rule was "must carry `command` + `exit_code`", and
   both fields are written by the judge. A record claiming
   `command: "definitely-not-run", exit_code: 0` returned `MET`: the judge
   asserting it had run something stood in for having run it, on precisely the
   criteria that exist to stop that. `exit_code` is now ignored outright and a
   supplied one is reported as `EVIDENCE-EXITCODE-IGNORED`. The validator does not
   re-run the command — these records are model-authored, and executing a string
   one wrote is a worse problem than the one it solves.
4. **Unverifiable-claim policy.** An externally checkable claim with no valid
   evidence is `UNMET`. Not partial credit, not a warning.

Rule 4 is the mechanical form of the lesson PHV5-044 taught: it converts
"PARTIAL, no artifact" from a judgment call into an outcome.

Byte-equality is chosen deliberately. The repository's own recorded lesson —
*"grep decides ABSENCE and EQUALITY; it cannot decide PRESENCE OF INTENT"* — cuts
in favour of this design: quote equality is exactly the class of question a
deterministic check can answer, and the judge is confined to asserting things of
that class.

Records are written to `docs/plans/{date}-{name}/evidence/{criterion_id}.json`
and committed. An audit whose evidence directory is absent from the commit is
not a completed audit.

### 5.4 Seeded canary (PH5-030 … PH5-033)

Before the audit, `scripts/tq-canary.js` copies the spec to a working path and
injects exactly one surgical defect, recording which criterion it violates.
Bank of defect classes:

| Class | Mutation | Violates |
|-------|----------|----------|
| rollback-strip | Delete the rollback line from one deployment phase | LINT-03 |
| owner-strip | Remove the owner from one external dependency | LINT-04 |
| assumption-inject | Add one unverified HIGH-impact assumption | LINT-08 |
| criteria-strip | Delete go/no-go criteria from one phase | LINT-10 |
| test-claim-inject | Claim a test file that does not exist | LINT-15 |

The judge audits the mutated copy. Afterwards:

1. If the canary's criterion is **not** in the `UNMET` set → `CANARY-MISSED`.
   Re-run once with a different defect class. Second miss → gate fails with
   *"audit untrustworthy"*; no revision is attempted, because a revision loop
   driven by an audit that cannot see a planted defect is worse than no loop.
2. If found, strip the canary finding from the report, then **re-check only that
   one criterion against the unmutated original**. Without this step the plan
   would be gated on an audit of a document differing from the real one.

> **Known limitation.** The judge can read `scripts/tq-canary.js`. The canary
> therefore detects a *lazy* audit reliably and an *adversarial* one only
> incidentally. Defects are drawn pseudo-randomly per run and the class is
> rotated, which raises the cost of pre-empting it, but the honest claim is:
> this is a liveness check on the auditor, not a tamper-proof control.

### 5.5 Feedback discipline (PH5-040)

Revision instructions returned to the generator use one form:

```
{criterion_id} UNMET: {defect}. Location: {file}:{line}.
```

Example: `LINT-03 UNMET: Phase 2 database migration has no rollback step.
Location: docs/specs/plugin-hardening-v5.md:142.`

Forbidden in feedback text: `dimension`, `score`, `/40`, `points`, `threshold`,
`GREEN`, `YELLOW`. Enforced by a grep guard in the suite — the same class of
guard the consistency sweep already uses, and one where grep is deciding
absence, which it can do soundly.

Without this, the feedback channel re-leaks the scoring structure that §5.1 just
removed from the generator's view.

### 5.6 Rubric-free holistic pass (PH5-050, advisory)

One additional judge per audit, given no rubric, no LINT list, and no dimension
names. Its entire prompt is: *"Ignore any checklist. What would make this plan
fail in production?"*

Findings are mapped against the existing criterion set. Anything that maps to
nothing is appended to `docs/planning-techniques/lint-candidates.md` with the
plan and date, for owner review.

**This never gates.** It is the only mechanism in the spec that can detect an
incomplete criterion set, and its output is a proposal for a new rule, not a
verdict on the current plan.

### 5.7 Score-distribution monitoring (PH5-051, advisory)

`status.json` gains a `score_history` array: per audit, the total, per-criterion
verdicts, iteration number, and canary result. A cluster of totals immediately
above any historical threshold is the statistical signature of threshold-aiming
and is worth seeing even though the total no longer gates.

### 5.8 Conditional human waiver (PH5-060)

```
waiver_allowed = (infra_gaps == 0)
                 AND (score >= 35)
                 AND (canary_found == true)
```

A score in [32, 34] — the guard band around the old threshold — blocks the
waiver and requires a named reviewer. Waivers are recorded in `status.json`
**and** stamped into `audit.md` and the Phase 9 handoff, so they remain visible
downstream rather than only in machine state.

Note the asymmetry, and that it is intentional: the score cannot let a plan
**pass**, but a low-ish score can remove the owner's ability to **skip review**.
A gameable signal is safe to use in the direction that adds friction.

---

## 6. Tickets

| ID | Wave | Ticket | Depends on |
|----|------|--------|-----------|
| PH5-001 | 0 | `PH5-001a`/`PH5-001b` guards in `tests/layer1-config-wiring.sh`; renumber confidence-brief rules to LINT-19/20; strip 38 restatements from `commands/`+`agents/`; correct 14 doc restatements to registry wording | — |
| PH5-002 | 0 | Remove hardcoded rule counts from `plan.md`, `plan-auditor.md`, `METHODOLOGY.md` (four different values were in print) | PH5-001 |
| PH5-010 | 1 | Move 5-point anchors and LINT text out of `commands/plan.md` into `agents/plan-auditor.md` | PH5-002 |
| PH5-011 | 1 | Add input manifest + forbidden-input table to `plan-auditor.md` | PH5-010 |
| PH5-012 | 1 | Fresh judge instance per revision iteration | PH5-011 |
| PH5-013 | 1 | Remove threshold and band table from all generator-visible and judge-visible text | PH5-010 |
| PH5-014 | 1 | Judge output schema: verdicts + evidence, no total field | PH5-011 |
| PH5-020 | 2 | `scripts/tq-evidence-validate.js` — the four rules of §5.3 | PH5-014 |
| PH5-021 | 2 | Evidence record emission in `plan-auditor.md` | PH5-014 |
| PH5-022 | 2 | `evidence/` directory convention + commit requirement | PH5-021 |
| PH5-023 | 2 | Unverifiable-claim policy wired into verdict resolution | PH5-020 |
| PH5-030 | 3 | `scripts/tq-canary.js` — 5 defect classes, injection + record | PH5-020 |
| PH5-031 | 3 | Canary detection check + single re-run on miss | PH5-030 |
| PH5-032 | 3 | Canary strip + single-criterion recheck against the original | PH5-031 |
| PH5-033 | 3 | `CANARY-MISSED` twice ⇒ gate fails, no revision attempted | PH5-031 |
| PH5-040 | 4 | Feedback template + forbidden-string guard | PH5-014 |
| PH5-041 | 4 | Rewrite the gate expression in `commands/plan.md` Phase 5 | PH5-023, PH5-032 |
| PH5-042 | 4 | Same gate in `commands/quick-audit.md` and `commands/quick-plan.md` | PH5-041 |
| PH5-050 | 5 | Rubric-free holistic judge + `lint-candidates.md` | PH5-041 |
| PH5-051 | 5 | `score_history` in `status.json` | PH5-041 |
| PH5-060 | 5 | Conditional waiver + downstream stamping | PH5-041 |
| PH5-070 | 6 | Update `02-evaluator-optimizer-loop.md` to describe the verifier-first loop | PH5-060 |
| PH5-071 | 6 | Suite guards (§8) | all |
| PH5-072 | 6 | Mutation controls for the new guards | PH5-071 |
| PH5-073 | 6 | CHANGELOG 6.0.0 with breaking-change section and migration note | all |

---

## 7. Acceptance rows

Each row is written to be answerable by *"which committed artifact satisfies
this?"* rather than *"did I fix it?"* — the check Wave 5 of plugin-hardening-v5
was closed without, twice.

| # | Row | Satisfying artifact |
|---|-----|--------------------|
| A1a | No file under `commands/` or `agents/` states LINT rule text — bare ids only | `PH5-001a` guard in `tests/layer1-config-wiring.sh`; zero extractions from the machine-read set |
| A1b | Every restatement in a human-facing doc matches a registry wording verbatim | `PH5-001b` guard in the same file; set difference against the registry map is empty |
| A2 | Each LINT id has exactly one meaning | Follows from A1a+A1b by construction — with one definition site, a collision cannot be expressed. Registry diff moving the confidence-brief rules to LINT-19/20 |
| A3 | `commands/plan.md` contains no 5-point anchor text and no band thresholds | Guard asserting absence of `32-40 GREEN` and `5 = Thorough` in `commands/plan.md` |
| A4 | `plan-auditor.md` enumerates forbidden inputs | Frontmatter-anchored presence check via existing `fm_get`/`fm_has` helpers |
| A5 | Judge output schema has no total field | Schema fixture in `tests/fixtures/` + validator rejecting a payload containing `total` |
| A6 | A `MET` verdict with a paraphrased quote is forced to `UNMET` | Negative test in the evidence-validator test file |
| A7 | A `MET` verdict with an empty evidence array is forced to `UNMET` | Negative test |
| A8 | A stale `sha256` is rejected | Negative test mutating the artifact after record emission |
| A9 | Each of the 5 canary classes is detected by a correct audit | 5 fixture audits under `tests/fixtures/canary/` |
| A10 | Two consecutive canary misses fail the gate and skip revision | Negative test asserting no revision call is made |
| A11 | Canary strip is followed by a recheck of that criterion against the original | Test asserting the recheck command appears in the evidence directory |
| A12 | Feedback text contains no forbidden string | Grep guard over generated feedback fixtures |
| A13 | The gate expression contains no score term | Structural check on the PASS expression in `commands/plan.md` |
| A14 | Waiver is blocked at score 34 with zero infra gaps | Fixture-driven test of the waiver predicate |
| A15 | Holistic judge findings that map to no criterion land in `lint-candidates.md` | The file exists with at least one entry after the fixture run |
| A16 | Every new guard has a **control** that must stay SILENT on a legitimate edit | `tests/mutation/` entries; controls counted separately from catches |

A16 is not optional. Every previous mutation round in this repository consisted
only of defects, which measured sensitivity and said nothing about specificity —
which is how eight guards ended up rejecting valid work.

Wave 0 was verified this way and the controls earned their place immediately. The
first draft of the PH5-002 guard flagged `Phase 5 lint rules` as a rule count — it
names a phase — and only a control distinguished that from the genuine finding two
words later, where the identical phrase was preceded by a cardinal and did assert a
set size. A sensitivity-only round would have scored that draft 2/2 and shipped a
guard that fires on correct text.

| Case | Mutation | Expected | Result |
|------|----------|----------|--------|
| M1 | Drifted rule text added to a machine-read file | CATCH | pass |
| M2 | One-word wording drift in a human-facing doc | CATCH | pass |
| M3 | Registry rule ids renamed so extraction collapses | CATCH | pass |
| M4 | Rule count reintroduced in a human-facing doc | CATCH | pass |
| M5 | Registry stops stating counts, floor must fire | CATCH | pass |
| C1 | New prose carrying bare id references | SILENT | pass |
| C2 | Unrelated prose edit beside the rule table | SILENT | pass |
| C3 | `Phase N lint rules` / `Layer 1 lint rules` prose | SILENT | pass |
| C4 | Unrelated cardinals (`8 scenarios`, `12 concerns`) near lint prose | SILENT | pass |

Each verdict also asserted the *other* guard stayed silent, so a mutation aimed at
one could not be scored by the other's reaction.

Wave 1's five guards were verified the same way, but with mutations **batched** and
the full five-guard verdict vector asserted on every run. Single-mutation runs cannot
detect cross-talk: a guard firing because a neighbour's subject changed is
indistinguishable from a guard working. The `SILENT` cells are where that shows up.

| Run | Mutations | Expected vector (010/011/012/013/014) | Result |
|-----|-----------|----------------------------------------|--------|
| A | Anchor leaks back into `plan.md`; a `NEVER read:` rule dropped; band table returns to the judge; `"total"` added to the schema | CATCH CATCH SILENT CATCH CATCH | pass |
| B | Judge's anchors *deleted* rather than moved; respawn downgraded to "Consider spawning"; schema reordered verdict-first | CATCH SILENT CATCH SILENT CATCH | pass |
| C | Agent stops refusing prior-iteration scores | SILENT CATCH CATCH SILENT SILENT | pass |
| D | Five legitimate edits: ordinary scoring prose, reworded rationale, a new `"confidence"` field | all SILENT | pass |

Runs A and C are the pair that matters. Both drop a rule from `<forbidden_inputs>`;
A expects PH5-012 to stay quiet and C expects it to fire, because only C removes the
specific line PH5-012's cross-side floor depends on. A guard that fired on any change
to the block would pass C and fail A, and nothing but the vector separates those.

Run B is the deletion-not-move probe: it mangles the judge's anchors while leaving
the generator side genuinely clean, so the only thing that can fail is the presence
floor. Had PH5-010 stayed silent there, "criteria moved out of generator reach" would
have been satisfiable by deleting the rubric from the repository altogether.

---

## 8. Verification

Run at every wave boundary, all from the plugin root:

```bash
bash tests/run-all.sh                # 5 layers, expect 0 failed
bash tests/layer1-config-wiring.sh   # cross-file consistency: A1a, A1b, A3, A12, A13
node tests/run-hook-corpus.js
claude plugin validate --strict
```

The structural guards live in layer 1, not layer 3. Layer 1's stated subject is
"plugin.json, commands/, agents/, README.md and CHANGELOG.md are internally
consistent", which is exactly what a cross-file drift check is; layer 3 runs lint
logic against fixture plans with deliberate defects, which is a different question.

Note also that the layer-1 sweep is slow on Windows (~2 min): it walks every tracked
`.md` file. Guards added there must do their extraction in a single `awk` pass — an
earlier draft of the PH5-001 guard spawned ~5 processes per matched line and did not
finish inside the suite's time budget at all.

`tests/expected-failures.txt` must remain empty. Note the scope limit already
recorded for this repo: `claude plugin validate` reads manifests only and never
reads agent or command frontmatter, so a green run proves nothing about whether
the judge isolation clauses in `plan-auditor.md` are wired — A4 exists precisely
because validate cannot cover it.

New test files:

- `tests/evidence-validate-test.js` — A5–A8
- `tests/canary-test.sh` — A9–A11
- `tests/fixtures/canary/` — 5 mutated spec fixtures
- `tests/fixtures/audit-payloads/` — valid and invalid judge outputs

---

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Judge reads the criterion files despite instruction | HIGH | MED | Stated as a known limitation (§5.1), not claimed as closed. Revisit by scoping tool access in a later version |
| Judge reads the canary bank | MED | MED | Rotate classes pseudo-randomly per run; claim only liveness detection (§5.4) |
| Evidence validation is slow on large specs | MED | LOW | Hash once per artifact per audit, cache by path; validation is line-slice comparison, not re-parsing |
| Stricter gate blocks plans that used to pass | HIGH | MED | Expected and intended. Migration note must say so plainly: plans that passed at 32-34 on prose scores will now fail until their claims carry evidence |
| Canary re-check reintroduces a second audit pass | LOW | LOW | Re-check is one criterion, not a full audit |
| Standalone `quick-audit` has no plan folder for `evidence/` | MED | LOW | Lite mode writes evidence to a temp path and reports inline; gate still applies |
| `commands/plan.md` is large; the Phase 5 rewrite touches ~350 lines | HIGH | MED | Wave boundaries keep each commit reviewable; suite runs at every boundary |

---

## 10. Rollback

Every change is markdown plus two new scripts and their tests. No state format
changes except the additive `score_history` and `evidence/` paths, both of which
older readers ignore.

- **Per wave:** `git revert` the wave's commits; the suite returns to green
  because each wave's guards land with that wave.
- **Whole change:** revert to `df8ac58` (v5.0.1). Plans audited under 6.0.0
  retain their `evidence/` directories, which are inert under 5.x.
- **Kill switch:** none, and this is deliberate — a runtime flag that restores
  the score gate would be the first thing reached for when the new gate blocks
  something, which is exactly when it is doing its job.

---

## 11. Out of scope

- Cross-model judging. `/toque:codex-challenge` already exists for that and
  is unchanged; making it the default Phase 5 judge is a separate decision.
- Multi-judge panels and verdict aggregation.
- Variance re-runs.
- Judge calibration against a human-labelled gold set. This is the natural
  successor to this spec: none of the mechanisms here measure whether the judge
  is *right*, only whether it is *evidenced*.
- Any change to Phases 1-4 or 6-9 beyond the LINT renumbering in Wave 0.
