
Generate a PRD for "$1".

**Step 0: Disambiguate**

Read `docs/audit/baseline/feature-inventory.json` and search for features
matching "$1" by name, domain, namespace, or keyword.

If no baseline exists: "No audit baseline found in docs/audit/. Continuing without it."

If multiple features match, present a numbered list:
```
"$1" matches N features:
  [1] Feature A (Domain, confidence: 0.92)
  [2] Feature B (Domain, confidence: 0.78)
  [3] Feature C (Domain, confidence: 0.65)
Which feature do you want a PRD for?
Or [A] All of the above (separate PRD per feature)
```

Wait for the developer's choice. Never assume which one they meant.

If zero features match in the baseline, ask:
```
"$1" was not found in the audit baseline.
  [1] Search the codebase directly (may find unindexed features)
  [2] Create a forward-looking PRD for a new feature named "$1"
```

**Step 1: Confidence Check**

Once a feature is selected, check its confidence score.

If confidence >= 0.90:
```
[Feature Name] confidence is [score]. Ready to generate PRD.
  [1] Generate PRD now
  [2] Run deep scan first to maximize accuracy
```

If confidence < 0.90:
```
[Feature Name] confidence is [score] (below 0.90 threshold).
The PRD may contain [ASSUMPTION] tags and unverified requirements.
  [1] Run deep scan first to verify to 95%+ (recommended)
  [2] Generate PRD at current confidence (will include assumption tags)
```

Wait for the developer's choice.

**Step 2: Deep Scan (if chosen)**

Read every entry point file for this feature. Trace database access patterns.
Verify table names. Check for feature flags. Search for callers.
Carry the verified confidence into the PRD itself; the baseline is an input and
is never written back to.

**Step 3: Generate PRD**

Generate the PRD directly, using:
- The selected feature ID
- Whether to reverse-engineer (existing feature) or template (new feature)
- The verified confidence level

Steps:
1. Create `docs/prd/{domain}/` directory
2. Write the PRD using the skeleton below

**Document skeleton**

For an existing feature, reverse-engineer each section from entry points,
DB tables, and tests; tag anything not tool-verified with `[ASSUMPTION]`.
For a new feature, fill from the developer's answers and leave unknowns in
Open Questions rather than inventing them.

```markdown
# PRD: {Feature Name}

**Domain:** {domain} · **Feature ID:** {id or "new"} · **Confidence:** {score or "n/a"}
**Status:** Draft | Approved · **Date:** {YYYY-MM-DD}
**Linked:** BRD-{domain} · ADR-{NNN} · Spec {link}

## Problem Statement

{2-3 sentences: the user problem, who experiences it and how often, and the
cost of not solving it. Ground in evidence: support data, metrics, findings.}

## Goals

{3-5 measurable outcomes, not outputs. "Reduce time to first value by 50%",
not "build onboarding wizard". Split user goals from business goals.}

## Non-Goals

{3-5 things this feature will NOT do, each with a one-line reason: not enough
impact, too complex, separate initiative, premature.}

## User Stories

{"As a {specific user type}, I want {capability} so that {benefit}." Grouped
by persona, ordered by priority. Include error, empty, and boundary states.}

## Requirements

### Must-Have (P0)

{Cannot ship without. Test: "If we cut this, does the feature still solve the
core problem?" If yes, it is not P0.}

- **REQ-001:** {behavior}
  - Given {precondition}, when {action}, then {outcome}
  - Given {error or edge condition}, when {action}, then {outcome}
  - Depends on: {team, system, or "none"}

### Nice-to-Have (P1)

{Improves the experience; core use case works without it. Likely fast follows.}

### Future Considerations (P2)

{Out of scope for v1, but design must not block them.}

## Success Metrics

| Metric | Type | Target | Measured by | Evaluate at |
|--------|------|--------|-------------|-------------|
| {adoption, activation, task completion, error rate} | Leading | {"50% adoption in 30 days", not "high adoption"} | {tool or query} | {1 week / 1 month} |
| {retention, revenue, support-ticket reduction} | Lagging | {target} | {tool or query} | {1 quarter} |

## Open Questions

| Question | Owner | Blocking? |
|----------|-------|-----------|
| {question} | engineering / design / legal / data / stakeholder | Yes / No |

## Timeline Considerations

{Hard deadlines, dependencies on other work, suggested phasing if too large
for one release.}
```

**Writing rules**

- If everything is P0, nothing is P0. Challenge each must-have: "Would we
  really not ship without this?"
- User stories describe the need, not the widget. "I want a dropdown" is a
  solution; "I want to pick my region without typing" is a story.
- A story with no benefit clause ("I want to click a button") is a task.
- Acceptance criteria cover happy path, error cases, and what must NOT happen.
  Each is independently testable. Ban "fast", "intuitive", "user-friendly"
  unless defined with a number.
- Any scope addition after approval comes with a scope removal or a timeline
  extension. Park good out-of-scope ideas under Non-Goals.

**Step 4: Post-Generation**

After the PRD is created, check `docs/brd/` and `docs/adr/` for related documents:

If no BRD exists for this feature's domain:
```
PRD created: docs/prd/{domain}/PRD-{name}.md

Note: No BRD exists for the [Domain] domain.
A BRD defines the business context for this feature.
  [1] Generate BRD now with /toque:documentation brd [domain]
  [2] Skip for now
```

If a BRD already exists:
```
PRD created: docs/prd/{domain}/PRD-{name}.md
Linked to: BRD-{NNN} and [N] ADRs
Document chain: BRD -> PRD -> [ADR status]
```

If no ADR exists for this feature:
```
Note: No ADR exists documenting the architectural decisions for this feature.
An ADR should document how and why this feature was built the way it is.
  [1] Generate ADR now with /toque:documentation adr [feature topic]
  [2] Skip for now
```
