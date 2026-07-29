# Guardrail Evaluation (Post-Fix Analysis)

## What It Is

Guardrail Evaluation is a post-fix analysis that asks: WHY did existing safeguards — CI pipelines, tests, linters, type systems, code review — fail to catch this bug before it reached the environment where it was discovered? Every bug that reaches production (or even staging) represents a failure in the safety net, not just a failure in the code.

This is not blame assignment. It is systems thinking applied to quality gates. If a test suite passes while a bug exists, either the test coverage has a gap, or the tests are testing the wrong things. If a linter passes while a code smell exists, either the linter rules are insufficient, or the linter is misconfigured. The guardrail evaluation identifies which specific guardrail failed and what concrete change would make it catch this class of bug in the future.

The difference between "Prevention" (which our current command has) and Guardrail Evaluation is specificity. "Prevent this in the future" is vague. "LINT-05 doesn't check for null returns from this API, and the test suite has no integration test for the payment→receipt flow" is actionable.

## Enterprise Origin

**Source:** BMAD Method Root Cause Analysis framework, DORA "Change Failure Rate" metric, Cypress baseline regression detection.

The BMAD Method's root cause analysis skill defines a structured guardrail evaluation as Step 4 of its process: *"Evaluate guardrails. Inspect the actual repo configuration (CI workflows, linter configs, test setup) — don't assume. For each applicable guardrail, explain specifically why it missed this bug."*

The emphasis on "inspect the actual repo configuration — don't assume" is critical. Engineers often say "the tests should have caught this" without checking whether a relevant test exists. Or "the linter should flag this pattern" without verifying the linter rule is enabled. The BMAD approach requires reading the actual CI workflow files, linter configs, and test files before concluding what should have caught the bug.

DORA's "Change Failure Rate" metric tracks the percentage of deployments that cause failures. When a deployment causes a failure, the implicit question is: what in the CI/CD pipeline should have blocked this deployment? The metric doesn't just track failures — it drives investment in pre-deployment quality gates.

Cypress's baseline regression detection provides a model for how guardrails should work: track coverage at the element level, compare against baselines, and block regressions. If a UI element was tested and the test is removed, that's a regression. The same principle applies to code: if a code path was guarded by a test and that test is weakened or removed, the guardrail has regressed.

## How It Works

### 1. After Fix, Before Closing: Inspect Actual Guardrails

For every resolved bug, answer these questions by reading the actual configuration files:

| Guardrail | Check | File to Inspect |
|-----------|-------|----------------|
| **Unit tests** | Does a test exist for the buggy function? | `tests/` directory, test runner config |
| **Integration tests** | Does a test cover the interaction that broke? | Integration test files, test database setup |
| **Type system** | Could stricter types have prevented this? | tsconfig.json, .editorconfig, compiler options |
| **Linter rules** | Is there a rule that should catch this pattern? | .eslintrc, .editorconfig, linter configs |
| **CI pipeline** | Does CI run the tests that would catch this? | .github/workflows/, CI config files |
| **Code review** | Was the buggy change reviewed? By whom? | git log, PR history |
| **Pre-commit hooks** | Would a hook have caught this locally? | .husky/, .pre-commit-config.yaml, hooks config |
| **Runtime validation** | Should input validation have rejected the bad data? | Validation middleware, schema definitions |

### 2. Classify Why Each Guardrail Missed

For each guardrail that should have caught the bug, classify WHY it missed:

| Classification | Meaning | Action |
|---------------|---------|--------|
| **Not present** | No test/rule exists for this scenario | Write the test or add the rule |
| **Present but insufficient** | Test exists but doesn't cover this case | Expand test coverage for this case |
| **Present but disabled** | Rule exists but is disabled or skipped | Re-enable and understand why it was disabled |
| **Present but wrong** | Test exists but asserts the wrong thing | Fix the test assertion |
| **Present and passed** | Test ran but the bug is at a different layer | Add coverage at the correct layer |
| **Not applicable** | No reasonable guardrail could catch this | Document as accepted risk |

### 3. Generate Concrete Guardrail Improvements

For each missed guardrail, produce a specific, actionable improvement:

```markdown
## Guardrail Evaluation

### What missed this bug:

1. **Unit test gap**: `tests/payment/charge.test.ts` tests successful charges
   but has no test for the timeout scenario. The timeout path in
   `src/payment/charge.ts:47` is completely untested.
   **Action:** Add test case for payment gateway timeout response.

2. **CI pipeline gap**: The GitHub Actions workflow runs unit tests but not
   integration tests on PR. The integration test that WOULD catch this
   (payment→receipt flow) only runs on nightly.
   **Action:** Add integration test suite to PR workflow, or at minimum
   the payment-critical subset.

3. **Type system gap**: The `chargeResult` return type is `any`. A strict
   return type of `ChargeResult | ChargeError` would have forced the
   caller to handle the error case.
   **Action:** Add strict return types to payment service functions.
```

### 4. Track Guardrail Improvements Over Time

In the knowledge base, tag entries with which guardrails missed and what was improved:

```markdown
**Guardrails missed:** unit test (not present), CI (insufficient)
**Guardrails added:** payment timeout test, integration tests in PR workflow
```

When pattern detection finds 2+ bugs with the same missed guardrail category, flag it: "This is the 3rd bug missed by insufficient integration test coverage. Consider a systematic review of integration test gaps."

## Why It Prevents Gaps

- **Turns every bug into a permanent improvement.** Without guardrail evaluation, fixing a bug prevents THAT bug from recurring. With guardrail evaluation, fixing a bug prevents THAT CLASS of bugs from reaching production.
- **Prevents the "same miss twice" pattern.** If integration tests are consistently missing bugs, guardrail evaluation surfaces the systematic gap, not just individual test additions.
- **Provides specificity over vague "prevention."** "Add more tests" is not actionable. "Add a timeout test to charge.test.ts and move integration tests to PR workflow" is actionable.
- **Inspects reality, not assumptions.** Reading the actual CI config file reveals what actually runs, not what the team thinks runs. Engineers often assume guardrails exist that don't.
- **Creates a quality improvement backlog.** Guardrail improvements that aren't implemented immediately can be tracked as tech debt with direct traceability to the bugs they would have caught.

## Status Before Implementation

Our troubleshooting command's "Prevention" section (in the log template) asks "how to prevent this in the future" but doesn't guide the engineer to inspect actual guardrail configurations. The result is vague entries like "add more tests" or "be more careful with null checks."

The command does not:
- Inspect CI workflow files
- Check test coverage for the buggy function
- Verify linter rule configuration
- Classify WHY a guardrail missed the bug
- Generate specific guardrail improvements
- Track guardrail improvement patterns over time

## Implementation

- Add Guardrail Evaluation as **Phase 6** after Phase 5 (Fix), before logging
- Add guardrail inspection checklist (tests, linter, CI, types, code review, hooks)
- Add miss classification taxonomy (not present, insufficient, disabled, wrong, not applicable)
- Add concrete improvement generation template
- Extend knowledge base entries with guardrail miss tags
- Extend pattern detection to flag repeated guardrail misses by category

## References

- BMAD Method: Root Cause Analysis skill — guardrail evaluation step (github.com/bmadcode/bmad-method)
- DORA Metrics: Change Failure Rate (dora.dev)
- Cypress: Baseline regression detection and coverage tracking (docs.cypress.io/ui-coverage)
