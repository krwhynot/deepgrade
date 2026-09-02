# Phase 7: IMPACT REVIEW

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

## Contents

- What it checks: dimensions 1-7
- Process: parallel subagents
- Output: impact-review.md template
- Testing methodology verification
- Gate

Question: What else does this change affect across layers?

This is a cross-cutting verification gate. Code that works locally and passes
targeted tests can still break integration edges, scale behavior, transition-state
UX, and downstream consumers. This phase explicitly asks "what did we miss?"

WHAT IT CHECKS:

1. INTEGRATION EDGES
   - What other modules call the code we changed?
   - Did we update all callers, or just the ones we knew about?
   - Are there event handlers, webhooks, or async consumers that depend on
     the old behavior?
   ```bash
   # Find all callers of changed functions
   grep -rn "{function-name}" --include="*.cs" --include="*.vb" --include="*.ts" \
     . 2>/dev/null | grep -v node_modules | grep -v test
   ```

2. CROSS-LAYER EFFECTS
   - Database: did schema changes affect other queries or stored procedures?
   - API: did response format changes break downstream consumers?
   - UI: did state changes affect other screens or components?
   - Config: did new settings need to be added to all environments?

3. SCALE AND PERFORMANCE
   - Will this change behave differently at production load?
   - Did we add queries inside loops? New N+1 patterns?
   - Did we add memory-intensive operations without limits?

4. TRANSITION-STATE BEHAVIOR
   - During rollout, old and new code may run simultaneously.
   - Feature flags: is the off-state still safe?
   - Database migrations: is the schema compatible with both old and new code?
   - What happens to in-flight requests during deployment?

5. TEST DELTA
   - What tests existed before vs after?
   - Did we add tests for the new behavior?
   - Did existing tests need updating and did we miss any?
   - Are there integration tests that cover the cross-cutting paths?

6. STRING PATH REFERENCES (critical for file moves/renames)
   If ANY files were moved or renamed during the build phase, scan for stale
   string-based path references that don't auto-update. This is a KNOWN gap:
   TypeScript/VSCode updates import statements on file move, but does NOT
   update string literals.

   Patterns to scan for old file paths:
   - vi.mock("old/path") and jest.mock("old/path")
   - require("old/path") string arguments
   - eslint.config.js ignore arrays
   - tsconfig.json paths and includes
   - vite.config.ts resolve.alias
   - webpack.config.js alias/resolve
   - storybook stories globs
   - jest.config moduleNameMapper
   - package.json scripts that reference file paths
   - .env files with path values
   - CLAUDE.md or README references to file locations

   ```bash
   # For each moved/renamed file, find stale string references
   OLD_PATH="{old-file-path-without-extension}"
   grep -rn "$OLD_PATH" --include="*.ts" --include="*.tsx" --include="*.js" \
     --include="*.json" --include="*.config.*" --include="*.md" \
     . 2>/dev/null | grep -v node_modules | grep -v ".git/"
   ```

   Any match is a potential stale reference that needs updating.
   TypeScript Issue #62835 (open): This is a known gap in all major IDEs.

7. BACKWARD TRACEABILITY (does every change serve a goal?)
   For every file changed during Build, verify the reverse coverage chain:
   - Changed file -> Ticket that authorized the change -> Goal it serves

   Orphan detection:
   - Files changed with no ticket mapping = SCOPE CREEP (flag)
   - Tickets with no changed files = DELIVERY GAP (flag unless explicitly deferred)

   ```bash
   # For each changed file, check if it maps to a plan ticket
   # Compare git diff file list against ticket-file mapping in status.json
   git diff --name-only HEAD~{N}..HEAD | while read FILE; do
     grep -q "$FILE" docs/plans/{date}-{name}/status.json || echo "ORPHAN: $FILE"
   done
   ```

   Any orphan file must be either:
   - Linked to an existing ticket (developer forgot to log it)
   - Justified as necessary infrastructure (added to a new ticket)
   - Flagged as scope creep for review

   This traceability check is what LINT-11 and LINT-12 are evaluated against;
   the registry holds their text and marks both as Phase 7, Full mode only.

PROCESS:
PARALLELIZATION RULE: The 5 check dimensions are independent. Deploy parallel
subagents for each dimension to speed up the review.

