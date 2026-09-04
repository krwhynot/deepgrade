# The design gate

Stage 2 of `/toque:plan` ends in an audit. The design gate decides whether that
audit is trustworthy enough to authorize Stage 3.

It is the most opinionated mechanism in the toolkit, and the reason the planning
plugin needs Node.

## The problem it solves

An AI audit of an AI-written spec has an obvious failure mode: the auditor says
"looks good" and nobody can tell whether it looked. A score does not help — a
lazy audit and a rigorous one both produce a number, and the number is the
auditor's own claim about itself.

So the gate does not score. It asks two questions with checkable answers:

1. **Did the auditor actually audit?** — proven by planting a defect and seeing
   whether it is found.
2. **Is the evidence real?** — proven by re-reading every cited file and
   comparing bytes.

**What question 2 does not ask is whether the evidence is *relevant*.** The
validator decides that a cited file exists, has not changed since the audit, and
contains the quoted text at the cited lines. It cannot decide that the quoted
text supports the criterion it is filed under — a record citing a closing brace
passes every mechanical check there is.

That limit is not a gap waiting to be closed. Relevance is a judgement about
meaning, and text comparison does not make judgements about meaning. Three
successive attempts to tighten this by machine each moved the bar by one
character and left the class untouched.

So read a green gate as: *the auditor was awake, and nothing it cited was
invented or stale.* Whether the evidence actually establishes each criterion is
the one part still on the human at the approval gate. It is a much smaller job
than auditing from scratch — every claim comes with a file, a line and a quote
you can check in seconds — but it is not zero, and the gate does not pretend
otherwise.

## The audit itself

A fresh, isolated `plan-auditor` agent returns criterion records. Each carries a
verdict and byte-addressed evidence — a file, a hash, a line range, and the
quoted text.

Isolation matters: the auditor does not share context with whatever wrote the
spec, so it is not reviewing its own work.

## `tq-canary.js` — checking the auditor

Before the audit runs, the canary injects one known defect into a **working
copy** of the spec. The original is never touched.

There are five rotating defect classes:

| Class | What it plants |
| --- | --- |
| `assumption-inject` | An unstated load-bearing assumption |
| `criteria-strip` | Removes acceptance criteria |
| `test-claim-inject` | A claim about testing that nothing backs |
| `rollback-strip` | Removes the rollback plan |
| `owner-strip` | Removes an owner or accountability line |

The audit then runs against the mutated copy. If it finds the planted defect,
the audit is trustworthy on that round.

- **One miss** asks for a re-run, not a failure.
- **Two consecutive misses** are fatal. The audit is untrustworthy and does
  **not** trigger the revision loop — because a revision loop driven by an audit
  that cannot see defects would launder the problem into a fix list.

A spec that no class can mark exits with an error rather than passing. A spec
that cannot carry a canary is a spec whose audit cannot be checked, and the tool
refuses to proceed unchecked instead of quietly skipping.

## `tq-evidence-validate.js` — checking the evidence

For every criterion record, this re-reads the cited file, verifies its hash,
slices the cited line range, and compares that slice to the quoted text
byte-for-byte.

The critical property: **it can only demote a verdict, never promote one.** A
citation that does not match demotes the finding. A finding with clean evidence
is left exactly where the auditor put it. The validator can make an audit
harsher; it can never make one more favorable.

## The pass expression

```
PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

Four booleans, all required. There is no weighted sum and no partial credit —
those are the mechanisms that let a marginal audit argue its way through.

## The known limitation

Stated here rather than buried, because it bounds what the gate proves:

**The auditor can read the canary's defect table.** The five classes live in the
plugin's own files, which an auditor with repository access can see.

So the mechanism reliably detects a **lazy** audit — one that did not look — and
only incidentally detects an **adversarial** one that has decided to game the
check. Treat a passing gate as evidence of diligence, not of incorruptibility.

## Failure modes

| Situation | What happens |
| --- | --- |
| Node missing | Both tools fail; Stage 2 cannot pass. No degraded mode |
| Canary missed once | Audit re-runs |
| Canary missed twice | Fatal. Revision loop forbidden |
| No canary class applies | Exit 2 with the list of classes tried |
| Evidence does not match | That finding is demoted |
| Everything passes | Stage 2 clears; Stage 3 needs separate human approval for codebase writes |

## Where the files go

| Output | Location | Committed? |
| --- | --- | --- |
| Audit evidence | `docs/plans/{date}-{name}/evidence/` | Yes |
| Canary working copy | `docs/plans/{date}-{name}/.canary/` | No |

## Related

- [The plan workflow](./the-plan-workflow.md) — where Stage 2 sits
- [When to use Toque](./when-to-use.md#the-design-gate-specifically)
- `plugins/toque/GUIDE.md` — the full reference
