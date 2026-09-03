# Confidence brief — plan-centerpiece-alignment

Date: 2026-09-03 · Revision 3 (post CR-002)

## Headline

**Design: 84%.** **Execution: Spec — no implementation evidence exists yet.**

The headline is the floor of its components, not an average. The design is
well-evidenced; the *process that produced the numbers in it* failed twice and
has only just been repaired.

| Component | Confidence | Basis |
| --- | --- | --- |
| The problem is real | **99%** | Two independent reviewers and the arithmetic agree: a plan with the worst possible rollback (1/5) can total exactly 36/40 and be reported converged. Seven perfect dimensions outvote one fatal flaw — the thing the gate's own documentation forbids. |
| The decision (one verdict currency) | **95%** | Survived a Codex review that attacked the implementation and not the goal, and two design gates that found no fault with it. |
| CR-001 (delete rather than de-score) | **90%** | Removes 49 of 88 violations, the only external dependency, and the only HIGH-risk phase. Cost is named, not glossed: adversarial cross-model review is lost and nothing replaces it. |
| The inventory | **88%** | Now produced by a shipped, self-tested instrument (20 assertions) rather than asserted. Falsifiable by anyone who runs it. |
| The exclusion judgments | **70%** | The instrument tests *that* exclusions apply, not that they are *right*. "The readiness scan's letter grades are a different product" is a human call encoded in code. |
| Delivery plan | **75%** | Rebuilt under CR-002 but never gate-tested. The two previous delivery plans both failed. |

## Assumptions

| # | Assumption | Impact if false | Verification | Status |
| --- | --- | --- | --- | --- |
| A1 | Nothing consumes a score programmatically | Deletion breaks a caller | 23 references swept, all prose | **verified** |
| A2 | The instrument's pattern catches every scoring form in use | Same undercount that failed two gates | 20-assertion self-test, incl. all six historical miss classes | **verified** |
| A3 | METHODOLOGY outside §7 is a different product | A working feature is stripped | Read: lines 174-178 are the readiness scan's composite rating | **verified** |
| A4 | Report mode keeps the suite green pre-fix | The ordering defect that failed revision 1 recurs | Instrument exits 0 in report mode by construction | **verified** |
| A5 | `10-llm-rubric-calibration.md` can be rewritten without losing real content | 140 lines argue for what FR-1 abolishes | **Not attempted.** Open question. | **unverified** |
| A6 | A weaker third gate is still worth running | A pass means less than it appears | The `plan-auditor` agent is gone; no substitute is equivalent | **unverified, accepted** |

A5 is the one unverified HIGH-impact assumption. It blocks the phase that
touches that document, not the plan.

## What would change the assessment

- Running the instrument on a tree where the fixes have landed and getting a
  non-zero count would mean the pattern is *still* incomplete — the seventh
  error. That is the single most informative future observation.
- A5 resolving to "retire the document" rather than "rewrite it" would shrink
  the remaining work materially.

## Failure modes this plan has already exhibited

Recorded because the same classes are the likeliest way it fails again.

| Mode | Occurrences | Repaired by |
| --- | --- | --- |
| Asserted measurement, no shipped instrument | 2 gates | CR-002 — the instrument ships |
| Pattern too narrow | 3 (`N/5`, subtree scope, `X/40`) | 20-assertion self-test covering each |
| Pattern too broad | 1 (`RED` inside `REQUIRED`) | Word-bounded, self-tested |
| Tool mismatch | 1 (`awk` `\b`) | One tool throughout |
| Constraint changed without a change record | 1 (NFR-4) | Authorised retroactively in CR-002 |

Six counting errors in one session. The inversion removes the *class*; it does
not make the author more careful.

## Honest limits

- **The next gate is weaker than the two that failed.** The `plan-auditor` agent
  is unavailable. A pass under a weaker check is worth less, and this is
  recorded rather than worked around.
- **The instrument encodes judgment.** Its exclusion list is reviewable, not
  provably correct.
- **No implementation evidence exists.** Nothing has been built. Every claim
  about the delivery plan is about a document, not about working code.
