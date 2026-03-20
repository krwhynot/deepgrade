# Options Analysis Matrix

## What It Is

An Options Analysis Matrix is a structured comparison framework that evaluates multiple viable approaches against functional requirements, non-functional requirements (architecture characteristics), and strategic factors BEFORE committing to a solution. It prevents the most common leadership challenge to any plan: "Did you consider...?" Every option gets the same evaluation criteria applied consistently. The chosen option must have documented rationale for WHY it won over alternatives, not just "we picked X."

The matrix is not a formality or a checkbox exercise. It is the mechanism that separates a defensible architectural decision from an opinion. When a plan presents a single approach without alternatives, it is impossible for reviewers to know whether the team evaluated the space or simply went with the first idea that seemed reasonable. The Options Analysis Matrix makes the evaluation visible, comparable, and auditable.

## Enterprise Origin

Source: Gareth Morgan's Solution Architecture Decision Record template, widely adopted at enterprise scale. The template structures decisions with: High-Level Overview (ease of implementation, timescales, strategic value per option), Functional Requirements (scenario fit per option scored with traffic-light indicators), and Non-Functional Requirements/Architecture Characteristics (scalability, performance, availability per option).

Also from the arc42 architecture documentation framework used in European enterprise architecture, which includes explicit decision records with alternatives evaluated and rejected.

Jeff Tyree and Art Akerman (Capital One) published a template that includes a "Positions" field: "List the positions (viable options or alternatives) you considered... you don't want to hear the question 'Did you think about...?' during a final review; this leads to loss of credibility and questioning of other architectural decisions."

The Gareth Morgan ADR template defines three comparison layers:

### Layer 1: High-Level Overview

How well does each option fit at a glance?

| Summary | Option 1 | Option 2 | Option 3 |
|---------|----------|----------|----------|
| Ease of Implementation | Easy | Tricky | Expert knowledge required |
| Timescales | Very quick | Fairly slow | Very slow |
| Strategic Value | Purely tactical | Slightly improves UX | Ideal for upcoming merger |

### Layer 2: Functional Requirements

How well does each option handle specific scenarios?

| Scenario | Option 1 | Option 2 | Option 3 |
|----------|----------|----------|----------|
| Normal checkout flow | Full support | Full support | Full support |
| Offline mode | Not supported | Partial | Full support |
| Multi-currency | Not supported | Not supported | Full support |

### Layer 3: Non-Functional Requirements (Architecture Characteristics)

How does each option perform on quality attributes?

| Characteristic | Option 1 | Option 2 | Option 3 |
|----------------|----------|----------|----------|
| Scalability | Poor | Good | Excellent |
| Performance | Excellent | Good | Good |
| Availability | Good | Good | Excellent |

Each cell uses traffic-light scoring (green/amber/red) with `+` or `-` prefixes to indicate strong or weak positioning within a band, and brief rationale explaining the score.

## How It Works

1. **Identify minimum 2 options** (chosen approach + best alternative). 3 is ideal. The first option should not always be the one you expect to win; genuine evaluation requires genuine alternatives, not strawmen set up to lose.

2. **Define evaluation criteria in 3 categories:**
   - **High-Level:** ease of implementation, timeline, strategic value, cost
   - **Functional:** how well each option satisfies specific scenarios/requirements
   - **Non-Functional:** architecture characteristics (scalability, performance, availability, security, maintainability)

3. **Score each option against each criterion** using traffic-light indicators (green/amber/red) with `+` or `-` prefixes. Each score must include a brief rationale, not just a color. "Green" without explanation is not useful; "Green: existing SDK handles this natively, tested in staging" is.

4. **Document the winning option with explicit rationale.** Per the Tyree/Akerman template, the "Argument" section must outline why this position was selected, referencing the criteria that made the difference. The rationale should be specific enough that a reader can determine what would need to change for the decision to flip.

5. **Document what the losing options would have required** so the decision can be revisited if constraints change. For example: "Option 2 would become preferred if timeline extends beyond Q3, because its scalability advantages outweigh the longer implementation time when schedule pressure is removed."

6. **Record assumptions that influenced the choice.** If those assumptions change, the decision should be revisited. For example: "We chose Option 1 assuming the existing database can handle 2x current load. If load projections increase beyond 2x, Option 3's dedicated data layer becomes necessary."

### Example Options Analysis Section

