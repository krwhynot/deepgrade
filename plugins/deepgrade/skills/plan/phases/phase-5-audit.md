# Phase 5: AUDIT

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

## Contents

- Checks 1-4: score, devil's advocate, codebase verification, gap verification
- Outputs A-D: coverage matrix, assumption register, scenario matrix, cross-cutting sweep
- Canary (run before the auditor is spawned)
- Evidence validation
- Infrastructure verification
- Plan lint rules and gap summary
- Confidence reinforcement
- Baseline snapshot and score distribution
- Gate: evaluator-optimizer loop, rubric-free pass, gate expression
- Revision feedback and auditor isolation
- Human review gate and waiver condition

Question: What is weak or missing?

Run four checks using the plan-auditor agent:

CHECK 1 - 8-DIMENSION SCORE:
The rubric, its per-level anchors and the band interpretation live in
`agents/plan-auditor.md`. They are deliberately not repeated here.

This file is read by the Phase 4 generator. A generator that can see the scoring
function writes to the scoring function — it produces text shaped like each anchor
rather than a plan that happens to score well, and the two are indistinguishable
from the score alone. Keeping the rubric on the auditor's side is what makes the
score a measurement of the plan rather than a measurement of how well the generator
remembered the rubric.

The score is reported. Under the verifier-first gate it does not authorize passage
(see GATE below), so its role is trend and triage, not permission.

CHECK 2 - DEVIL'S ADVOCATE:
Challenge each assumption. For each challenge, cite evidence or flag [VERIFY].
Structured premortem questions:
  "If this fails in production, what is the most likely reason?"
  "What did we assume would be true but isn't?"
  "What changed in one layer but not another?"
  "What behavior works in tests but fails in browser/runtime?"

CHECK 3 - CODEBASE VERIFICATION:
Confirm file paths, line numbers, function names referenced in plan actually exist.

CHECK 4 - GAP VERIFICATION (new):
This check produces 4 structured outputs that catch systematic gaps.
A plan CANNOT be considered gap-checked until all 4 outputs exist.

OUTPUT A: Coverage Matrix
Map every goal, risk, dependency, and non-goal to its plan artifact:

```markdown
## A. Coverage Matrix

| Item | Type | Covered By | Status |
|------|------|-----------|--------|
| bilingual receipts | goal | Phase 1, POS-5163, tests T1/T2 | covered |
| certification timeline | dependency | Phase 4, owner TBD | partial |
| rollback | operational | plan section + handoff | covered |
| CORS handling | non-goal | explicitly excluded | ok-excluded |
| user pagination | assumption | not addressed | GAP |
```

Rules:
- Every goal must map to at least one phase AND at least one ticket
- Every risk must map to a mitigation
- Every dependency must map to an owner or blocker
- Every rollout item must map to monitoring + rollback
- Every non-goal must NOT accidentally appear in the plan
- Items marked GAP fail the gap check

OUTPUT B: Assumption Register
Every assumption the plan makes, with impact-if-false and verification:

```markdown
## B. Assumption Register

| # | Assumption | Impact If False | How to Verify | By When | Owner | Status |
|---|-----------|----------------|---------------|---------|-------|--------|
| 1 | User lookup fits in first page | Breaks onboarding flow | Check query with production data volume | Before Phase 2 | Kyle | unverified |
| 2 | triPOS SDK supports Canada | Blocks entire plan | Test API call to Canadian endpoint | Phase 1 | Kyle | verified |
| 3 | Supabase rate limit handles OTP volume | Throttles users at scale | Load test 100 concurrent OTPs | Before launch | TBD | unverified |
```

Rules:
- Every assumption must have an impact assessment
- Unverified high-impact assumptions are BLOCKERS
- Assumptions with no validation step are WARNINGS
- Assumptions that block execution must be verified before Build phase

AUTOMATED ASSUMPTION VERIFICATION:
After generating the Assumption Register, attempt automated verification
of all assumptions that have a verification method:

