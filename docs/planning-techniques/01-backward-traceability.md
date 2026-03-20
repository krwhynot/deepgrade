# Backward Traceability (Bidirectional RTM)

## What It Is

Standard forward tracing maps goals to tickets to code: you start with what you want to build, break it into work items, and track those work items through implementation. Backward traceability reverses the direction: every code change must trace back to a goal or requirement. If you cannot draw a line from a code change back to a stated objective, that change has no justification.

A **Bidirectional Requirements Traceability Matrix (RTM)** enforces BOTH directions simultaneously. Forward tracing asks "did we build everything we planned?" Backward tracing asks "did we ONLY build what we planned?" The matrix is the artifact that holds both answers.

The rules are simple:
- If a code change doesn't map to any requirement, it's **scope creep**.
- If a requirement has no code change, it's a **gap**.

Both are failures. Both are invisible without bidirectional tracing.

## Enterprise Origin

**Source:** AWS Prescriptive Guidance ADR Process, Jeff Tyree & Art Akerman (Capital One) ADR template, SEI *Software Architecture in Practice*.

The Tyree/Akerman template states: *"You can assess each architecture decision's contribution to meeting each requirement, and then assess how well the requirement is met across all decisions. If a decision doesn't contribute to meeting a requirement, don't make that decision."*

This is not a suggestion. In the Capital One engineering culture where this template was developed, decisions that cannot demonstrate contribution to a requirement are rejected. The AWS ADR process codifies the same principle: every architectural decision record must include explicit mapping of decisions to objectives and deliverables. A decision that serves no objective is not recorded as "low priority" — it is not made at all.

The SEI's *Software Architecture in Practice* extends this into implementation: traceability is not just between decisions and requirements, but between all artifacts in the development lifecycle. Requirements trace to design, design traces to code, code traces to tests, and every link must be traversable in both directions.

## How It Works

### 1. Forward Trace: Goal -> Ticket -> Phase -> Code File -> Test

This is the direction most teams already practice. A product goal ("support bilingual receipts") becomes a ticket (POS-5160), gets assigned to a phase (Phase 3: Core Implementation), results in code changes (src/receipts/bilingual.cs), and is verified by tests (tests/receipts/bilingual.test.cs). The forward trace confirms that planned work resulted in implemented artifacts.

### 2. Backward Trace: Code Change -> Ticket -> Goal (validates every change serves a purpose)

This is the direction most teams skip. For every file modified during a build phase, you ask: what ticket authorized this change? What goal does that ticket serve? If the answer to either question is "none" or "unclear," the change is unjustified. The backward trace confirms that implemented artifacts serve planned goals.

### 3. Orphan Detection: Code changes with no goal = scope creep. Goals with no code = delivery gap.

Orphan detection is the automated output of running both traces. An orphan code change is a file that was modified but cannot be traced to any goal. An orphan goal is a requirement that was stated but has no implementation artifact. Both orphan types represent failures in plan execution, and both are invisible without the bidirectional matrix.

### 4. Matrix Format: Rows are requirements/goals, columns are implementation artifacts. Every cell must be filled or explicitly marked N/A.

The matrix is a table where:
- Each row represents a requirement or goal from the plan
- Each column represents an implementation artifact (code file, config change, test, migration)
- Each cell contains the ticket that links them, or "N/A" with a reason

```
| Requirement / Goal     | src/auth/login.cs | src/receipts/bilingual.cs | tests/receipts/bilingual.test.cs | Status        |
|------------------------|-------------------|---------------------------|----------------------------------|---------------|
| Bilingual receipts     | N/A               | POS-5160                  | POS-5160                         | TRACED        |
| Auth token refresh     | POS-5162          | N/A                       | N/A (test pending)               | PARTIAL GAP   |
| (no goal)              | —                 | —                         | —                                | —             |

| Orphan Artifacts       | Ticket  | Goal    | Status       |
|------------------------|---------|---------|--------------|
| src/reports/summary.cs | (none)  | (none)  | SCOPE CREEP  |
```

If a column (artifact) has no row (goal) that claims it, it's scope creep. If a row (goal) has no column (artifact) that implements it, it's a delivery gap. The matrix makes both visible at a glance.

## Why It Prevents Gaps

- **Catches scope creep**: Work that serves no goal is surfaced immediately. Developers sometimes add "while I'm in here" changes — refactors, formatting fixes, utility functions — that were never planned. These changes introduce risk without serving any objective. Backward tracing flags them.
- **Catches delivery gaps**: Goals with no implementation are surfaced immediately. A goal can be stated in a brainstorm document, accepted during planning, and then silently dropped during build because no one assigned it to a ticket. Forward tracing from the goal would catch this, but only if someone remembers to check. The matrix forces the check.
- **Catches orphan tests**: Tests that verify nothing in the plan are identified. A test file that doesn't trace back to any requirement is either testing scope-creep code (which shouldn't exist) or testing something that was never a goal (which means the test itself is unjustified).
- **Catches phantom dependencies**: Code that changes things no one asked for is flagged. A developer modifying a shared utility to support their feature may inadvertently break other consumers. If that shared utility modification doesn't trace to a ticket, the backward trace catches it before it causes downstream failures.
- **Forces every line of work to justify its existence**: The cultural effect is as important as the mechanical one. When developers know that every change will be traced back to a goal, they stop making unjustified changes. The matrix changes behavior, not just detection.

## Status Before Implementation

Our Coverage Matrix (Audit Output A) only traces forward: goals -> tickets. It answers "does every goal have a plan artifact that covers it?" This is valuable but incomplete.

During Phase 6 Build, developers can write code that doesn't map to any goal, and Phase 7 Impact Review never catches it because it only looks at cross-cutting effects, not goal alignment. The Impact Review asks "does this change affect other systems?" but never asks "was this change authorized by the plan?"

We have no "reverse coverage check." A developer could add an entirely new feature during Build, and as long as it doesn't break anything cross-cutting, our audit pipeline would never flag it. The plan would show 100% forward coverage (all goals implemented) while silently containing 30% unauthorized work.

## Implementation (Completed)

1. **Add a Reverse Coverage Check to Phase 7 Impact Review.** After the existing cross-cutting analysis, add a backward trace step that examines every file changed during Build.

2. **For every file changed during Build, verify it maps to a ticket, and every ticket maps to a goal.** This requires:
   - Extracting the list of changed files from the Build phase (git diff or file manifest)
   - For each file, looking up the ticket that authorized the change (from commit messages or a change log)
   - For each ticket, looking up the goal it serves (from the Coverage Matrix)

3. **Orphan changes (code that serves no goal) get flagged as scope creep.** These are not automatically rejected — sometimes scope creep is justified — but they must be explicitly acknowledged and approved. Silent scope creep is the failure mode.

4. **Add LINT-11: Every code change maps to a plan ticket.** This lint rule runs during Phase 7 and fails if any changed file cannot be traced to a ticket. The developer must either link the change to an existing ticket, create a new ticket (which then needs a goal), or justify the orphan.

5. **Add LINT-12: Every plan ticket maps to at least one code change (or is explicitly deferred).** This lint rule runs during Phase 7 and fails if any ticket in the plan has no corresponding code change. The ticket must either have implementation artifacts or be marked as explicitly deferred with a reason.

## References

- AWS Prescriptive Guidance: ADR Process (docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html)
- Jeff Tyree & Art Akerman, "Architecture Decisions: Demystifying Architecture", Capital One Financial
- SEI, "Documenting Software Architectures: Views and Beyond"
- Joel Parker Henderson, Architecture Decision Record repository (github.com/joelparkerhenderson/architecture-decision-record)
