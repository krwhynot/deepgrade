# 4-Phase Methodology — Expanded

This document expands on the condensed Phase 1–4 descriptions in SKILL.md
with signals, gotchas, evidence patterns, and decision points for each phase.

## Phase 1: Locate

The goal of Phase 1 is to answer two questions: WHAT happened and WHERE in
the code? You exit Phase 1 when you can name the specific file and function
where the issue manifests, and ideally reproduce the symptom.

### Step 1.1: Categorize the Bug

Different bug categories need different investigation approaches.

| Category | Signals | First Check |
|----------|---------|-------------|
| Logic          | Wrong output, wrong behavior in defined cases | Read the function and trace the logic |
| Boundary       | Works most of the time, fails on edge cases (empty, null, max, min) | Check input ranges, null handling, empty collections |
| Error Handling | Crashes, unhandled exception, error swallowed | Read catch/finally blocks; check error propagation |
| Data Flow      | Data is wrong somewhere downstream from a correct source | Trace from source to where the data turns wrong |
| Integration    | Works in isolation, fails when combined with other components | Inspect the boundaries between components (API, DB, file IO) |
| Timing         | Intermittent, works then doesn't, race-condition-like | Check async, shared mutable state, order assumptions |

Tell the user: "This looks like a {category} issue. Here's my approach..."

### Step 1.2: Check Recent Changes (ALWAYS do this first)

The single highest-leverage diagnostic step. Most bugs are introduced by
recent changes.

```
git log --oneline -10
git diff --name-only HEAD~3
git status --short
```

"These files changed recently: {list}. The bug may be in one of these changes."

### Step 1.3: Reproduce the Issue

A reproducible bug is a solvable bug. An intermittent bug is a hypothesis
about timing, shared state, or environment differences.

Ask: "Can you reproduce this consistently? What are the exact steps?"

- Yes → Capture the repro steps. Use them as your acceptance test.
- No → Likely timing-related. Look for: async without await, shared mutable
       state, order-dependent initialization, environment-specific values
       (locale, timezone, feature flags), background jobs.

### Step 1.4: Read the Actual Code

Do not guess from descriptions. Open the files. Trace the flow with your eyes.

```
grep -rn "{error-or-function}" --include="*.{ext}" .
```

Read the files. Understand the data flow. Note what you see — not what you
expect to see.

### Step 1.5: Gather Evidence

For multi-component issues, trace data across boundaries:

- What goes IN to the function?
- What comes OUT?
- Where does the data transform from correct to incorrect?

Exit Phase 1 with: "Phase 1 complete. The issue is in {file}:{function}.
The data is correct at {point A} but wrong at {point B}."

### Phase 1 Gotchas

- **The reported symptom and the actual location can be different services.**
  A user reports "search is slow," but the actual bottleneck is the shared
  database connection pool — search is just where the symptom shows up first.
  Consider blast-radius extension (resources/techniques/03) for distributed work.
- **Recent-changes bias.** Just because a file was touched recently doesn't
  mean THAT change is the cause. Verify with bisect for regressions.
- **The intermittent trap.** "It works on my machine" usually means
  environment difference (locale, config, data state, feature flag).

## Phase 2: Investigate

The goal of Phase 2 is to find the difference between working code and broken
code. You exit Phase 2 when you can articulate what assumption breaks.

### Step 2.1: Find Working Examples

Find a similar-shaped piece of code that works correctly. The broken code
deviates from the working pattern in some way — that deviation is the
investigation target.

```
grep -rn "{similar-pattern}" .
```

### Step 2.2: Compare Working vs Broken

State the difference precisely: "Working code does {X}. Broken code does {Y}.
The difference is {Z}."

### Step 2.3: Check Dependencies and Assumptions

What does the broken code ASSUME that might not be true?

- Does it assume data exists? (null check missing)
- Does it assume order? (async timing, initialization order)
- Does it assume format? (string vs number, ISO date vs Unix timestamp)
- Does it assume config? (environment-specific, feature flag enabled)
- Does it assume scale? (works on small inputs, fails on large)
- Does it assume identity? (caller has permission, tenant matches)

Exit Phase 2 with: "Phase 2 complete. The broken code assumes {assumption}
which is not true when {condition}. The working code handles this by {how}."

### Phase 2 Gotchas

- **Cargo-culting the working code.** "Let me make the broken code look more
  like the working code" is a shortcut, not a fix. You still need to know WHY
  the deviation exists.