For each assumption where impact = HIGH and status = unverified:
  1. If verification method mentions file/path: run `test -f [path]`
  2. If verification method mentions API/endpoint: note as REQUIRES_MANUAL
  3. If verification method mentions schema/database: search for schema files
  4. If verification method mentions config: search config files
  5. Update assumption status in status.json:
     - verified: automated check passed
     - unverified: automated check failed or not automatable
     - falsified: automated check proved assumption false

Track verification results:
  "Assumptions: X total, Y verified (Z automated, W manual), V unverified, F falsified"

OUTPUT C: Scenario Matrix
The auditor maps a fixed set of scenarios to implementation, test and monitoring.
The scenario list and the output table live in `agents/plan-auditor.md`; they are
not repeated here, for the same reason the rubric is not.

What the plan itself must do — state this to the generator, not the list:
the plan has to account for how the change behaves when it works, when it fails,
while old and new run side by side, under load, at permission boundaries, across
environment differences, and on the way back out. A plan written against a named
checklist tends to grow a section per checklist item; a plan written against the
requirement tends to notice which of those actually apply to it and say so.

Every scenario in the auditor's set gets an entry, including "not applicable" with
a reason. Items marked GAP fail the gap check.

OUTPUT D: Cross-Cutting Concern Sweep
The auditor checks every feature and change against a fixed set of concerns. That
set and its output table live in `agents/plan-auditor.md` and are not repeated here.

What the plan itself must do: address the concerns that cut across the change
rather than sitting inside one component — the contract it exposes, who is allowed
to call it, what differs between environments, how it behaves at the network and
data-access boundary, what it emits when running, and how it migrates and rolls
back. Concerns that genuinely do not apply are excluded explicitly with a reason.

Every concern in the auditor's set gets a verdict. Unaddressed concerns are GAPS;
partial ones are WARNINGS.

CANARY (automated, run BEFORE the auditor is spawned):

Every other check in Phase 5 examines the plan. This one examines the auditor.

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/dg-canary.js" inject \
  docs/specs/{plan-name}.md docs/plans/{date}-{plan-name}/.canary/
```

One known defect is injected into a working copy of the spec — a rollback line
removed, a dependency owner blanked, an unverified HIGH-impact assumption added,
go/no-go criteria deleted, or a claim of coverage from a test file that does not
exist. The class is recorded along with the single criterion it violates.

The auditor then audits the MUTATED copy, knowing nothing of any of this.

Afterwards:
  1. If the recorded criterion is NOT in the audit's UNMET set, the audit missed a
     defect that was placed there to be found. Re-run once with a different class.
     A second miss fails the gate as "audit untrustworthy" — and DOES NOT trigger
     the revision loop. Revising a plan against findings from an audit that could
     not see a planted defect is worse than not revising: it rewrites the spec to
     satisfy conclusions never derived from reading it.
  2. If it was found, strip that finding from the report — it is an artefact of
     this harness, not a property of the plan — and then RE-CHECK that one
     criterion against the unmutated original. The strip alone is unsafe: if the
     plan has a genuine gap on the same criterion, removing "the LINT-03 finding"
     would remove the real one with it. The strip removes the artefact; the
     recheck decides the truth.

An audit reporting zero gaps on a document known to contain a defect is not a
clean audit. It is a broken one, and nothing in its output would tell you so.

Known limitation, stated rather than glossed: the auditor can read
`scripts/dg-canary.js`, including its defect table. This detects a lazy audit
reliably and an adversarial one only incidentally. Rotating the class per run
raises the cost of pre-empting it; it does not make the canary tamper-proof.

EVIDENCE VALIDATION (automated, run before anything is treated as MET):

The auditor returns criterion records, each carrying its evidence. Those records are
a PROPOSAL, not a result. Re-check every one of them mechanically:

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/dg-evidence-validate.js" \
  docs/plans/{date}-{plan-name}/evidence/
```

The validator re-reads each cited artifact, confirms its hash still matches, slices
the cited line range and asserts the quoted text is byte-identical to it. It can only
ever DEMOTE a verdict — there is no input that makes it turn an UNMET into a MET. Use
the verdicts it returns, never the verdicts the auditor claimed.

