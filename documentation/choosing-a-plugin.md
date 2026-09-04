# Choosing a plugin

Toque ships alone. The audit and readiness scanners it used to ship
alongside now live in a separate marketplace, [ai-scan](https://github.com/krwhynot/ai-scan). This page is the decision between them.

## The one-line version

| You want to… | Install |
| --- | --- |
| Find out whether an AI agent can work in this codebase at all | `ai-scan` |
| Get a severity-graded inventory of what is wrong with the code | `ai-scan-audit` |
| Take a change from idea to release with gates at every step | `toque` |

## Longer

### `ai-scan` — can an agent read this?

Scores how well an AI coding agent can **read, navigate, and safely modify** a
project. 52 checks across 9 categories produce a weighted composite and a letter
grade from A+ to F, plus a prioritized list of what to fix first.

This is a question about the *project's legibility*, not its code quality. A
well-written codebase with no `CLAUDE.md`, no clear entry point, and a
5,000-line monolith will score badly — correctly, because an agent will struggle
in it.

Reach for it when you are picking up an unfamiliar repo, or before you point
heavier tooling at one. It is also the cheapest of the three to run.

Ships in the `ai-scan` marketplace, not with Toque.

Two commands: `readiness-scan`, then `readiness-generate` to scaffold the gaps
it found.

### `ai-scan-audit` — what is wrong with the code?

A team of parallel agents produces a severity-graded audit report: features,
dependencies, docs, risk, integrations. Plus a security-focused scan, delta
tracking against a previous baseline, golden-master characterization tests, and
generated CI quality gates.

This is engineering due diligence — inheriting a codebase, evaluating an
acquisition, deciding whether a refactor is safe to start.

Five commands, of which `codebase-audit` is the entry point and
`codebase-delta` is the one you re-run later to prove things improved.

Also in the `ai-scan` marketplace.

### `toque` — how do I ship this change safely?

A six-stage workflow from intent to release, each stage committing one artifact
the next stage reads, with a human gate at every stage. Stage 2 ends in an
adversarial design gate that has to be passed, not scored.

This is the heavyweight of the three and the one with a real learning curve. It
is also the only one with hooks, the only one needing Node, and the only one
that changes how your day feels. See [When to use
Toque](./when-to-use.md#toque-planning) before committing to it — it is genuine
overkill for small work, and that page says so plainly.

Ten commands. `/toque:help` maps all of them.

## Do they need each other?

No. Each works alone, and since 11.0.0 they install from different
marketplaces, so you can take one without the other.

They do compose, though, and the ordering matters: readiness grades whether the
codebase is legible, audit finds what is wrong in it, and planning is how you
fix what audit found. Running an audit against a repo that scores below 70 on
readiness produces findings with lower confidence, because the scanners are
reading a codebase that is hard to read.

Toque reads audit output when it is present: a plan grounded in a real risk
assessment and dependency map is better than one written from the codebase
alone. It never requires it. See [interop.md](https://github.com/krwhynot/toque/blob/main/interop.md) for exactly which
files are read.

The [Quickstart](./quickstart.md) walks that full chain.

## Cost and time

All three spend model tokens rather than money on infrastructure — they run
inside your Claude Code session.

The rough ordering, cheapest to most expensive: a readiness scan is a bounded
pass over the repo's structure; a full codebase audit fans out to six parallel
agents and costs several times more; a six-stage plan is not a single run at all
but a workflow you return to over days.

These are shapes, not measurements. This repo does not publish benchmark
numbers, because it has no eval harness to produce honest ones.

## Related

- [Install](./install.md)
- [When to use Toque](./when-to-use.md)