```markdown
## Options Analysis

### Options Considered

#### Option 1: Strangler Fig Migration (RECOMMENDED)
- **Approach:** Incrementally replace legacy modules behind a facade
- **Pros:** Low risk per increment, rollback is per-module, production stays live
- **Cons:** Longer total timeline, facade adds temporary complexity
- **Risk:** LOW per increment, MEDIUM overall timeline risk
- **Rollback complexity:** LOW (revert facade routing per module)

#### Option 2: Big Bang Rewrite
- **Approach:** Build new system in parallel, cut over on a single date
- **Pros:** Clean architecture from day one, no facade overhead
- **Cons:** High risk at cutover, no production validation until launch
- **Risk:** HIGH (single point of failure at cutover)
- **Rollback complexity:** HIGH (revert entire system)
- **Why rejected:** Cutover risk unacceptable for payment-critical system
- **Would revisit if:** System is non-critical OR a full maintenance window is available

### Comparison Matrix

| Criterion | Option 1: Strangler Fig | Option 2: Big Bang |
|-----------|------------------------|-------------------|
| Implementation ease | +Green: incremental, team familiar with pattern | Red: requires parallel development capacity |
| Timeline | Amber: 4 months total | -Amber: 2 months build + high-risk cutover |
| Strategic alignment | +Green: supports incremental delivery roadmap | Amber: delivers faster but higher risk |
| Risk profile | +Green: risk distributed across increments | Red: concentrated at cutover |
| Rollback complexity | +Green: per-module rollback | Red: full system rollback |

### Decision Rationale
Option 1 selected because risk distribution across increments is the decisive factor
for a payment-critical system. Option 2's shorter build timeline does not compensate
for the concentrated cutover risk. This decision assumes the team can maintain the
facade without excessive overhead; if facade maintenance exceeds 20% of sprint capacity,
Option 2 should be reconsidered.
```

## Why It Prevents Gaps

- **Forces explicit consideration of alternatives** (prevents tunnel vision on first idea). Teams naturally anchor on the first approach that seems viable. The matrix requirement forces them to genuinely evaluate the space.
- **Exposes hidden assumptions:** "We picked X because we assumed Y about timeline." When assumptions are documented alongside the decision, changes to those assumptions trigger re-evaluation rather than silent drift.
- **Creates institutional knowledge:** future team members understand WHY, not just WHAT. Six months later, when someone asks "why didn't we just do X?", the matrix provides the answer without requiring the original team to be present.
- **Prevents leadership credibility challenges:** alternatives are documented and evaluated. The Tyree/Akerman warning is practical: hearing "did you think about...?" in a review meeting undermines confidence in every other decision in the plan.
- **Enables decision reversal:** if constraints change, you know which alternative to revisit and under what conditions. The "would revisit if" documentation turns a rejected option into a ready fallback.
- **Catches non-functional blind spots:** a solution that is great for features but terrible for scalability gets exposed in the matrix. Without the matrix, non-functional requirements tend to be evaluated only after functional requirements are satisfied, by which point commitment to the approach is already high.
- **Prevents "sunk cost" attachment:** options are evaluated before work begins, so there is no emotional or financial investment in any particular approach when the comparison is made.

## Status Before Implementation

Our Phase 3 (Pre-Plan) approach.md selects a single pattern (Strangler Fig, Feature Flag, Migration, etc.) without documenting what alternatives were considered or why they were rejected. The plan-scaffolder's Step 3 "Identify the Pattern" picks one from a table. There is no structured comparison. When leadership asks "did you consider just refactoring in place instead of the migration?" we have no documented answer.

This means:
- No record of WHY alternatives were rejected
- No fallback if the chosen approach hits a blocker during Build
- Leadership cannot validate the decision process
- The same "Did you consider X?" question gets asked repeatedly with no way to resolve it
- If constraints change mid-project, the team must start analysis from scratch rather than referencing a pre-evaluated alternative

## Implementation (Completed)

- **Add an Options Analysis section as a REQUIRED part of approach.md in Phase 3.** This is not optional. Every approach.md must include it.
- **Minimum 2 options compared** (selected approach + strongest alternative). Three is preferred for complex decisions.
- **Each option scored against:** ease of implementation, timeline, strategic value, risk level, rollback complexity. Additional criteria can be added per project but these five are the baseline.
- **Add traffic-light indicators for quick visual scanning.** Green/amber/red with `+`/`-` prefixes and brief rationale per cell.
- **Winner must have an explicit "Argument" section** (per Tyree/Akerman: "Outline why you selected a position"). The argument must reference specific criteria from the matrix, not general statements.
- **Losing options documented with "would revisit if" conditions.** This transforms rejected options into contingency plans rather than dead ends.
- **Add LINT-13: Approach has options analysis with minimum 2 alternatives evaluated.** This lint rule checks for the structural presence of the Options Analysis section, the minimum number of options, and the presence of a Decision Rationale.
- **Plan-scaffolder's Pattern Researcher analyst should produce a comparison, not just a recommendation.** The analyst's output should be a scored matrix, and the orchestrator should select from the matrix rather than receiving a single recommendation.

## References

- Gareth Morgan, "Solution Architecture Decisions" (linkedin.com/pulse/solution-architecture-decisions-gareth-morgan)
- arc42 Architecture Documentation Framework (arc42.org)
- Jeff Tyree & Art Akerman, "Architecture Decisions: Demystifying Architecture", Capital One Financial
- Joel Parker Henderson, ADR Templates (github.com/joelparkerhenderson/architecture-decision-record)
- Mark Richards & Neal Ford, "Fundamentals of Software Architecture: An Engineering Approach"