A record comes back UNMET, with a flag naming the reason, when:
  EVIDENCE-INVALID           the quote does not match the lines it cites
  EVIDENCE-MISSING           MET was claimed with no evidence at all
  EVIDENCE-STALE             the artifact changed after the record was written
  EVIDENCE-ARTIFACT-MISSING  the cited file does not exist
  EVIDENCE-RANGE-INVALID     the cited line range does not exist in the file
  EVIDENCE-UNEXECUTED        an executable criterion retained no command
  EVIDENCE-COMMAND-FAILED    the retained command exited non-zero

The fourth rule is the one that matters most and is easiest to soften by accident:
an externally checkable claim with no evidence is UNMET. Not PARTIAL, not a warning,
not "verified but undocumented". This project has lost that argument twice — a layer
was recorded PARTIAL with its result asserted in a commit message and no artifact in
any commit, and a whole wave was closed against greps typed at a terminal that left
nothing behind. Both are UNMET here without anyone needing to notice.

Do not re-run the auditor to "resolve" a demotion. A demotion is not a disagreement
to be settled; it means the evidence was not there, and the fix is in the plan.

COMMIT the evidence directory together with audit.md. An audit whose evidence is not committed did not happen.

This is the rule that makes an audit auditable later. A verdict is only as good as
the ability to re-derive it, and a re-check needs the records, the artifacts and the
hashes that bound them together at the time. Without them the audit degrades into
testimony — "it passed when I ran it" — which is exactly the class of claim this
project has already had to refuse twice.

Exit codes from the validator, which the gate branches on:
  0  every record survived re-checking
  1  at least one claimed MET was demoted — the gate does NOT open
  2  the evidence directory is missing or empty

Treat 2 as the most serious of the three. A missing directory is not a clean run
with nothing to report; it means the audit produced no evidence at all, and reading
it as a pass would rebuild the exact failure this replaces — a phase recorded green
on the strength of a claim that no artifact anywhere supports.

INFRASTRUCTURE VERIFICATION (automated, run after gap matrices):
Cross-reference every coverage claim against verifiable artifacts.

For each Scenario Matrix "Tested?" entry with a test file reference:
  1. Check if the test file exists: `test -f "$TEST_PATH"`
  2. If file exists, check it contains a relevant test: `grep -c "$SCENARIO_KEYWORD" "$TEST_PATH"`
  3. If file missing or no matching test: flag as INFRA-GAP

For each Scenario Matrix "Monitored?" entry with a monitoring reference:
  1. Search for dashboard configs, alert rules, or monitoring setup files
  2. If monitoring config missing: flag as INFRA-GAP

For each Coverage Matrix "Covered By" entry with a file reference:
  1. Verify the referenced file exists and contains relevant implementation
  2. If file missing or no matching implementation: flag as INFRA-GAP

INFRA-GAP is a distinct severity: the plan CLAIMS coverage but the
infrastructure to deliver that coverage does not exist. This is more
dangerous than a known gap because it creates false confidence.

Report: "Infrastructure Verification: X/Y claims verified (Z% rate)"
List all INFRA-GAPs with the claim, expected file, and actual status.

PLAN LINT RULES (automated, run before presenting results):
These are binary pass/fail checks. Any FAIL is a gap.

Rule text and the applicable rule set live in `docs/planning-techniques/lint-registry.md`.
Read it and apply every rule the registry assigns to Phase 5 in the current audit mode.
This file names ids only — it does not restate what a rule means, so the two cannot
drift apart. Report one PASS/FAIL per id, using the ids exactly as the registry
numbers them.

Apply at Phase 5: the registry's Phase 5 set.
LINT-14 is skipped on the first audit (no baseline exists to regress from).
LINT-11 and LINT-12 belong to Phase 7 and do not run here.

GAP SUMMARY:
After all 4 outputs + lint rules, produce:

```markdown
## Gap Summary

Lint: {N}/{applicable} passed, {M} failed   <- denominator = the registry's Phase 5 set for this mode
Coverage Matrix: {N} items, {M} gaps
Assumption Register: {N} assumptions, {M} unverified high-impact
Scenario Matrix: 8 scenarios, {M} gaps
Cross-Cutting Sweep: {N} concerns, {M} gaps

Total gaps: {sum}
Total warnings: {sum}

Gap-checked: YES / NO
```

