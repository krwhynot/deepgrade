# Plan Lint Registry

Single source of truth for all plan lint rules. Referenced by `plan-auditor.md`, `plan.md`, and `quick-plan.md`.

## Rules

| Rule | Description | Phase | Applies In |
|------|-------------|-------|------------|
| LINT-01 | Every goal has at least one mapped ticket | 5 (Audit) | Full + Lite |
| LINT-02 | Every HIGH risk has a mitigation | 5 (Audit) | Full + Lite |
| LINT-03 | Every deployment phase has a rollback plan | 5 (Audit) | Full + Lite |
| LINT-04 | Every external dependency has an owner | 5 (Audit) | Full + Lite |
| LINT-05 | Every new endpoint/API has a contract or test entry | 5 (Audit) | Full + Lite |
| LINT-06 | Backward compatibility claimed but no mixed-state scenario | 5 (Audit) | Full + Lite |
| LINT-07 | Every new behavior has a test or test delta | 5 (Audit) | Full + Lite |
| LINT-08 | No unverified HIGH-impact assumption exists | 5 (Audit) | Full + Lite |
| LINT-09 | No unaddressed cross-cutting concern for in-scope features | 5 (Audit) | Full + Lite |
| LINT-10 | Every phase has go/no-go criteria | 5 (Audit) | Full + Lite |
| LINT-11 | Every code change maps to a plan ticket | 7 (Impact) | Full only |
| LINT-12 | Every plan ticket maps to at least one code change (or deferred) | 7 (Impact) | Full only |
| LINT-13 | Approach has options analysis with min 2 alternatives evaluated | 5 (Audit) | Full + Lite |
| LINT-14 | No regressions from previous baseline | 5 (Audit) | Full + Lite |
| LINT-15 | All "Tested" claims have verified test infrastructure | 5 (Audit) | Full + Lite |
| LINT-16 | All "Monitored" claims have verified monitoring infrastructure | 5 (Audit) | Full + Lite |

## Phase Ownership

- **Phase 5 (Audit):** LINT-01 through LINT-10, LINT-13, LINT-14, LINT-15, LINT-16 (14 rules)
- **Phase 7 (Impact Review):** LINT-11, LINT-12 (2 rules, Full mode only)
- **Total:** 15 active rules (LINT-14 reserved)

## Audit Modes

- **Full mode** (`/deepgrade:plan`, `/deepgrade:quick-audit` with plan context): All 15 rules apply. Phase 7 rules run during Impact Review.
- **Lite mode** (`/deepgrade:quick-plan`, standalone `/deepgrade:quick-audit`): 13 rules apply. LINT-11 and LINT-12 are skipped (no build phase, no changed files to trace).

## Gate Behavior

| Rule | Gate Type | Behavior |
|------|-----------|----------|
| LINT-08 | **Hard gate** (Phase 6 entry) | Blocks Build if any HIGH-impact assumption is unverified. Waiver requires documented risk acceptance. |
| LINT-11 | Advisory (Phase 7) | Flags orphan code changes for review. Does not block. |
| LINT-12 | Advisory (Phase 7) | Flags orphan tickets for review. Does not block. |
| LINT-14 | Audit quality (Phase 5) | Fails if any previously-passing element now fails. Skipped on first audit (no baseline). |
| All others | Audit quality | Contribute to gap-checked status. Plan is gap-checked only when all applicable lint rules pass. |

## Lint Count by Context

| Context | Lint Rules | Count |
|---------|-----------|-------|
| Phase 5 Audit (Full mode) | 01-10, 13, 14, 15, 16 | 14 |
| Phase 5 Audit (Lite mode) | 01-10, 13, 14, 15, 16 | 14 |
| Phase 7 Impact Review | 11, 12 | 2 |
| Total (Full mode) | All active | 16 |
| Total (Lite mode) | Minus 11, 12 | 14 |
