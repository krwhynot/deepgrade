# The plan workflow

`/toque:plan` in depth — the six stages, what each one commits, and what it
takes to get past each gate.

This is the longest page in the documentation because it is the feature with the
most in it. If you want the short version first, read [When to use
Toque](./when-to-use.md#toque) — it includes the cases where this
workflow is the wrong tool.

---

## The core idea

Six stages take any starting input — a vague idea, a docs folder, a ticket, an
incident — and leave **one committed artifact behind at each stage**. The chain
of artifacts is the audit trail: who asked, what was produced, who approved.

```
  idea / ticket / incident
          |
    +-----v------+  intent.md          gate: a named product owner accepts
    | 1 PLAN     |------------------->
    +-----+------+
    +-----v------+  spec.md, audit.md  gate: scope lock, then the design gate
    | 2 DESIGN   |------------------->       (canary + evidence, PASS/NOT PASS)
    +-----+------+
    +-----v------+  plan.md, code      gate: plan.md approved BEFORE code,
    | 3 BUILD    |------------------->       then impact review confirmed
    +-----+------+
    +-----v------+  test-plan.md       gate: Tier 1 automated pass AND
    | 4 TEST     |------------------->       Tier 2 manual human-confirmed
    +-----+------+
    +-----v------+  review.md          gate: a NAMED human authorizes release
    | 5 DEPLOY   |------------------->       (the agent never deploys)
    +-----+------+
    +-----v------+  new intent.md      no gate. Never completes.
    | 6 MAINTAIN |------------------->
    +------------+
```

Each stage **reads the previous artifact and commits its own**. The agent does
the generating, verifying, and mechanical work. Humans keep the judgment calls.

### Four hard rules, in every stage

1. Human gates are real gates. The workflow never advances past one without a
   recorded approval.
2. Nothing is implemented without an approved `plan.md`. When implementation
   departs from it, `plan.md` is updated in the same commit.
3. The agent verifies its own work before asking a human to review it.
4. The agent never crosses the production gate. It prepares the release, then
   stops and asks.

### A gate without a name is not passed

Every gate records *who*. `accepted_by`, `approved_by`, `authorized_by`, each
with a date. This is enforced, not encouraged — if the approver is not named,
the stage does not advance.

---

## Starting and resuming

```
/toque:plan {name}                 start a new plan, or resume one by that name
/toque:plan intent {name}          Stage 1 only, then stop
/toque:plan {name} from docs/...   start from source material
```

**Intent-only mode** exists so a non-engineer can originate a plan without
committing anyone to building it. It runs Stage 1, commits `intent.md`, asks for
acceptance, and stops — even if acceptance is given in the same session. Someone
resumes with `/toque:plan {name}` when design should begin.

**Resume** reads `status.json`, finds the current stage, checks the freshness of
every completed stage, and reports staleness before offering to continue. See
[The plan workspace](./plan-workspace.md) for the resume and staleness rules.

---

## Stage 1 — Plan

> **Question:** What problem are we solving, and what is true about our situation?
> **Produces:** `intent.md`, `research/findings.md`, `research/reference-data.json`
> **Gate:** a named product owner sets `intent.md` Status to Accepted

### The intent interview

The originator may be a non-engineer, so the interview asks **one question at a
time, in plain language**, and accepts short answers. It deliberately does not
ask about file paths, architecture, or technology — those belong to Stage 2.

Six questions, each mapping to one section of `intent.md`:

| Question | Section |
| --- | --- |
| What cannot be done today, and why does it matter? | Problem |
| What should be true when this is done? How would you know? | Proposed outcome |
| Who is affected, which systems does this touch, who owns the decision? | Affected users and systems |
| What is fixed — deadline, budget, compliance, security, compatibility? | Constraints |
| What should this explicitly NOT cover? | Out of scope |
| What do you not know yet that would change the answer? | Open questions |

Given source docs or an existing ticket instead, it drafts every section from
the material first and then confirms each one with you, rather than making you
retype what it can already read.

### Research — three parallel tracks

The three tracks are independent, so they run as **simultaneous subagents**,
each with its own context window, each writing to the plan folder.

| Track | Objective | Output |
| --- | --- | --- |
| 1 — Codebase scan | Find all related code that already exists | `research/codebase-scan.md` |
| 2 — Source doc cleanup | Clean and structure any provided documents | `research/intake/` |
| 3 — Best practices | Find how others solved this | `research/best-practices.md` |

Track 3 uses connected MCP search tools in a defined order — Ref for framework
docs, Exa for code examples, Perplexity for targeted questions, then plain web
search as a fallback. **With no external search tools available**, it falls back
to codebase-only research and tags the output `[EXTERNAL RESEARCH UNAVAILABLE]`
rather than quietly producing thinner findings.

Research is done when every open question is answered or explicitly deferred, at
least one viable implementation path exists, top risks have mitigation ideas,
and the remaining unknowns are non-blocking.

### Synthesis

Research does **not** change the Problem or Proposed outcome — those belong to
the originator. It updates exactly two sections:

- **Constraints** gains anything research discovered that the originator did not
  name, each marked `(from research)`.
- **Open questions** has each question replaced by its answer and the finding
  behind it, or marked `Deferred to design: {reason}`.

### The gate

A named person accepts, requests changes, or rejects. The originator may accept
their own intent if they own the decision; otherwise the workflow asks who does.

> An intent nobody has accepted is a draft, and Stage 2 must not start from a
> draft — an unaccepted intent produces a spec for a problem no one agreed
> exists.

---

## Stage 2 — Design

> **Question:** What exactly will be built, and does the spec hold up?
> **Produces:** `spec.md`, `audit.md`, `evidence/`
> **Gate:** scope lock, then the design gate PASS, then human review

The largest stage, in three parts.

### Part A — scope and design

Writes the first half of `spec.md`: Requirements (functional and
non-functional), Design, Standards applied, Gotchas, Evidence, Open questions.

Every open question from `intent.md` is carried forward with its current state —
answered, or deferred with an owner and a due date. **A question with no owner
is a gap the design gate will find.**

### Scope lock — a mid-stage gate

Before any of the delivery detail is written, the drafted sections are presented
for confirmation:

```
Does this scope look right? [confirm / adjust / back to research]
```

On confirm, `spec.md` is committed and **the locked sections become immutable**.
Changes after this point require a Change Record, not a silent edit. This is the
mechanism that makes drift visible later.

### Part B — verification plan and delivery

The verification plan requires picking a **testing methodology per deliverable**,
explicitly rather than defaulting to "unit tests for everything." Eleven are on
the menu:

| Methodology | When |
| --- | --- |
| TDD | New feature with a clear spec, algorithms, core business logic |
| BDD | User-facing features, cross-functional teams, ambiguous requirements |
| Characterization / Golden Master | Refactoring legacy code, extracting from a monolith |
| Contract testing | Microservices, API integrations, DB backward compatibility |
| Property-based | Algorithms with infinite input space, financial calculations |
| Snapshot / Approval | UI components, serialized output, reports, config generation |
| Shadow / Parallel | Production migration, database cutover, replacing live systems |
| ATDD | Sprint planning, user-story definition, migration sign-off |
| Mutation testing | Pre-release quality gate, measuring suite effectiveness |
| Exploratory | Complex UI, late-stage discovery, automation gaps |
| Expand/Contract | Schema migration, renaming columns, changing data types |

Three AI-specific rules apply here, and they are the interesting part:

- **Separate test authorship** — the agent that writes implementation code must
  not write the tests for it.
- AI-generated code receives **higher** testing scrutiny than human code.
- Every AI-generated deliverable is checked against an AI failure-mode
  checklist: logic drift, stale dependencies, hidden business-rule violations,
  tautological tests, happy-path-only coverage.

The Delivery section is then written in **three views of the same plan** —
Jira-ready tickets, a leadership summary with a timeline and go/no-go criteria,
and a working checklist with verification per step. Detail scales with risk:
HIGH-risk phases get exact files, function names, and grep patterns; LOW-risk
phases get goals and success criteria.

### Part C — the design gate

The audit. A fresh, isolated `plan-auditor` runs against `spec.md`, and two
tools decide whether its verdict counts:

```
PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

No weighted sum, no partial credit. This is the most opinionated mechanism in
the toolkit and it has [its own page](./the-design-gate.md), including its known
limitation.

---

## Stage 3 — Build

> **Question:** What exactly will change, in what order, and what else does it affect?
> **Produces:** `plan.md`, `changes/CR-{N}.md`, `impact-review.md`, code
> **Gate:** `plan.md` approved before any code; impact review confirmed

### Step 1 — the build plan

`plan.md` names the files that change, the order of work, risks, proof,
verification, and what can be parallelized. **It is approved before any
implementation begins.**

### Step 2 — the assumption hard gate

Before any build work starts, assumptions recorded in `status.json` are checked
by impact:

| Impact | Status | Result |
| --- | --- | --- |
| HIGH | unverified | **BLOCK.** Verify now / accept risk with a waiver / back to research |
| HIGH | falsified | **BLOCK** and return to Stage 2 — the approach is invalid |
| HIGH | verified or waived | Pass |
| MEDIUM | unverified | Warn, allow |
| LOW | unverified | Note only |

A waiver is not a shrug: it requires a documented risk statement, an approver's
name, and a contingency plan if the assumption fails.

> This gate is not advisory. It is a hard block.

### Change control

Three situations produce an immutable Change Record in `changes/`:

- **Scope change** — offers a return to Stage 2, marks design and build stale,
  and preserves the original `spec.md`.
- **New blocker** — the ticket is marked BLOCKED with the reason and impact.
- **Implementation diverges from plan** — the divergence and its rationale are
  recorded, and `plan.md` is updated **in the same commit**. This is the living
  document rule, and it replaces informal change notes.

There is no gate on build work itself. You stay in Build until you are ready for
the exit check.

### Step 3 — impact review

The exit check, and the reason the stage does not simply end when the code
works. Code that passes targeted tests can still break integration edges, scale
behavior, transition-state UX, and downstream consumers. This step asks "what
did we miss?" across seven dimensions, run as parallel subagents.

HIGH-severity findings force a choice: fix now (return to Step 2, update
`plan.md` in the same commit, re-run the affected dimension) or accept the risk
with a recorded reason.

---

## Stage 4 — Test

> **Question:** Does it work safely?
> **Produces:** `test-plan.md`, results
> **Gate:** all Tier 1 automated checks pass AND all Tier 2 manual checks confirmed by a human

`test-plan.md` gets a per-phase test matrix, edge cases, characterization
candidates, and each criterion categorized as automated or manual.

The methodology chosen back in Stage 2 now drives an explicit checklist. The
database migration path is the longest — **eighteen steps** across Expand,
Migrate, and Contract phases, covering forward and backward migrations, dual
writes, row counts, checksums, referential integrity, shadow comparison, orphan
references, index regressions, and query performance.

### Two-tier verification

**Tier 1 runs without you.** Critical-path tests, a clean compile, no lint
errors in changed files, characterization baselines captured, the design gate
recorded as PASS, and every verification command from `plan.md` producing its
healthy output.

Then it **stops** and hands you Tier 2.

**Tier 2 requires a human** and is never auto-checked: no open P0/P1 defects,
rollback plan validated in staging or reviewed by ops, key user flows working in
staging, edge cases manually verified, and the deployment runbook reviewed **by
someone other than its author**.

The gate needs all of Tier 1 passing, all of Tier 2 confirmed, and nothing left
pending. Who confirmed and when is recorded.

---

## Stage 5 — Deploy

> **Question:** Is this the change the plan intended, and who authorizes it?
> **Produces:** `review.md`, `plan.md ## Departures from plan`
> **Gate:** a named human authorizes. The agent never runs a deploy command.

### Step A — diff-versus-plan

The drift control, and the design detail worth noticing: it runs in a **fresh
subagent, not the one that did the build**, so the comparison is not biased by
memory of why each file changed. Its brief is explicitly *report, do not judge*.

It produces three lists — files changed but not planned, files planned but not
changed, and matches — then checks every constraint from `intent.md` against the
diff for auth changes, data-scope changes, and new external dependencies, citing
`file:line` for anything that *appears* to violate one.

"Appears" is deliberate. The subagent supplies evidence; the human decides.

A non-empty delta is **not** an automatic rejection, but it must be
acknowledged: every unplanned and untouched file is appended to `plan.md` under
`## Departures from plan` with a one-line reason each, or marked "unexplained" —
and an unexplained departure becomes a finding. That append lands in the same
commit as the release candidate.

> Drift that is not written down is drift that did not get reviewed.

### Step B — review.md

Evidence before opinions, in a fixed order: summary, diff-versus-plan, the
constraint check, findings (each citing `file:line`, ordered by severity, at
most five nits with the rest summarized as a count), and the release checklist.

Rollback triggers in that checklist must be **numeric thresholds over a window**
— an error rate, a latency figure, a failing smoke test, a data-integrity count.
"Looks wrong" is explicitly not a trigger. Those same thresholds are what Stage 6
later uses to classify incident severity.

### Step C — authorization

```
Two questions for the reviewer:
  1. Is this the change the plan intended?
  2. Is the risk acceptable?
```

The hard rule: **no deploy, publish, release, tag-push, merge-to-production, or
migration command is run by this skill, in any approval tier, even if you say
"just do it" in passing.** A deliberate release is a human action.

Once authorized, the human performs the release from the checklist. The agent
may run the *verification* steps after the human confirms each deployment step —
never the deployment steps themselves.

---

## Stage 6 — Maintain

> **Question:** What did production teach us?
> **Produces:** new `intent.md` files when the trigger fires
> **Gate:** none. This stage never completes.

After release the plan folder is the record. **Nothing in it is rewritten after
Stage 5** — new facts go in new files.

Incidents are handled by `/toque:troubleshoot --plan {name}`, which writes its
log inside the plan's `troubleshooting/` folder. Stage 6 reads those logs; it
does not investigate.

### The trigger rule

When a logged incident is **either** SEV1/SEV2 **or** a recurrence of a known
pattern (recurrence count of 2 or more), a new `intent.md` is drafted, pre-filled
from the incident — root cause becomes Problem, the recommended fix becomes
Proposed outcome, every unverified hypothesis becomes an Open question.

Then it stops. The new intent re-enters Stage 1 for a human to accept or reject.
**It is never auto-accepted, and this stage never edits code.**

Incidents below the trigger are linked and counted only.

### Steady state

There is no completion timestamp. `/toque:plan-status` reports Maintain with its
metrics — incidents linked, intents proposed, repeat incidents in the same class.

> "Done" is observed, not declared.

---

## Approval tiers

Four tiers govern what happens without asking:

| Tier | Examples | Approval |
| --- | --- | --- |
| 1 — Read-only | grep, read files, search | None |
| 2 — Document write | anything under `docs/plans/{date}-{name}/` | None |
| 3 — Codebase write | test files, scaffolds, generated code | **Required** |
| 4 — Side-effect commands | git operations, package installs, builds | **Required** |

Release to production is not a tier. The skill never runs it.

---

## Where parallelism is used

| Stage | Parallelized | Deliberately sequential |
| --- | --- | --- |
| 1 Plan | 3 research tracks | The intent interview — it is a conversation |
| 2 Design | 5 audit specialists | Scope lock and spec authoring |
| 3 Build | Independent tickets; 3 impact-review groups | — |
| 4 Test | — | Tests may have execution-order dependencies |
| 5 Deploy | Diff check in its own fresh subagent | — |
| 6 Maintain | — | Triage is a human decision |

The rule of thumb: 1–2 independent tasks run inline, 3 or more go parallel, 5 or
more get batched into groups. Every subagent has a functional name, a defined
scope, and a visible report — **no silent background work**.

---

## Related

- [The plan workspace](./plan-workspace.md) — the folder, `status.json`, resume, staleness
- [The design gate](./the-design-gate.md) — Stage 2's gate in full
- [When to use Toque](./when-to-use.md#toque) — including when not to