A plan is gap-checked ONLY when:
- Every rule in the registry's Phase 5 set passes (enumerating a subset here is how
  the count drifted to four different values before PH5-001)
- Coverage matrix has zero GAPs
- No unverified HIGH-impact assumptions
- Scenario matrix has zero GAPs
- Cross-cutting sweep has zero GAPs
- Infrastructure verification has zero INFRA-GAPs

Write docs/plans/{date}-{plan-name}/audit.md with: scored dimensions, challenges, verification results, ALL 4 gap verification outputs, lint results, gap summary.

Update manifest.md: add audit.md to Plan Files table with date and score.

CONFIDENCE REINFORCEMENT (after audit, before baseline):

Re-read confidence.md (created in Phase 3) and reinforce it with audit findings:

1. AUDIT-DRIVEN ADDITIONS:
   - If the audit identified new dependencies, patterns, or tools not in the
     original confidence.md (e.g., from gap-filling revisions), add entries.
   - If the audit challenged an assumption about a tool/method and the
     challenge was resolved, add a "Validated by audit" note to that entry.

2. STRESS-TEST ANNOTATIONS:
   For entries where the audit found weakness or gaps, add a subsection:
   ```markdown
   **Audit note ({date}):** {What the audit found — e.g., "Devil's advocate
   challenged whether YamlDotNet handles multi-document streams. Verified:
   YamlDotNet 16.x supports multi-doc via `LoadStream()`. No gap."}
   ```
   For entries where audit found a real gap, note the gap AND how it was resolved:
   ```markdown
   **Audit note ({date}):** {Gap found and resolution — e.g., "Audit flagged
   missing error handling for malformed YAML. Added try/catch in Phase 5
   revision v2. Gap closed."}
   ```

3. UPDATE HEADER:
   Set "Last reinforced: {date} (Phase 5)" in the confidence.md header.

4. NEW CROSS-PLAN REFERENCES:
   If the audit revision introduced tools/patterns that exist in other plans,
   add "Also referenced in" links.

Update manifest.md: update Confidence row with reinforcement date.

BASELINE SNAPSHOT:
After writing the audit, capture a per-element baseline in status.json:
```json
{
  "baseline": {
    "run_number": 1,
    "date": "{ISO date}",
    "plan_version": "v1",
    "lint_results": { "LINT-01": "pass", "LINT-02": "pass", ... },
    "coverage_items": [{ "name": "...", "status": "covered|gap" }],
    "assumption_counts": { "total": N, "verified": N, "unverified": N, "waived": N },
    "scenario_statuses": [{ "id": 1, "name": "Happy path", "status": "covered|partial|gap" }],
    "concern_statuses": [{ "name": "API contract", "status": "ok|warn|gap" }],
    "dimension_scores": [{ "name": "Problem Definition", "score": 4 }],
    "infra_gaps": N
  }
}
```

On re-audit (after revision loop or manual re-run), compare current vs baseline:
- REGRESSION: item was covered/passing, now gap/failing -> flag in audit output
- IMPROVEMENT: item was gap/failing, now covered/passing -> report as progress
- NEW: item not in previous baseline -> report for awareness

Report: "Baseline comparison: X regressions, Y improvements, Z new items"
Regressions are flagged as HIGH priority in the audit output.

This comparison is what LINT-14 is evaluated against (see the registry for its text).
Only an element that was covered/passing in the previous baseline and is now
gap/failing counts; pre-existing gaps do not trigger it. Skipped on the first audit,
when no baseline exists.

Update the baseline in status.json after each comparison (append to history array
for trend tracking).

SCORE DISTRIBUTION (append on every audit, including re-audits):

Record each audit's score in a score_history array in status.json:
```json
{
  "score_history": [
    { "date": "{ISO date}", "plan_version": "v1", "iteration": 1,
      "score": 27, "canary_found": true, "gate_passed": false },
    { "date": "{ISO date}", "plan_version": "v2", "iteration": 2,
      "score": 36, "canary_found": true, "gate_passed": true }
  ]
}
```

