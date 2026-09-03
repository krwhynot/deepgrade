Generate a runbook for "$1".

A runbook is the exact, repeatable procedure for one operational task:
a deploy, a rotation, a backfill, a failover, a recovery. It is the artifact
Stage 4 of `/toque:plan` gates on ("Deployment runbook reviewed by someone
other than the author") and the source for the Deployment sequence in
review.md.

**Step 0: Disambiguate**

If "$1" names a plan (`docs/plans/*-$1/` exists), read its plan.md
## Verification and status.json; the runbook is that plan's deployment
procedure and lives at `docs/plans/{date}-$1/runbook.md`.

Otherwise the runbook is standalone and lives at `docs/runbooks/{slug}.md`.

If "$1" is vague ("the deploy", "rotation"), ask which task:
```
"$1" could be one of several procedures:
  [1] {candidate from scripts/, CI config, or existing runbooks}
  [2] {candidate}
  [3] Something else — describe it
```

Wait for the developer's choice.

**Step 1: Gather the real commands**

Read the files that already encode the procedure: deploy scripts, CI
workflows, Makefiles, migration tooling, infra config. Every step in the
runbook must be an exact command or click path lifted from or verified
against those files. If a step cannot be verified, write it and tag it
`[ASSUMPTION]` rather than guessing silently.

Check for an existing runbook at the target path. If one exists, update it
in place and append a History row instead of overwriting.

**Step 2: Generate**

~~~markdown
# Runbook: {Task Name}

**Owner:** {person or role} · **Frequency:** Daily / Weekly / Monthly / Per release / As needed
**Last Updated:** {YYYY-MM-DD} · **Last Run:** {YYYY-MM-DD or "never"}
**Plan:** {plan name or "standalone"}
**Blast radius:** {what this touches: services, data, users}

## Purpose

{What this accomplishes and when to run it. One paragraph.}

## Prerequisites

- [ ] {access or permission needed, e.g. prod deploy role}
- [ ] {tool or version required, e.g. `node >= 18`, CLI logged in}
- [ ] {input or state needed, e.g. release tag exists, backup taken}
- [ ] {who must be reachable during the run}

## Procedure

### Step 1: {Name}

```bash
{exact command, run from where, with real flags}
```

**Expected result:** {what healthy output looks like, verbatim if possible}
**If it fails:** {stop / retry once / roll back to Step N / escalate}

### Step 2: {Name}

```bash
{exact command}
```

**Expected result:** {healthy output}
**If it fails:** {what to do}

## Verification

- [ ] {command or URL and the healthy response}
- [ ] {metric to check and its acceptable range}
- [ ] {key user flow to exercise by hand}

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| {what you see} | {why} | {what to do, with the command} |

## Rollback

**Trigger:** {observable condition that means roll back now}

1. {exact step}
2. {exact step}
3. Verify: {command and healthy output}

## Escalation

| Situation | Contact | Method |
|-----------|---------|--------|
| {condition} | {person or role} | {channel and expected response time} |

## History

| Date | Run by | Duration | Notes |
|------|--------|----------|-------|
| {YYYY-MM-DD} | {person} | {minutes} | {issues, deviations, observations} |
~~~

**Writing rules**

- Be painfully specific. "Run the script" is not a step. "Run
  `python sync.py --prod --dry-run` from the ops box as the deploy user" is.
- Every step has an expected result and a failure action. A step with no
  failure action is a step nobody has thought about failing.
- Rollback trigger is an observable, not a feeling: an error rate, a failed
  health check, a missing row count.
- The runbook is tested by someone who did not write it. Where they stall,
  the runbook is wrong, not the reader.

**Step 3: Post-Generation**

```
Runbook created: {path}

Next steps:
  - Have someone other than the author walk it once (dry-run flags where they exist)
  - If plan-linked: reference it from review.md ## Release checklist and add a
    manifest.md row
  - Record the first real run in ## History
```

If plan-linked, update manifest.md Project Documents and status.json documents.
