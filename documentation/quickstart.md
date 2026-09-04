# Quickstart

Your first plan, end to end, with what appears on disk at each step.

Assumes `toque` is installed — see [Install](./install.md) — and that you are in
a Claude Code session inside a project.

---

## Start small first

Before running the full six-stage workflow on something that matters, spend ten
minutes on the lightweight commands. They share the same conventions and cost
almost nothing:

```
/toque:quick-plan add rate limiting to the upload endpoint
```

Writes a single plan document to `docs/specs/` — no folder, no stages, no gates.
This is the right answer far more often than the full workflow.

```
/toque:quick-audit docs/specs/upload-rate-limiting.md
```

Audits any plan or spec across eight review dimensions with evidence, and
produces a go/no-go assessment. Point it at a document you already have — it
does not need to be one Toque wrote.

When those feel familiar, the full workflow will make sense.

---

## The full workflow

### 1. Start a plan

```
/toque:plan upload-rate-limiting
```

It suggests a folder name and asks you to confirm:

```
Suggested plan name: upload-rate-limiting
This will create: docs/plans/2026-09-03-upload-rate-limiting/
  [1] Use this name
  [2] Enter a different name
```

On disk:

```
docs/plans/2026-09-03-upload-rate-limiting/
  manifest.md      every row Pending
  status.json      current_phase: "plan"
  research/intake/
  changes/
```

### 2. Answer six questions

Stage 1 interviews you **one question at a time**, in plain language. No file
paths, no architecture — those come later.

It asks what cannot be done today, what should be true when it is done, who is
affected and who owns the decision, what is non-negotiable, what is explicitly
out of scope, and what you do not know yet.

Short answers are fine. Each one becomes a section of `intent.md`.

**Starting from material you already have?** Point it at the source and it
drafts every section first, then confirms each with you:

```
/toque:plan upload-rate-limiting from docs/tickets/PLAT-4471.md
```

### 3. Research runs in parallel

Three independent subagents, each with its own context window: one scans your
codebase for related code, one cleans any source documents you provided, one
looks up how others solved this.

They write into `research/`, then a synthesis pass cross-references all three
and reports in plain language — what exists, what can be reused, what is still
unknown, and which of your open questions got answered.

### 4. Accept the intent

```
intent.md is ready for acceptance. Who is the product owner accepting it?
  [1] Enter the owner's name to accept
  [2] Request changes
  [3] Reject
```

**A name is required.** This is the pattern at every gate — an unnamed approval
is not an approval, and the workflow will not advance without one.

> Only capturing an idea, not committing anyone to build it? Use
> `/toque:plan intent {name}` and it stops right here.

### 5. Design, and the scope lock

Stage 2 writes `spec.md` — requirements, design, standards, gotchas, evidence —
then stops mid-stage and asks:

```
Does this scope look right? [confirm / adjust / back to research]
```

Confirming **locks those sections**. Changing them afterwards requires a Change
Record rather than a silent edit, which is what makes scope drift visible later
instead of invisible.

Then it writes the verification plan — picking a testing methodology per
deliverable from eleven options rather than defaulting to unit tests — and the
delivery plan in three views: Jira-ready tickets, a leadership summary, and a
working checklist.

### 6. The design gate

The part that can tell you no.

An isolated auditor reviews the spec. Before it runs, a **canary** plants one
known defect in a throwaway copy — if the audit misses it twice, the audit is
untrustworthy and does not get to authorize anything. Every piece of evidence
the auditor cites is then re-read from disk and compared byte-for-byte.

```
PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

Four booleans, no partial credit. [Full detail](./the-design-gate.md).

### 7. Onward

Stages 3 through 6 — Build, Test, Deploy, Maintain — follow the same shape:
read the previous artifact, commit a new one, stop at a named human gate. The
[plan workflow page](./the-plan-workflow.md) covers each in depth.

Two things worth knowing before you get there:

- No code is written until `plan.md` is approved, and codebase writes always
  ask.
- The agent **never deploys**. Stage 5 prepares the release and stops.

---

## Checking in later

```
/toque:plan-status
```

Every active plan, its stage, and whether anything has gone stale.

```
/toque:plan upload-rate-limiting
```

Resumes exactly where you left off. It re-checks the freshness of completed
stages first, so if the code moved under a finished stage, you hear about it
before you continue.

---

## Related

- [The plan workflow](./the-plan-workflow.md) — all six stages in depth
- [When to use Toque](./when-to-use.md) — including when not to