The score no longer gates, but its distribution is still the cheapest detector of
the gate being gamed. A cluster of totals sitting just above any historical
threshold — 32-34 under the old regime — is the statistical signature of
threshold-aiming, and it is visible only as a series. One audit's score means
almost nothing; forty audits piling up at the same boundary means the boundary is
being aimed at. Keeping the series costs one array append.

GATE: Evaluator-Optimizer Loop.

RUBRIC-FREE HOLISTIC PASS (advisory, runs alongside the gate):

RUN one additional judge with no rubric, no criterion list, and no dimension names.

Its entire prompt is: "Ignore any checklist. What would make this plan fail in
production?" Fresh instance, same input manifest as the auditor, none of the
criterion files.

Map its findings against the criterion set afterwards. A finding that maps to an
existing criterion is discarded — the gate already covers it. A finding that maps
to NOTHING is appended to docs/planning-techniques/lint-candidates.md with the plan
name and date, as a candidate rule for owner review.

This pass never gates, and that is deliberate. Every other mechanism in Phase 5
makes the judge honest ABOUT the criteria; none of them can notice that the
criteria are incomplete. A plan can satisfy every rule and still be bad in a way no
rule names — rubric-design failure as distinct from verifier failure. This is the
only check on that class, and its output is a proposed rule, not a verdict on the
current plan: gating on unmapped findings would just re-create the unfalsifiable
prose judgment the gate rewrite removed.

The gate does not read the score. It reads whether the claims survived checking.

<gate_expression>
CANARY_OK   = the criterion the planted defect violates came back UNMET
EVIDENCE_OK = dg-evidence-validate.js exited 0 (nothing was demoted)
VERIFIED    = every applicable criterion is MET or N_A after validation
INFRA_OK    = infra_gaps == 0

PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
</gate_expression>

Every term is re-derivable by someone who has the plan folder and did not run the
audit. That is the property being bought here: the previous gate authorised passage
on a number the audited model chose for itself, and no reader could tell a plan that
earned it from one that was written to earn it.

There is no weighted sum, so a strong showing on seven criteria cannot offset a
failure on the eighth. Non-compensability is the thing a 40-point total structurally
cannot give you.

IF PASS:
  -> "Plan is solid. Ready to start building."
  -> Proceed to Phase 6.

IF NOT PASS:
  -> If CANARY_OK is false after a re-run: STOP. Do not revise. The audit could not
     see a defect placed for it to find, so its other findings are not a basis for
     rewriting anything.
  -> Otherwise auto-trigger revision of the Phase 4 spec, using the feedback form
     below.
  -> Revise ONLY the failing sections (not the entire spec).
  -> Re-run the audit on the revised spec.
  -> Compare re-audit against baseline: flag any regressions (items that
     were passing in v1 but now fail in v2). Regressions indicate the
     revision broke something that was previously working.
  -> Maximum 2 revision iterations.

<revision_feedback>
Send the generator defects and locations. One line per unmet criterion:

  {criterion_id} UNMET: {what is missing}. Location: {file}:{line}.

Worked example:

  LINT-03 UNMET: Phase 2 database migration has no rollback step.
    Location: docs/specs/plugin-hardening-v5.md:142.

Never send the rubric, the totals, the bands, or how near the plan came to passing.
The generator cannot see any of that when it writes, and returning it through the
revision channel would hand back exactly what was withheld — after which the cheapest
response is prose shaped like the missing thing rather than the missing thing itself.

A defect the generator can locate is a defect it can fix. A number it can chase is a
number it will chase.
</revision_feedback>

SPAWN A NEW plan-auditor INSTANCE for every audit iteration. Do not re-audit inside
the instance that produced the previous verdict, and do not pass it the previous
audit.md, the previous score, or a summary of either.

An evaluator that already published a number for v1 is, on v2, checking its own
prior judgement. The consistent story available to it is that the revision fixed
what it said was broken, so the second audit tends to ratify the first rather than
re-derive it — and the loop's regression check is exactly the thing that cannot
work if the same evaluator grades both sides of it. The agent refuses prior-iteration
scores on its side too (see <forbidden_inputs> in agents/plan-auditor.md); both
halves are required, because either alone is a single point of failure.

