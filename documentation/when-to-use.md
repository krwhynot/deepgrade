# When to use Toque

The honest version, including the cases where you should not.

Toque is deliberately heavy in places. Knowing where it is overkill is what
makes the places it fits worth the cost.

## Toque

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

**The learning curve is real.** Six stages, six commands, and a gate that can
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

- [The plan workflow](./the-plan-workflow.md)
- [The design gate](./the-design-gate.md)
