# When to use Toque

The honest version, including the cases where you should not.

Toque is deliberately heavy in places. Knowing where it is overkill is what
makes the places it fits worth the cost.

## `toque-readiness`

**Use it when**

- You are picking up a codebase you did not write and want to know what you are
  in for.
- An AI agent keeps getting lost in a repo and you want to know why, in
  specifics rather than vibes.
- You are about to run a deeper audit and want a baseline first.
- You maintain several repos and want them graded on one consistent scale.

**Skip it when**

- The repo is a few hundred lines. The 52 checks will mostly report absence, and
  absence is not informative at that size.
- You already know the answer. If there is no `CLAUDE.md`, no tests, and one
  4,000-line file, you do not need a scan to tell you the grade is bad.

**What it will not tell you.** Whether the code is *correct*, *secure*, or
*well-designed*. It grades legibility to an agent. A beautifully architected
service with no entry-point documentation scores worse than a mediocre one that
explains itself.

## `toque-audit`

**Use it when**

- You are inheriting or evaluating a codebase and need findings you can hand to
  someone else.
- You want to know what a refactor would put at risk before starting it —
  `codebase-characterize` captures current behavior as golden-master tests
  first.
- You need to demonstrate improvement over time. `codebase-delta` re-measures
  against the previous baseline.

**Skip it when**

- You want a code review of a specific change. This audits a *codebase*, not a
  diff. Use a review tool for diffs.
- The codebase scores below 70 on readiness. The audit will still run, but its
  scanners are reading a project that is hard to read, and confidence on
  affected modules drops accordingly. Fix legibility first.

**What it will not tell you.** Whether the findings are worth fixing in your
context. Severity is assigned from the code, not from your roadmap.

## `toque` (planning)

This is the one to be honest about, because the failure mode is enthusiasm.

**Use it when**

- The change is large enough that getting the design wrong costs more than the
  planning does.
- More than one person has to agree on what is being built before it is built.
- You need an auditable trail — what was intended, what was specified, what was
  decided and why. Each stage commits an artifact the next stage reads.
- The work is risky enough to want a rollback plan written before the change,
  not after.

**Do not use it when**

- The change is small. A six-stage workflow around a one-line fix is theatre.
  `/toque:quick-plan` exists for exactly this and is the right answer far more
  often than the full workflow.
- You are exploring. The gates assume you know roughly what you are building.
  Prototyping under a design gate is friction with no payoff.
- You are the only stakeholder and the work is reversible. Most of the value is
  in the artifacts other people read.
- You do not have Node 18+. Stage 2 cannot pass without the design-gate tools,
  and there is no degraded mode.

**The learning curve is real.** Six stages, ten commands, and a gate that can
refuse your plan. Start with `/toque:quick-plan` or `/toque:quick-audit` on
something small before you run the full workflow on something that matters.

## The design gate specifically

The gate is the most opinionated thing in the toolkit, and it will occasionally
refuse an audit that you believe was fine.

That is the intent — an audit that cannot be shown to be trustworthy does not
get to authorize the next stage. But it means Stage 2 is not a rubber stamp, and
if you want a rubber stamp you will find it frustrating.

Its known limitation is documented rather than hidden: the auditor can read the
canary's defect table, so the mechanism reliably detects a *lazy* audit and only
incidentally an *adversarial* one. Full detail in [The design
gate](./the-design-gate.md).

## What none of it does

- **It does not deploy.** The agent never crosses the production gate. Stage 5
  produces a release checklist and stops.
- **It does not decide.** Every stage ends at a human gate.
- **It does not publish benchmark numbers**, because there is no eval harness
  behind them. Claims here are about mechanism, not measured performance.

## Related

- [Choosing a plugin](./choosing-a-plugin.md)
- [The plan workflow](./the-plan-workflow.md)
- [The design gate](./the-design-gate.md)
