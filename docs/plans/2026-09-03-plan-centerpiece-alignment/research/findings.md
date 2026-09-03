# Stage 1 research findings

Date: 2026-09-03
Tracks run: codebase scan only. Track 2 (source doc cleanup) was satisfied
before research began — see `research/intake/session-findings.md`. Track 3
(external best practices) was **skipped deliberately**: this is an internal
coherence question about one codebase's own conventions, and no external source
can answer whether these tools should agree with each other. Skipping is
recorded rather than silently omitted.

Method: `grep` over `plugins/toque/`, every hit read in place. No subagents —
one independent track is below the skill's 3-track parallelisation threshold.

---

## R1 — Open question 2 is RESOLVED: nothing consumes the score

**Question:** does anything read `quick-audit`'s X/40 programmatically, which
would make stripping it a code change rather than a wording change?

**Answer: no.** Every reference to `/toque:quick-audit` outside its own command
file is prose — a suggestion to run it, a row in a help table, or a mode label.
Twenty-three references checked; not one parses, stores, compares, or branches
on a score.

The closest thing to a consumer is `agents/plan-auditor.md:241,253`, which
switches between FULL and LITE mode by *caller*, not by score.

**Consequence:** stripping is safe from a data-flow standpoint. Its cost is
entirely in `codex-challenge`, whose loop is score-driven (see R4).

## R2 — NEW: the guide documents a field that does not exist

`plugins/toque/GUIDE.md:265` states:

> `status.json` keeps a `score_history` for trend-watching, but nothing reads it
> as a gate.

`score_history` appears exactly twice in the entire repository: in that sentence,
and in `tests/layer1-repo.sh:857`, which is the guard **forbidding** it. Nothing
writes it. No `status.json` in `docs/plans/` contains it.

The field was removed with scoring in 8.0.0 and the guide was not updated. This
is a false claim in shipped documentation, and it is wrong under either
resolution of the scoring question.

## R3 — NEW: two more stale rubric citations, in an agent

The intake found stale citations in `codex-challenge/SKILL.md:27` and
`commands/quick-plan.md:2`. The scan found two more, in a file the intake did
not cover:

- `agents/plan-scaffolder.md:24` — "Auditable (would score 32+/40 on the
  plan-auditor)"
- `agents/plan-scaffolder.md:232` — "Score against the 8 plan-auditor
  dimensions (target 32+/40)"

Four stale citations total, in three files, across both commands and agents.

## R4 — Scope is concentrated, and it is smaller than first stated

Precise inventory. The pattern is `/40`, `score_history`, `scorecard`,
whole-word `GREEN|YELLOW|ORANGE|RED`, `scored 1-5`, `32+`.

| File | Lines |
| --- | --- |
| `skills/codex-challenge/SKILL.md` | 8 |
| `skills/codex-challenge/phases/round-loop.md` | 5 |
| `skills/codex-challenge/phases/report.md` | 5 |
| `GUIDE.md` | 3 |
| `commands/quick-plan.md` | 3 |
| `commands/quick-audit.md` | 2 |
| `agents/plan-scaffolder.md` | 2 |
| `commands/help.md` | 1 |
| `docs/planning-techniques/02-evaluator-optimizer-loop.md` | 1 |
| `docs/planning-techniques/09-multi-category-success-criteria.md` | 1 |

**10 files, 31 lines.** `codex-challenge` is **18 of the 31** — well over half,
concentrated in its convergence loop:

- `round-loop.md:113` — "Score >= 36/40 → GREEN achieved"  (the stop condition)
- `round-loop.md:126` — model escalation triggered by "< 24/40 (RED)"
- `report.md:20,21,25,79` — final score, target, and the per-round trend line

Stripping the score therefore means **redesigning how the loop knows it is
finished and when to escalate models**, not deleting text. Relabelling leaves
the loop intact.

**Correction to an earlier estimate.** A first pass reported 17 files. That
count was inflated by a regex matching `RED` inside the word `REQUIRED`, which
put `stages/stage-2-design.md` at the top of the list with 11 apparent hits.
It has **zero**. The guard was right; the measurement was wrong.

## R5 — The relabel posture is already half-implemented

`commands/quick-plan.md:72` reads:

> Overall score (X/40), reported only — it does not gate anything

That is precisely the sentence the relabel option would add to `quick-audit` and
`codex-challenge`. One of the three scoring tools already says it.

This is evidence for relabel being the smaller, more consistent-with-intent
change: it finishes a pattern already started rather than introducing one.

---

## What this means for the decision

| | Strip | Relabel |
| --- | --- | --- |
| Files touched | 10 | 10 |
| Lines | 31 | ~8 changed, rest kept |
| Redesign required | Yes — `codex-challenge` stop condition and model escalation | No |
| Risk | Medium — a working convergence loop is rebuilt | Low — wording plus a guard |
| Precedent in tree | None | Yes, `quick-plan.md:72` |
| Fixes R2 and R3 | Yes | Yes (independent of the choice) |

R2 and R3 are wrong either way and can be fixed regardless of the decision.

## Files referenced (path-scoped fingerprint set)

```
plugins/toque/GUIDE.md
plugins/toque/agents/plan-auditor.md
plugins/toque/agents/plan-scaffolder.md
plugins/toque/commands/help.md
plugins/toque/commands/quick-audit.md
plugins/toque/commands/quick-plan.md
plugins/toque/docs/planning-techniques/02-evaluator-optimizer-loop.md
plugins/toque/docs/planning-techniques/09-multi-category-success-criteria.md
plugins/toque/skills/codex-challenge/SKILL.md
plugins/toque/skills/codex-challenge/phases/report.md
plugins/toque/skills/codex-challenge/phases/round-loop.md
plugins/toque/skills/plan/stages/stage-2-design.md
tests/layer1-repo.sh
```
