# Codex review of the Part A design

Date: 2026-09-03 · Reviewer: Codex CLI 0.153.0, `codex exec --sandbox read-only`
Prompt: challenge the proposed design for over-engineering; favour the simplest
thing that works; name the cheaper option if one exists.

Verbatim answers to the five questions asked.

## 1. Is the proposed change over-engineered? — **Yes**

> The proposal fixes the defect, but it turns one bad convergence predicate into
> a cross-tool contract migration.

## 2. Is there a materially simpler fix that still closes the 36/40 defect? — **Yes**

> Keep the scorecard and require both conditions:
>
> `GREEN = total >= 36 && every_dimension >= PASS_FLOOR`
>
> Define `PASS_FLOOR` from the existing rubric—likely 4/5. Add one regression
> case for `[5,5,5,5,5,5,5,1] → NOT CONVERGED`. No fatal dimension can then be
> averaged away.

## 3. Is expand/contract justified? — **No, it is ceremony**

> The prompt, schema, parser, and fixtures ship together. Unless external
> consumers or mixed plugin versions exchange these payloads, make any eventual
> contract change atomically. Tests and fixtures are not independent consumers.

**Accepted without reservation.** The spec's Approach section was wrong. The
methodology exists for contracts with independent consumers; four fixtures and
one parser in the same commit are not that.

## 4. Is severity-based convergence actually better? — **Partly no. This is the catch I missed.**

> The non-compensating gate is better; "findings only" is not necessarily
> better. Severity is still an LLM judgment, not an objective measurement.
> Worse, "no blocking findings" can mean "nothing is wrong" or "the model
> omitted the dimension." The current scorecard at least forces coverage of all
> eight dimensions. If you later replace it, require an explicit verdict and
> evidence for every dimension—not merely emitted findings.

**This is a correctness hole in Option A, not a simplicity complaint.**

A findings-only response cannot distinguish *"rollback is sound"* from *"the
reviewer never looked at rollback."* Silence is ambiguous. The scorecard's
requirement that all eight dimensions carry a number is doing real work:
it forces coverage. Option A as written in spec.md removes that guarantee and
puts nothing in its place.

The last sentence is also the repair: require an explicit verdict **per
dimension**, with evidence, rather than accepting whatever findings happen to be
emitted.

## 5. What would you do instead?

> I would keep both score-producing tools intact, change `codex-challenge` so
> GREEN requires 36/40 plus every dimension passing its minimum, and ensure
> round-cap exhaustion reports NOT CONVERGED. Add the single regression test,
> delete the four stale rubric references, and remove the fictional
> `score_history` documentation. The eight-line relabel is insufficient because
> documentation cannot neutralize a score that still controls execution. Treat
> wholesale severity-schema unification as a separate cleanup only if
> inconsistent outputs are causing a real user problem.

---

## Assessment of the review

**Where Codex is right and its finding is absorbed:**

- **Expand/contract is ceremony here** (Q3). Removed from the design.
- **The coverage hole is real** (Q4). Option A as specified is defective, and
  the defect is worse than the one it fixes: an omitted dimension reads as a
  clean one.
- **Relabel is dead** (Q5): *"documentation cannot neutralize a score that still
  controls execution."* This retires the alternative recorded in intent.md OQ1
  on a stronger argument than the one used to reject it there. Worth noting the
  accepted decision to strip was directionally sound even though the
  implementation was over-built.

**Where the review answers a narrower question than the intent asks:**

Codex optimises for closing the **36/40 defect**. The accepted intent's Problem
is **two verdict currencies**, of which the defect is one symptom. Its Q5
recommendation explicitly defers currency unification — *"only if inconsistent
outputs are causing a real user problem"* — which is a legitimate position but a
different goal than the one accepted at the Stage 1 gate.

Both facts stand; they are not averaged. The choice between them is a scope
decision the owner makes at scope lock, not a technical one the reviewer
settles.

**The synthesis Codex itself points at (Q4, final sentence):** strip the score,
but require an explicit verdict plus evidence for **every** dimension. That
keeps one currency (the intent's goal) and keeps enforced coverage (Codex's
catch). It is more work than Codex's minimum and less than spec.md's Option A,
since the expand/contract staging is gone.
