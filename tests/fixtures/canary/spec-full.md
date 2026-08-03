# Sample Plan Spec (canary fixture)

Fixture for tests/canary-test.js. It deliberately contains one satisfying instance
of each thing a canary class strips, so injection has something real to remove.
Do not reflow or reorder it.

## Phase 1: Expand schema

Rollback: revert migration 0041 via `npm run db:down 0041`.
Go/No-Go: all existing integration tests pass against the widened schema.

## Phase 2: Backfill

Rollback: truncate the backfill table and re-run from the checkpoint.
Go/No-Go: row counts reconcile within 0.1% of source.

## Dependencies

| Dependency | Owner | Status |
|------------|-------|--------|
| triPOS SDK | platform team | confirmed |
| Supabase OTP quota | growth team | confirmed |

## Assumptions

| # | Assumption | Impact If False | Status |
|---|-----------|-----------------|--------|
| 1 | Existing indexes cover the new query shape | Slow reads at peak | verified |

## Testing

Scenario coverage is asserted in tests/integration/backfill.test.js.
