# Intake: coherence findings from the 2026-09-03 session

Source: working session, 2026-09-03, after the 10.0.0 rename shipped. Every
claim below was read from the file cited, not inferred.

## F1 — Two tools score plans; the design gate abolished scoring

8.0.0 removed numeric scoring from the design gate. The gate is four booleans:

```
PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

`plugins/toque/agents/plan-auditor.md:60` keeps the 8 dimensions but only as
"lenses for finding" — no score, no bands, no totals.

A guard enforces the removal: `tests/layer1-repo.sh` PH5-051 fails if
`score_history`, `/40`, or `N-N = GREEN|YELLOW|ORANGE|RED` appears in any of
`plugins/toque/skills/plan/SKILL.md`, `plugins/toque/skills/plan/stages/*.md`,
or `plugins/toque/agents/plan-auditor.md`.

That file list is the hole. Two tools that also audit plans sit outside it and
still score:

| File | Line | What it does |
| --- | --- | --- |
| `plugins/toque/commands/quick-audit.md` | 59 | "Overall score (X/40) with color (Green/Yellow/Orange/Red)" |
| `plugins/toque/commands/quick-audit.md` | 60 | "The scorecard table (8 dimensions)" |
| `plugins/toque/skills/codex-challenge/SKILL.md` | 27 | Targets **36/40** |
| `plugins/toque/skills/codex-challenge/SKILL.md` | 28 | Bands: "GREEN: 32-40 (plan is solid)" |
| `plugins/toque/skills/codex-challenge/SKILL.md` | 125 | "Each dimension is scored 1-5 by Codex" |

Net effect: the same plan can return a boolean PASS from the centerpiece and a
numeric 34/40 Yellow from the tool beside it.

## F2 — Two citations are now factually stale

Both name a rubric that 8.0.0 deleted:

- `plugins/toque/skills/codex-challenge/SKILL.md:27` — 36/40 described as "upper
  GREEN threshold from Toque's plan-auditor rubric".
- `plugins/toque/commands/quick-plan.md:2` — output "scores well on the plan
  auditor's 8 dimensions".

The dimensions survive as lenses; the scoring rubric does not. These are wrong
regardless of what is decided about F1.

## F3 — `quick-plan` has no promotion path

`plugins/toque/commands/quick-plan.md:9-13`:

```
1. Write spec to docs/specs/{name}.md
2. If docs/plans/*-{name}/ exists: update its manifest.md and status.json
3. If docs/plans/*-{name}/ does NOT exist: do NOT create a plan folder.
   ... If the user wants a full plan folder, use /toque:plan.
```

So "this quick plan turned out to matter, make it real" means starting over.
The artifact lands outside the plan workspace and Stage 1 cannot consume it.

## F4 — `quick-cleanup` is the counter-example, not a problem

Checked on the hypothesis that it duplicated Stage 1's document-intake track.
It does not. `plugins/toque/commands/quick-cleanup.md:7-25` creates a plan
homebase automatically, writes into `research/intake/`, and initialises both
`manifest.md` and `status.json`. It is the best-integrated side tool and the
model `quick-plan` should follow.

## F5 — `codex-challenge` is the only external dependency

Requires the OpenAI Codex CLI on `PATH`. Every other command needs only Claude
Code, plus Node 18+ for the hooks and gate tools.

## Inventory the findings apply to

After the readiness and audit plugins are split out, `toque` retains 10 command
surfaces, 6 skills, 2 agents, 5 scripts, 3 hooks.

| Surface | Serves the centerpiece? |
| --- | --- |
| `/toque:plan` | is the centerpiece |
| `/toque:plan-status`, `/toque:plan-export` | yes, directly |
| `/toque:troubleshoot` | yes — feeds Stage 6 via `--plan` |
| `/toque:quick-cleanup` | yes — creates the homebase (F4) |
| `/toque:documentation` | partly — Stage 2 ADRs, Stage 5 runbooks, plus standalone use |
| `/toque:quick-plan` | weakly — orphaned output (F3), stale citation (F2) |
| `/toque:quick-audit` | conflicts — scoring model the gate rejected (F1) |
| `/toque:codex-challenge` | conflicts — scoring (F1), stale citation (F2), external dep (F5) |
| `/toque:help` | neutral |
