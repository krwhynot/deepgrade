# Multi-Category Success Criteria

## What It Is

Multi-Category Success Criteria is a technique that splits plan verification into two explicit tiers: **Automated Verification** (machine-runnable commands and checks) and **Manual Verification** (human testing that cannot be automated).

This distinction is critical because mixing them creates ambiguity about what a CI pipeline can enforce vs what requires human judgment. When success criteria are a flat list, teams either skip the manual items (because they look like the automated ones that already passed) or waste time trying to automate things that inherently need human evaluation (UX quality, real-world performance, edge case behavior). The two-tier structure makes each criterion's verification method explicit.

## Enterprise Origin

**Source: BAML (Boundary ML) Implementation Plan framework** which enforces:

> "Always maintain the two-category structure:
> 1. Automated Verification (can be run by execution agents): Commands that can be run like `make test`, `npm run lint`, specific files that should exist, code compilation/type checking.
> 2. Manual Verification (requires human testing): UI/UX functionality, performance under real conditions, edge cases that are hard to automate, user acceptance criteria."

The pattern also appears in the **BAML implement_plan verification approach**:

> "Pause for human verification: After completing all automated verification for a phase, pause and inform the human that the phase is ready for manual testing."

Additional enterprise origins:

- **Enterprise QA practices** that distinguish between regression test suites (automated, run in CI) and User Acceptance Testing (UAT, human-driven, before release sign-off).
- **ISO/IEC/IEEE 29119 Software Testing standard** which categorizes test levels and techniques by automation capability.

## How It Works

1. During **Phase 4 (Plan)** and **Phase 8 (Test)**, split every success criterion into one of two categories:

   **Automated Verification:**
   - Must be a runnable command: `make test`, `npm run lint`, `pytest tests/`, etc.
   - Must have a binary pass/fail result (not subjective)
   - Can check: compilation, type safety, test pass/fail, file existence, linting, coverage thresholds
   - Runs in CI pipeline without human intervention
   - Examples: "All unit tests pass", "TypeScript compiles with no errors", "Coverage >= 80%", "No ESLint errors"

   **Manual Verification:**
   - Requires human observation or judgment
   - Cannot be fully expressed as a command
   - Can check: UX quality, visual appearance, real-world performance, edge case behavior, business logic correctness in context
   - Requires a specific human tester and acceptance date
   - Examples: "Login flow feels responsive on mobile", "Receipt layout matches mockup", "Error messages are helpful to non-technical users"

2. After automated verification passes, the system **PAUSES** and presents manual items as a checklist.

3. Manual items cannot be auto-checked-off -- a human must confirm each one.

4. Both categories must pass before the phase gate clears.

5. Format for presenting the manual pause:

   ```
   Phase [N] Complete - Ready for Manual Verification

   Automated verification passed:
   - [List automated checks that passed]

   Please perform the manual verification steps:
   - [ ] [Manual item 1]
   - [ ] [Manual item 2]

   Let me know when manual testing is complete.
   ```

## Why It Prevents Gaps

- **Prevents "all tests pass" false confidence** -- tests only cover automated criteria. A green CI build says nothing about manual criteria.
- **Prevents skipping manual checks** because they look like automated ones that already passed.
- **Forces explicit identification of what CANNOT be automated** -- acknowledges automation limits rather than pretending everything is testable by machine.
- **Creates a natural "pause point"** for human quality judgment before proceeding to the next phase.
- **Prevents automation theater** -- writing automated checks for inherently subjective criteria (e.g., a "test" that always passes for "UX feels good").
- **Makes CI pipeline requirements crystal clear** -- only automated items go in CI, no ambiguity.
- **Ensures human testers know exactly what they need to verify** -- not "just check it looks good" but a specific checklist of items requiring judgment.
- **Tracks which category each criterion belongs to**, enabling metrics: "75% automated, 25% manual" -- useful for automation investment decisions.

## Status Before Implementation

Our Phase 8 (Test) readiness gate has a flat checklist:

- "All critical path tests pass"
- "No open P0/P1 defects"
- "Characterization baseline captured"
- "Audit score is GREEN or YELLOW"
- "Rollback plan validated"

These mix automated and manual criteria without distinction. "All critical path tests pass" is automated. "Rollback plan validated" could be either (tested in staging = automated, reviewed by ops = manual). There is no pause between automated and manual verification, and no explicit protocol for human testing sign-off.

## Implementation (Completed)

- **Add category field** to every success criterion in Phase 4 plan and Phase 8 test plan:
  ```json
  {
    "criterion": "All unit tests pass",
    "category": "automated",
    "command": "npm test"
  }
  ```
  ```json
  {
    "criterion": "Receipt layout matches mockup",
    "category": "manual",
    "tester": "QA Lead"
  }
  ```

- **In Phase 8:** run all automated criteria first, report results, then PAUSE for manual verification.

- **Use the BAML pause format:** present automated results, list manual items as unchecked boxes, wait for human confirmation.

- **Do NOT allow manual items to be auto-checked** -- even if the agent thinks they pass. Manual means manual.

- **Add to status.json:**
  ```json
  {
    "success_criteria": {
      "automated": { "total": 12, "passed": 12, "failed": 0 },
      "manual": { "total": 4, "verified": 2, "pending": 2 }
    }
  }
  ```

- **Add to plan template:** separate Automated and Manual sections in Go/No-Go Criteria.

- **Track manual verification with:** tester name, date, pass/fail, notes.

## References

- BAML iterate_plan command, Success Criteria Guidelines (github.com/boundaryml/baml/blob/canary/baml_language/.claude/commands/cl/iterate_plan.md)
- BAML implement_plan, Verification Approach (github.com/boundaryml/baml/blob/canary/baml_language/.claude/commands/cl/implement_plan.md)
- ISO/IEC/IEEE 29119 Software Testing standard
- Enterprise UAT (User Acceptance Testing) best practices