- **Misidentifying the working example.** A function that LOOKS similar may
  not actually handle the same case. Verify the working example handles the
  edge case you're investigating.

## Phase 3: Hypothesize

The goal of Phase 3 is to form ONE specific, testable hypothesis tied to
evidence from Phases 1 and 2.

### Step 3.1: Form ONE Hypothesis

"Based on the evidence: the bug is caused by {specific cause} because
{evidence from THIS codebase}."

The hypothesis MUST:
- Be specific (not "something is wrong with the data")
- Be testable (we can verify with a specific check)
- Reference evidence from Phase 1 and 2 (not general patterns)

### Step 3.2: Five Whys (for stubborn bugs)

If the first hypothesis doesn't hold, drill deeper. Each "why" turns a
symptom into a cause until the systemic root emerges.

Example:
1. Why did checkout fail? → The receipt string was null.
2. Why was it null? → The localization lookup returned no result.
3. Why no result? → The key was French but the table only has English keys.
4. Why English-only? → The migration only loaded the English resource file.
5. Why only English? → The French file wasn't included in the build config.

ROOT CAUSE: French resource file missing from build configuration. The bug
manifests at checkout but lives in build config.

### Step 3.3: Test Minimally

Change ONE variable at a time. Never bundle changes. The point of minimal
testing is to keep the signal clean — if you change three things and the bug
disappears, you don't know which fix worked.

- Confirmed: "Root cause confirmed: {cause}. Ready to fix."
- Disproved: "That wasn't it. Log the dead end. New hypothesis based on what we learned."

### Phase 3 Gotchas

- **Stopping at the first plausible explanation.** A plausible cause is not a
  proven cause. Always verify with a minimal test before proceeding to fix.
- **Bundled hypothesis testing.** "Let me try this AND that AND see what
  happens" loses the signal. Test ONE thing at a time.
- **Skipping Five Whys when you should use it.** The first cause is often the
  trigger, not the root. Drill until the systemic cause emerges.

## Phase 4: Fix

The goal of Phase 4 is to apply the minimal change that addresses the root
cause, verify it works, and verify it doesn't break anything else.

### Step 4.1: Failing Test First

Write a test that fails BEFORE applying the fix. The test should:
- Set up conditions that trigger the bug
- Call the function that fails
- Assert the CORRECT behavior (which currently fails)

This locks in your understanding of the bug and provides a regression
guard for the future.

### Step 4.2: Implement Focused Fix

The fix should be:
- Single, focused change (NOT a refactor)
- As small as possible
- Directly addressing the root cause, not the symptom

"Here's the fix: {description}. Apply it? [Y/n]"

### Step 4.3: Verify

- The failing test now passes
- The full test suite has no regressions
- The symptom is gone in the original reproduction steps

### Step 4.4: Git Bisect (for regressions)

If the bug previously worked, `git bisect` finds the introducing commit:

```
git bisect start HEAD {last-known-good-commit}
git bisect run {test-command}
git bisect log
```

This adds confidence: the bisect-identified commit should match the suspect
you investigated. If it doesn't, your hypothesis was wrong and you have new
evidence.

### Phase 4 Gotchas

- **Fixing the symptom instead of the root cause.** Catching a null and
  returning early "fixes" the crash but the data is still wrong upstream.
  Ask: would my fix make the bug disappear without making the system correct?
- **Refactor scope creep.** "While I'm here let me clean up this function"
  adds risk to the fix. Keep the change scope tight. Refactor in a separate
  change with its own test cycle.
- **Skipping the regression suite.** A fix that passes the failing test but
  breaks three unrelated tests is not a fix.

## Beyond the 4 Phases

For incidents that exceed the standard debugging scope, optional extensions
in `resources/techniques/` add:

- **Severity classification** (01) when triage matters
- **Containment** (02) when service must be restored before investigation
- **Blast radius assessment** (03) when scope is unclear
- **Observability-first** (04) when the project has telemetry
- **Guardrail evaluation** (05) after fix — why didn't tests/CI/lint catch it?
- **Structured postmortem** (06) for SEV1/SEV2 organizational learning
- **Communication protocol** (07) for stakeholder updates during incidents
- **Smart correlation** (08) for matching against past incidents
- **Timeline reconstruction** (09) for backward incident timelines

Engage extensions on demand. Do NOT apply them by default — they add weight
that simple bugs don't need.