The baseline comparison above is done by the CALLER, which holds both audits. The
judge sees one spec and reports on it, and never learns that a previous attempt
existed.

After revision loop completes, report against the gate, not against a band:
- PASS: "Plan revised and now solid. Ready to build."
- NOT PASS, criteria still unmet after 2 iterations: "Plan has remaining unmet
  criteria. Fix manually: [list each id with its defect and location]"
- NOT PASS because evidence was demoted: "Claims in this plan are not supported by
  what they cite: [list each flag]. These are not near-misses; the cited text does
  not say what the plan says it says."
- NOT PASS because the canary was missed twice: "The audit could not be trusted and
  no revision was attempted. Re-run Phase 5 before reading any of its findings."

A plan does not "usably pass with known gaps". Either every applicable criterion is
satisfied and evidenced, or the specific ones that are not get named. The old
YELLOW rung existed because a 24-31 total had to mean something; without the total
there is nothing for it to mean, and "proceed with known gaps" was the rung most
often used to proceed without reading them.

Track revision history in audit.md:
```markdown
## Revision History
| Version | Score | Gap-Checked | Gaps | Action |
|---------|-------|-------------|------|--------|
| v1      | 24/40 | NO          | 7    | Auto-revised sections 4, 5, 7 |
| v2      | 35/40 | YES         | 0    | Accepted |
```

Update status.json (include score, rating, gap_checked boolean, gap_count), manifest.md.

HUMAN REVIEW GATE (conditionally waivable):
After the automated audit completes, prompt for human review before Build:

"Automated audit complete (score: {X}/40, gap-checked: {YES/NO}).
 Before starting Build, this plan should be reviewed by at least one person.
 [1] Enter reviewer name(s) to proceed
 [2] Waive review (solo mode) — requires documented reason, and only offered
     when the waiver condition below holds
 [3] View audit summary first"

<waiver_condition>
waiver_allowed = (infra_gaps == 0)
                 AND (score >= 35)
                 AND (canary_found == true)
</waiver_condition>

This is the one place the score is load-bearing, and the asymmetry is the design:
the score cannot let a plan PASS the gate, but a borderline one can remove the
owner's ability to SKIP review. A gameable signal is safe in the direction that
adds friction. The 32-34 band — the scores that sat just above the old threshold —
is exactly where threshold-aiming lands, so a plan scoring there gets a human
whether or not the automated gate passed.

If the waiver condition fails, option [2] is not offered at all. Do not present it
greyed out with the reason; a visible near-miss invites one more revision aimed at
the waiver rather than at the plan.

If [1]: Record reviewer name(s) and date in status.json:
  { "review": { "reviewers": [{"name": "...", "date": "..."}], "outcome": "accepted" } }
  Proceed to Phase 6.

If [2]: Record waiver in status.json AND stamp it visibly:
  { "review": { "waived": true, "reason": "...", "waived_by": "...",
                "waiver_condition": { "infra_gaps": 0, "score": X, "canary_found": true } } }
  Also append one line to audit.md and to the Phase 9 handoff:
  "Review waived (solo mode) by {name} on {date}: {reason}"
  A waiver recorded only in machine state is invisible to the person reading the
  plan later, which is the person it exists to warn. Proceed to Phase 6.

If [3]: Show audit-derived review checklist:
  - Audit scorecard (8 dimensions with scores)
  - Top 3 gaps identified
  - Top 5 risks identified
  - Key assumptions and their verification status
  - Cross-cutting concerns flagged as partially addressed
  Then re-prompt [1] or [2].

If [1] with reviewer names: Record review in status.json:
  { "review": {
      "reviewers": [{"name": "...", "date": "...", "decision": "accepted"}],
      "outcome": "accepted",
      "checklist_presented": true,
      "comments": 0
  }}

For team/leadership plans: review is REQUIRED (option [2] not offered unless
the plan was started in solo mode or the user explicitly requests solo mode).

For solo mode: review is recommended but waivable with documented reason.
