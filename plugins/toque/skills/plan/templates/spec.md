# <Title> — Specification

- Derived from: intent.md <commit or path>
- Author: <agent + human reviewer>
- Status: Draft | Approved
- Date: <YYYY-MM-DD>

## Requirements

<Each requirement traces to a line of intent.md and carries a priority and
acceptance criteria. P0 = cannot ship without; if cutting it still solves the
core problem, it is not P0. If everything is P0, nothing is P0.>

### Functional

- **FR-001 (P0 | P1 | P2):** <what the system must do> — traces to intent.md <line>
  - Given <precondition>, when <action>, then <outcome>
  - Given <error or boundary condition>, when <action>, then <outcome>
  - Must NOT: <negative case>

### Non-functional

- **NFR-001 (P0 | P1 | P2):** <performance, security, accessibility, compliance,
  operability> — measurable: <number and how it is measured>

## Success metrics

<How anyone will know this worked after release. Targets are numbers with a
window: "50% of eligible users within 30 days", not "high adoption". Name the
measurement method and when it is evaluated.>

| Metric | Type | Target | Measured by | Evaluate at |
|---|---|---|---|---|
| <adoption, task completion, error rate, latency> | Leading | <target> | <tool or query> | <1 week / 1 month> |
| <retention, cost, support-ticket reduction> | Lagging | <target> | <tool or query> | <1 quarter> |

## Design

<Approach and rationale; architecture or data flow; interfaces (APIs, data, UI).>

## Standards applied

<Which org standards (brand, security, UX, compliance) were applied, and how.>

## Gotchas

<Conflict points, risky decisions, trade-offs, and what to watch.>

## Evidence

<The confidence brief lives here. Max 10 entries. Each entry: what it is /
who uses it at scale / why it works / reference / connection to this plan /
impact tier (High | Medium | Low) with rationale.>

1. <Name> — what: <> / who uses it: <> / why it works: <> / reference: <> /
   connection: <> / impact: <tier, rationale>

## Open questions

<Answered or deferred, with owners and due dates.>

## Verification plan

<Testing methodology (tdd | characterization | expand_contract | contract_testing |
shadow_parallel | property_based | bdd | snapshot_approval | mutation_testing) per
deliverable, and how this will be tested at build time and in Stage 4.>

## Delivery

- Tickets: <ID, title, deliverable, depends on>
- Timeline: <phases with dates or effort>
- Rollback per phase: <trigger and steps for each phase>
- Go/no-go: <criteria a human checks before each phase proceeds>