Deploy up to 3 subagents in parallel (scale to the size of the change):

SUBAGENT A - Integration & Cross-Layer (Sonnet):
Objective: Find all callers of changed code, check integration edges and cross-layer effects
Tools: Read, Grep, Glob, Bash
Checks: dimensions 1 (Integration Edges) and 2 (Cross-Layer Effects)

SUBAGENT B - Scale & Transition State (Sonnet):
Objective: Analyze performance impact and transition-state safety
Tools: Read, Grep, Glob
Checks: dimensions 3 (Scale) and 4 (Transition-State)

SUBAGENT C - Test Delta, String Paths & Backward Trace (Sonnet):
Objective: Compare test coverage before vs after, scan for stale string path references, AND verify backward traceability of all changed files
Tools: Read, Grep, Glob, Bash
Checks: dimensions 5 (Test Delta), 6 (String Path References), and 7 (Backward Traceability)

Each subagent writes its section to a temp file. Orchestrator synthesizes.

Steps:
1. Read the build phase's changed files from status.json
2. Deploy subagents with the list of changed files + relevant audit data
3. Each subagent scans for its dimensions
4. Cross-reference with docs/audit/dependency-map.md (if exists)
5. Cross-reference with docs/audit/integration-scan.md (if exists)
6. Synthesize all subagent findings
7. Flag any untested integration path
8. Present findings as a checklist

OUTPUT: Written to docs/plans/{date}-{plan-name}/impact-review.md with:

```markdown
# Impact Review: {Plan Name}
Date: {date}
Changed files: {count}
Integration edges checked: {count}

## Cross-Cutting Findings

| # | Finding | Severity | File | Checked? |
|---|---------|----------|------|----------|
| 1 | OrderReceipt.tsx also formats receipt strings | HIGH | src/features/orders/ | [VERIFY] |
| 2 | CCApproval.vb has hardcoded receipt text | MEDIUM | POSetcPOS/CreditCard/ | [VERIFY] |
| 3 | Print preview doesn't use new string table | LOW | POSetcPOS/Printer/ | [VERIFY] |

## Integration Paths Not Covered by Tests
- [list of caller->callee paths that have no test coverage]

## Scale Concerns
- [any performance-related observations]

## Transition-State Risks
- [anything that could break during partial rollout]

## Checklist Before Test Phase
- [ ] All callers of changed functions verified
- [ ] No untested integration paths remaining (or explicitly accepted)
- [ ] Scale behavior reviewed for production load
- [ ] Feature flag off-state tested
- [ ] Database migration compatible with old and new code
- [ ] No orphan code changes (all changes traced to tickets) [LINT-11]
- [ ] No orphan tickets (all tickets have implementation or are deferred) [LINT-12]

TESTING METHODOLOGY VERIFICATION:
For each deliverable with an assigned testing methodology (from Phase 4):
- [ ] Methodology is appropriate for the type of change (not defaulting to "unit tests")
- [ ] Test authorship is separate from implementation authorship for AI-generated code
- [ ] Database changes use Expand/Contract with forward AND backward migration scripts
- [ ] API changes have contract tests covering old code + new schema AND new code + old schema
- [ ] Characterization tests captured BEFORE refactoring (not after)
- [ ] AI Failure Mode Checklist applied to all AI-generated deliverables

Database Migration Testing (if applicable):

| Phase | What to Test | Method |
|-------|-------------|--------|
| Expand | New columns/tables exist, old untouched | Structural assertions |
| Migrate | Row counts, checksums, referential integrity preserved | Characterization + Shadow |
| Contract | Old structures removed, no orphan refs, all code uses new schema | Structural assertions |
| Rollback | Backward migration restores original state | Apply -> verify -> rollback -> verify |
| Backward compat | Old code + new schema works, new code + old schema works | Contract Testing |
| Performance | Queries under threshold, indexes present, no N+1 | Property-Based + Profiling |
```

GATE: User confirmation required.
"Impact review complete. {N} cross-cutting findings, {M} untested integration
paths. Review the findings and confirm before proceeding to Test."

If HIGH severity findings exist:
"HIGH severity: {finding}. This should be addressed before Test phase.
Fix it now, or accept the risk and proceed? [fix / accept with reason]"

Update status.json, manifest.md.
