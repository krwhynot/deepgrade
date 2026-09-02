# Phase 8: TEST

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

## Contents

- Document actions
- Methodology-specific test procedures
- Codebase actions
- Two-tier verification
- Hard readiness gate

Question: Does it work safely?

DOCUMENT ACTIONS (automatic):
Write docs/plans/{date}-{plan-name}/test-plan.md with:
- Per-phase test matrix (test name, type, what it verifies)
- Edge cases prompted by plan context
- Characterization test candidates for changed code
- Each criterion categorized as AUTOMATED or MANUAL (see below)

METHODOLOGY-SPECIFIC TEST PROCEDURES:
Based on the testing methodology assigned in Phase 4, execute the appropriate
test procedure for each deliverable. Reference the full framework at
docs/planning-techniques/10-testing-methodology-selection.md.

IF methodology = expand_contract:
Execute all 18 steps of the database migration test checklist:

  EXPAND PHASE:
  - [ ] Forward migration script runs cleanly on empty DB
  - [ ] Forward migration script runs cleanly on production-like data
  - [ ] New columns/tables exist with correct types and constraints
  - [ ] Old columns/tables are untouched (no dropped columns, no renamed columns)
  - [ ] Old code works against expanded schema (backward compatible)
  - [ ] New code works against expanded schema

  MIGRATE PHASE:
  - [ ] Dual-write triggers or application-level dual-write is active
  - [ ] Backfill of existing data completes without errors
  - [ ] Row counts match pre/post migration
  - [ ] Checksums match pre/post migration (normalize volatile data)
  - [ ] Referential integrity intact (no orphan foreign keys)
  - [ ] Shadow comparison of old vs new query results matches

  CONTRACT PHASE:
  - [ ] Backward (rollback) migration script restores original state
  - [ ] New code works against contracted schema
  - [ ] Old structures removed cleanly (no leftover columns/tables)
  - [ ] No orphan references to removed columns/tables in codebase
  - [ ] Indexes exist on new columns (no missing index regressions)
  - [ ] Query performance within acceptable bounds on new schema

IF methodology = tdd:
  - [ ] Test suite generated from spec BEFORE implementation
  - [ ] All tests fail initially (Red phase verified)
  - [ ] Implementation passes all tests (Green phase)
  - [ ] Refactoring does not break tests

IF methodology = characterization:
  - [ ] Golden master baseline captured BEFORE changes
  - [ ] Post-change output matches baseline (or divergences explicitly approved)
  - [ ] Volatile data normalized before comparison (timestamps, auto-increment IDs)

IF methodology = contract_testing:
  - [ ] Consumer contracts defined
  - [ ] Provider verification passes
  - [ ] Old code + new schema validated against contracts
  - [ ] New code + old schema validated against contracts

IF methodology = shadow_parallel:
  - [ ] Dual-write infrastructure in place
  - [ ] Comparison monitoring active
  - [ ] Divergence rate below threshold before cutover

IF methodology = property_based:
  - [ ] Invariants defined and documented
  - [ ] Input generators cover edge cases
  - [ ] All properties hold under generated inputs

IF methodology = bdd:
  - [ ] Gherkin specs written by humans (product/QA)
  - [ ] Step definitions wired and passing
  - [ ] All Given/When/Then scenarios covered

IF methodology = snapshot_approval:
  - [ ] Snapshots captured and approved by humans
  - [ ] No blind snapshot updates (each change reviewed)

IF methodology = mutation_testing:
  - [ ] Mutation testing tool configured and run
  - [ ] Mutation score above team-calibrated threshold
  - [ ] All surviving mutants reviewed and justified

CODEBASE ACTIONS (approval required):
- "Generate characterization tests for {function}? [Y/n]"
- "Create test stubs for new code? [Y/n]"

TWO-TIER VERIFICATION:
Split all success criteria into two categories. Run automated first,
then pause for manual verification.

TIER 1 — AUTOMATED VERIFICATION (run without human intervention):
- [ ] All critical path tests pass (run test command)
- [ ] TypeScript/code compiles with no errors (run build command)
- [ ] No lint errors in changed files
- [ ] Characterization baseline captured for any refactored code
- [ ] Audit score is GREEN with gap-checked = YES, or YELLOW with gap-checked = YES

Run all Tier 1 checks. Report results. Then PAUSE:

```
Phase 8 — Automated Verification Complete

Automated checks passed:
- [list each Tier 1 check and its result]

Ready for manual verification. Please perform these checks:
- [ ] [Manual item 1]
- [ ] [Manual item 2]

Let me know when manual testing is complete so I can proceed to Handoff.
```

TIER 2 — MANUAL VERIFICATION (requires human testing):
- [ ] No open P0/P1 defects against this plan
- [ ] Rollback plan has been validated (tested in staging or reviewed by ops)
- [ ] Key user flows work as expected in staging/preview
- [ ] Edge cases identified in test-plan.md have been manually verified
- [ ] Deployment runbook reviewed by someone other than the author

Do NOT auto-check Tier 2 items. Wait for human confirmation on each.
Track which items the human confirmed and when:
  { "test_gate": { "automated": { "passed": 5, "failed": 0 }, "manual": { "verified": 4, "pending": 1, "verified_by": "J. Smith", "date": "..." } } }

HARD READINESS GATE:
Before proceeding to Handoff, ALL of these must be true:
- All Tier 1 (automated) checks pass
- All Tier 2 (manual) checks confirmed by a human
- No Tier 2 items left in "pending" state

If gate fails, report what's missing and stay in Test phase.

Update status.json, manifest.md.
