Generate a Technical Specification for "$1".

**Step 0: Disambiguate**

Determine what kind of spec this is:

If "$1" describes an extraction or migration:
  -> Use the "Extraction/Migration Spec" sections below

If "$1" describes a new feature or capability:
  -> Use the "Feature Spec" sections below

If "$1" describes an infrastructure or tooling change:
  -> Use the "Infrastructure Spec" sections below

If "$1" is vague, present options:
```
"$1" could be documented as:
  [1] Extraction/Migration Spec (moving code between modules/languages/platforms)
  [2] Feature Spec (new capability or enhancement)
  [3] Infrastructure Spec (CI/CD, tooling, observability, deployment)
Which type fits best?
```

Wait for the developer's choice.

**Step 1: Gather Context**

Check for existing audit data that informs this spec:
- `docs/audit/risk-assessment.md` - risk levels for affected modules
- `docs/audit/feature-inventory.md` - features in scope
- `docs/audit/dependency-map.md` - what depends on what
- `docs/audit/integration-scan.md` - external touchpoints
- `docs/audit/readability/readability-report.md` - readiness score

If audit data exists, present relevant findings:
```
Related audit findings for "$1":
  - Risk level: [HIGH/MEDIUM/LOW] for affected modules
  - Dependencies: [N] modules depend on this area
  - Test coverage: [status]
  - Known issues: [list from audit]

  [1] Proceed with spec generation
  [2] I want to adjust the scope
```

If no audit data exists, proceed with codebase analysis.

**Step 2: Analyze the Codebase**

Read the relevant source files to understand:
- Current implementation (what exists today)
- Interfaces and contracts
- Database access patterns
- External dependencies
- Test coverage

**Step 3: Generate Spec**

Write the spec to `docs/specs/SPEC-{NNN}-{topic}.md` using this template:

```markdown
# SPEC-{NNN}: {Title}

## Context

**Problem:** [What's wrong or missing today]
**Impact:** [Business or technical cost of not doing this]
**Trigger:** [What prompted this work: bug, feature request, tech debt, mandate]

## Goal

[One paragraph: what the end state looks like when this is done]

**Critical Constraint:** [The one thing that absolutely cannot go wrong]

## Architecture

[Diagram or description of the proposed design]

**Pattern:** [Strangler Fig / Feature Flag / Migration / Refactor / New Component]
**Follows existing pattern:** [Reference to codebase pattern if applicable]

### New Components
[List new files/projects being created with paths]

### Modified Components
[List existing files being changed with paths]

### Dependencies
[What this spec depends on and what depends on it]

## Phases

### Phase 1: {Name} ({RISK} risk)

**Source:** [Functions/files being touched with line references]

**Deliverables:**
- [Concrete output 1]
- [Concrete output 2]

**Tests:** ~{N} tests covering [what scenarios]

**Validation:** [How to verify this phase is correct]

**Entry Criteria:** [What must be true to start]
**Exit Criteria:** [What must be true to finish]
**Estimated Effort:** [{N} days/weeks with basis for estimate]
**Rollback:** [How to undo if needed]

### Phase 2: {Name} ({RISK} risk)
[Same structure]

## Shadow Mode / Validation Strategy

**Feature flag:** [Name and location]
**Comparison method:** [How old and new are compared]
**Mismatch threshold:** [What % triggers investigation vs automatic rollback]
**Duration:** [How long to run in shadow before cutover]

## Risk Assessment

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|-----------|
| 1 | [risk] | [H/M/L] | [H/M/L] | [how to handle] |

## Hidden Dependencies / Gotchas

[Numbered list of non-obvious things that could derail implementation]

1. [Gotcha with explanation]
2. [Gotcha with explanation]

## Timeline

| Phase | Estimated Effort | Dependencies | Risk |
|-------|-----------------|-------------|------|
| 1 | [X weeks] | [what it needs] | [level] |

**Total estimated duration:** [X months]
**Buffer:** [20-30% for unknowns]

## Team & Resources

**Required skills:** [What expertise is needed]
**Headcount:** [How many people]
**Impact on other work:** [What gets delayed]
**Single accountable owner:** [Name/role or TBD]

## Testing Strategy

**Characterization tests:** [Needed before refactoring? For which functions?]
**Unit tests:** [Count and coverage target per phase]
**Integration tests:** [What needs end-to-end validation]
**Golden master fixtures:** [Capture real scenarios as JSON test data?]

## Rollback Strategy

**Kill switch:** [Feature flag name and how to flip it]
**Revert threshold:** [What triggers automatic rollback]
**Old code retention:** [When can old code be removed]
**Data rollback:** [Is data migration involved? How to reverse?]

## Success Criteria

[How do we know this worked?]
- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]
- [ ] [Measurable outcome 3]

## Open Questions

[Things that need answers before Phase 1 starts]
- [ ] [Question 1]
- [ ] [Question 2]

## Critical Files

| File | Role |
|------|------|
| [path] | [what it does in this spec] |

## Verification

**Per-phase:** [Test commands to run after each phase]
**End-to-end:** [Full validation procedure]
**Golden-master:** [How to capture and replay test scenarios]
```

**Step 4: Cross-Reference**

After generating the spec:
1. Check if related ADRs exist. If not, suggest creating one.
2. Check if a PRD exists for affected features. If not, suggest creating one.
3. If the plan-auditor is available, suggest running it on the spec.

```
Spec created: docs/specs/SPEC-{NNN}-{topic}.md

Document chain:
  - Related ADRs: [list or "None - consider /deepgrade:doc adr {topic}"]
  - Related PRDs: [list or "None - consider /deepgrade:doc prd {feature}"]
  - Related BRDs: [list or "None - consider /deepgrade:doc brd {domain}"]

Suggested next step:
  Run /deepgrade:quick-audit docs/specs/SPEC-{NNN}-{topic}.md
  to score the spec across 8 dimensions before presenting to leadership.
```
