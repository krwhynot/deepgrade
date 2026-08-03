# Sample Spec (fixture)

This file is a fixture for tests/evidence-validate-test.js. Its line numbering is
load-bearing: the tests cite specific line ranges and assert that quoted text is
byte-equal to those lines. Do not reflow, reorder, or reformat it.

## Phase 2: Database Migration

Rollback: revert migration 0043 via `npm run db:down 0043`.
Owner: platform team. Verified against staging on 2026-07-11.

## Phase 3: Cutover

No rollback path is defined for this phase.
