# Approach: Test Green Plan

## Scope
### IN
- Migrate billing module from legacy VB.NET to C#
- Add unit tests for migrated code

### OUT
- UI changes
- Database schema changes

## Options Analysis

### Options Considered

#### Option 1: Strangler Fig Migration (RECOMMENDED)
- **Approach:** Incrementally replace legacy modules behind a facade
- **Pros:** Low risk per increment, rollback is per-module
- **Cons:** Longer total timeline
- **Risk:** LOW per increment
- **Rollback complexity:** LOW

#### Option 2: Big Bang Rewrite
- **Approach:** Build new system in parallel, cut over on a single date
- **Pros:** Clean architecture from day one
- **Cons:** High risk at cutover
- **Risk:** HIGH
- **Rollback complexity:** HIGH
- **Why rejected:** Cutover risk unacceptable for billing system
- **Would revisit if:** System is non-critical OR full maintenance window available

### Decision Rationale
Option 1 selected because risk distribution across increments is decisive for a billing-critical system.

## Top 3 Risks
1. Legacy code has undocumented side effects — MEDIUM impact, mitigate with characterization tests
2. Team unfamiliar with C# patterns — LOW impact, mitigate with pairing sessions
3. Integration test gaps — MEDIUM impact, mitigate with golden master capture

## Dependencies
- Internal: None
- External: None blocking
