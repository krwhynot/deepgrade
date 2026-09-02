# Phase 4: Fix

Phase file for /deepgrade:troubleshoot, loaded by SKILL.md on entry.

## Contents

- Step 4.1: Create a Failing Test First
- Step 4.2: Implement Focused Fix
- Step 4.3: Verify
- Step 4.4: Git Bisect (for regression bugs)
- Step 4.5: Guardrail Evaluation (4.5.1 Inspect Each Guardrail Layer, 4.5.2 Classify Why Each Relevant Guardrail Missed, 4.5.3 Generate Recommended Actions)

## Phase 4: FIX (only NOW can you suggest a fix)

### Step 4.1: Create a Failing Test First

"Before fixing, let's prove the bug exists with a test. [Y/n]"

The test should:
- Set up conditions that trigger the bug
- Call the function that fails
- Assert the CORRECT behavior (which currently fails)

### Step 4.2: Implement Focused Fix

The fix should be:
- Single, focused change (not a refactor)
- As small as possible
- Directly addressing the root cause (not the symptom)

"Here's the fix: {description}. Apply it? [Y/n]"

### Step 4.3: Verify

```bash
# Run the failing test (should now pass)
# Run the full test suite (no regressions)
```

"Fix verified. Failing test passes. No regressions."

### Step 4.4: Git Bisect (for regression bugs)

If the bug worked before and now doesn't:

```bash
# Find which commit introduced the regression
git bisect start HEAD {last-known-good-commit}
git bisect run {test-command}
git bisect log
```

"The regression was introduced in commit {hash}: {message}."

### Step 4.5: Guardrail Evaluation (Why didn't safeguards catch this?)

After the fix is verified, inspect the ACTUAL guardrail configuration to understand
why this bug reached the environment where it was found. This step generates
RECOMMENDED follow-up actions — it does NOT automatically apply additional edits.
The fix is already verified; this is analysis, not more fixing.

#### 4.5.1: Inspect Each Guardrail Layer

Read the actual config files in THIS repo. For each guardrail, answer: could it
have caught this bug before it reached the user?

| Guardrail | Check | Files to Inspect |
|-----------|-------|-----------------|
| Unit tests | Does a test exist for the buggy function? | Test directory, test runner config |
| Integration tests | Does a test cover the interaction that broke? | Integration test files |
| Type system | Could stricter types have prevented this? | tsconfig.json, compiler options, type definitions |
| Linter rules | Is there a rule that should catch this pattern? | .eslintrc, linter configs |
| CI pipeline | Does CI run the tests that would catch this? | .github/workflows/, CI config |
| Pre-commit hooks | Would a hook have caught this locally? | .husky/, hooks config |
| Runtime validation | Should input validation have rejected the bad data? | Validation middleware, schema definitions |

Skip guardrails that clearly don't apply (e.g., don't check linter rules for a
data corruption bug). Only inspect what's relevant to THIS bug's category.

#### 4.5.2: Classify Why Each Relevant Guardrail Missed

For each guardrail that SHOULD have caught the bug, classify WHY it missed.
Use machine-friendly tokens in the format `{guardrail-type}:{classification}`:

| Classification | Token | Meaning | Action |
|---------------|-------|---------|--------|
| Not present | `not-present` | No test/rule exists for this scenario | Write it |
| Present but insufficient | `insufficient` | Test exists but doesn't cover this case | Expand coverage |
| Present but disabled | `disabled` | Rule exists but is disabled or skipped | Re-enable, understand why |
| Present but wrong | `wrong` | Test asserts the wrong thing | Fix the assertion |
| Present and passed | `wrong-layer` | Test ran but bug is at a different layer | Add coverage at correct layer |
| Not applicable | `n-a` | No reasonable guardrail could catch this | Document as accepted risk |

Examples: `unit-tests:not-present`, `ci:insufficient`, `linter:disabled`, `types:n-a`

#### 4.5.3: Generate Recommended Actions

For each missed guardrail, produce ONE specific, actionable recommendation.
These are suggestions for the user, not automatic edits.

"Guardrail evaluation:
1. `{type}:{classification}` — {specific finding}.
   **Recommended action:** {concrete change with file paths}.
2. ..."

Do NOT say "add more tests." Say "add a test for {function} that covers the
{scenario} path in {file}:{line}."

LOG: "Guardrail evaluation complete. {N} guardrails inspected, {M} gaps found.
{list of type:classification tokens}."

