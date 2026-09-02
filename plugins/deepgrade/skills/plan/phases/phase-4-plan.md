# Phase 4: PLAN

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

Question: How will we execute?

Create docs/specs/{plan-name}.md with THREE views:

1. JIRA-READY TICKETS: Per phase, with title, acceptance criteria, assignable
2. LEADERSHIP SUMMARY: Executive summary, timeline table, go/no-go criteria
3. WORKING CHECKLIST: Step-by-step with verification per step

Detail level per phase based on risk:
- HIGH risk: exact files, function names, grep patterns, commit SHA, test requirements
- MEDIUM risk: file paths, approach, key decisions
- LOW risk: goals, scope, success criteria

Include:
- Timeline table with dependencies and critical path
- Operational readiness section (if deployment involved): monitoring, config rollout, incident fallback, success metrics
- Rollback plan per phase
- Go/no-go criteria per phase boundary

TESTING METHODOLOGY SELECTION (REQUIRED):
For EACH deliverable in the spec, select the appropriate testing methodology.
Do NOT default to "unit tests" for everything. Reference the Testing Methodology
Selection Framework (docs/planning-techniques/10-testing-methodology-selection.md).

| # | Methodology | Evidence Tier | When to Use |
|---|-------------|--------------|-------------|
| 1 | TDD | ENTERPRISE-VALIDATED | New feature with clear spec, algorithms, core business logic, stored procedures |
| 2 | BDD | INDUSTRY-RECOMMENDED | User-facing features, cross-functional teams, requirements ambiguity |
| 3 | Characterization / Golden Master | ENTERPRISE-VALIDATED | Refactoring legacy code, extracting from monolith, data migration validation |
| 4 | Contract Testing | INDUSTRY-RECOMMENDED | Microservices, API integrations, database backward compatibility |
| 5 | Property-Based | INDUSTRY-RECOMMENDED | Algorithms with infinite input space, financial calculations, query performance |
| 6 | Snapshot / Approval | INDUSTRY-RECOMMENDED | UI components, serialized output, reports, config generation |
| 7 | Shadow / Parallel | ENTERPRISE-VALIDATED | Production migration, database cutover, replacing live systems |
| 8 | ATDD | INDUSTRY-RECOMMENDED | Sprint planning, user story definition, database migration sign-off |
| 9 | Mutation Testing | EMERGING PRACTICE | Pre-release quality gate, measuring test suite effectiveness |
| 10 | Exploratory | ENTERPRISE-VALIDATED | Complex UI, late-stage discovery, automation gaps |
| 11 | Expand/Contract | ENTERPRISE-VALIDATED | Database schema migration, renaming columns/tables, changing data types |

AI-specific requirements:
- The agent that writes implementation code MUST NOT write the tests (Separate Test Authorship)
- AI-generated code receives higher testing scrutiny than human code
- Every AI-generated deliverable is checked against the AI Failure Mode Checklist:
  logic drift, stale dependencies, hidden business rule violations, tautological
  tests, happy-path-only coverage

For database schema changes, use Expand/Contract (Methodology 11) with three phases:
  - Expand: add new alongside old (structural assertions)
  - Migrate: dual-write, backfill, test (data integrity + shadow comparison)
  - Contract: remove old after cutover (no orphan references)

GATE: User confirmation REQUIRED.
"Plan created with {N} phases and {M} tickets over {X} weeks. Review and confirm?"

Update status.json, manifest.md.
