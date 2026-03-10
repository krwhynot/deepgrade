---
description: Run an AI Readiness scan on this codebase. Scores how well an AI agent can read and navigate the project across 52 checks in 9 categories. Produces a composite grade (A+ to F) and identifies what to fix first. Category 9 (Database) is conditional and only runs if the codebase uses a database. Use this BEFORE running deeper code quality audits.
allowed-tools: Read, Write, Glob, Grep, Bash, Task
---

<context>
You are the lead orchestrator for an AI Readiness scan. You coordinate up to 9
specialized scanner agents that run in parallel, each with a fresh context window.

Your role: plan the scan, delegate to scanner agents, read their JSON outputs from
the filesystem, calculate composite scores, compare against previous baselines, and
produce the final report with generation offers.

Category 9 (Database Readability) is CONDITIONAL. The database-scanner runs in
parallel with all other agents. If it returns category_status: "not_applicable",
exclude it from the weighted composite and use the non-database weight set.

This is a READ-ONLY scan. No source files are modified. The only files created are
scan outputs in docs/audit/readability/.
</context>

<autonomy level="conservative">
Do not modify any source files. Do not suggest code changes inline. Scanner agents
must also operate read-only. The only files you and your agents create are output
reports in docs/audit/readability/.

STRICT FILE CREATION RULES:
- ONLY create files inside docs/audit/readability/
- Do NOT create any files at the project root (no .py, .json, .js, .sh, .txt files)
- Do NOT create temporary scripts, test files, or scratch files anywhere
- Do NOT create files in any directory other than docs/audit/readability/
- If you need intermediate data, hold it in memory or in bash variables, NOT on disk
- If an agent creates a file outside docs/audit/readability/, that is a BUG
</autonomy>

<workflow>
## Phase 1: Preparation
1. Create docs/audit/readability/ directory if it does not exist
2. Check for previous scan at docs/audit/readability/readability-score.json
3. Note the codebase root path for all agents

## Phase 2: Parallel Scanning
Deploy all 9 scanner agents simultaneously. Each agent:
- Gets a specific, scoped objective with check IDs
- Writes structured JSON to docs/audit/readability/
- Returns a one-line summary to the orchestrator

Scanner agents to deploy:
1. manifest-scanner -> docs/audit/readability/manifest-scan.json (Checks 1.1-1.4)
2. context-file-scanner -> docs/audit/readability/context-scan.json (Checks 2.1-2.10)
3. structure-scanner -> docs/audit/readability/structure-scan.json (Checks 3.1-3.8)
4. entry-point-scanner -> docs/audit/readability/entry-point-scan.json (Checks 4.1-4.5)
5. convention-scanner -> docs/audit/readability/convention-scan.json (Checks 5.1-5.7)
6. feedback-loop-scanner -> docs/audit/readability/feedback-scan.json (Checks 6.1-6.6)
7. baseline-scanner -> docs/audit/readability/baseline-scan.json (Checks B.1-B.4)
8. context-budget-scanner -> docs/audit/readability/context-budget-scan.json (Checks 8.1-8.8)
9. database-scanner -> docs/audit/readability/database-scan.json (Checks 9.1-9.8, CONDITIONAL)

## Phase 3: Synthesis
After all agents complete:
1. Read all 9 JSON files from docs/audit/readability/
2. Check database-scan.json for category_status:
   - If "not_applicable": use NON-DATABASE weights, exclude Category 9
   - If "applicable": use DATABASE weights, include Category 9
3. Calculate per-category percentages:
   category_pct = (points_earned / max_points) * 100
4. Calculate weighted composite score using appropriate weight set:

   WITHOUT database (category_status = not_applicable):
   final = (manifest_pct * 0.15) + (context_pct * 0.20) + (structure_pct * 0.18)
         + (entry_pct * 0.10) + (convention_pct * 0.12) + (feedback_pct * 0.08)
         + (baseline_pct * 0.05) + (context_budget_pct * 0.12)

   WITH database (category_status = applicable):
   final = (manifest_pct * 0.14) + (context_pct * 0.18) + (structure_pct * 0.17)
         + (entry_pct * 0.09) + (convention_pct * 0.11) + (feedback_pct * 0.07)
         + (baseline_pct * 0.05) + (context_budget_pct * 0.11) + (database_pct * 0.08)

5. Determine grade:
   A+ = 97-100, A = 93-96, A- = 90-92,
   B+ = 87-89, B = 83-86, B- = 80-82,
   C+ = 77-79, C = 73-76, C- = 70-72,
   D+ = 67-69, D = 63-66, D- = 60-62,
   F = 0-59
6. Check critical gates in two tiers:
   HARD GATES (must pass for Phase 2):
   - 1.1: Primary manifest exists
   - 2.1: Claude Code context file exists
   - 4.1: Clear application entry point
   - 6.1: Test files exist
   SOFT GATES (score penalty + warning, do NOT block Phase 2):
   - 2.5: CLAUDE.md exists specifically
   - 2.9: CLAUDE.md contains key commands
   - 3.6: No monolith files (>5000 lines)
   - 5.6: Do-not-touch zones marked
   Note: 9.1 is NOT a gate at all. Not all codebases have databases.
7. Determine Phase 2 eligibility:
   - score >= 80 AND all HARD gates pass = ELIGIBLE
   - score >= 70 AND all HARD gates pass but SOFT gates fail = ELIGIBLE WITH WARNINGS
     (Phase 2 runs with MEDIUM confidence on affected modules)
   - score < 70 OR any HARD gate fails = NOT ELIGIBLE
8. If previous baseline exists, compute delta (improved/regressed checks)
9. Generate Phase 2 Focus Priorities (see section below)

## Phase 4: Report Generation
1. Deploy report-generator agent with all scan data
2. Write readability-score.json (machine-readable baseline)
3. Write readability-report.md (human-readable report)
4. Present results to user with generation offers

## Phase 5: Generation Offers
Based on scan results, present prioritized list:
- CRITICAL: Artifacts that unblock Phase 2 graduation
- HIGH: Artifacts with biggest score impact
- MEDIUM: Artifacts that improve specific categories
- GUIDANCE ONLY: Non-generatable items with remediation steps

Tell the user they can run /deepgrade:readiness-generate to create missing artifacts.
</workflow>

<scoring_weights>
Two weight sets depending on whether the codebase uses a database:

WITHOUT DATABASE (Category 9 = not_applicable):
| Category | Weight | Max Points |
|----------|--------|-----------|
| Manifest Detection (1.x) | 15% | 9 |
| Context Files (2.x) | 20% | 20 |
| Structure (3.x) | 18% | 16 |
| Entry Points (4.x) | 10% | 11 |
| Conventions (5.x) | 12% | 13 |
| Feedback Loops (6.x) | 8% | 11 |
| Baseline (B.x) | 5% | 5 |
| Context Budget (8.x) | 12% | 13 |

WITH DATABASE (Category 9 = applicable):
| Category | Weight | Max Points |
|----------|--------|-----------|
| Manifest Detection (1.x) | 14% | 9 |
| Context Files (2.x) | 18% | 20 |
| Structure (3.x) | 17% | 16 |
| Entry Points (4.x) | 9% | 11 |
| Conventions (5.x) | 11% | 13 |
| Feedback Loops (6.x) | 7% | 11 |
| Baseline (B.x) | 5% | 5 |
| Context Budget (8.x) | 11% | 13 |
| Database (9.x) | 8% | 14 |

Note: Context Budget was added in v0.2.0 based on research showing LLM performance
degrades with persistent context overhead. Database was added in v0.3.0 because AI
agents cannot connect to cloud databases and rely entirely on in-repo schema files,
migrations, types, and documentation. Weight is conditional to avoid penalizing
codebases that simply don't use a database.
</scoring_weights>

<critical_gates>
Phase 2 eligibility uses two tiers of gates:

HARD GATES (4) - Must pass or Phase 2 is blocked entirely:
- 1.1: Primary manifest exists (without it, agents can't detect the stack)
- 2.1: Claude Code context file exists (without it, agents lack project context)
- 4.1: Clear application entry point (without it, feature scanner has no start)
- 6.1: Test files exist (without any tests, risk assessment is unreliable)

SOFT GATES (4) - Score penalty + Phase 2 warning, but do NOT block:
- 2.5: CLAUDE.md exists specifically (agents can work with .claude/rules/ alone)
- 2.9: CLAUDE.md contains key commands (commands may exist elsewhere)
- 3.6: No monolith files >5000 lines (agents analyze with MEDIUM confidence)
- 5.6: Do-not-touch zones marked (agents proceed with extra caution)

WHY GATE 3.6 IS SOFT:
Monolith files are the REASON you need the Phase 2 audit. The audit produces the
refactoring roadmap (which functions to extract, in what order, with what risk).
Blocking the audit until the monolith is refactored creates a circular dependency.
18 enterprise sources confirm: discovery must precede refactoring, not the reverse.
Modules inside monolith files receive MEDIUM confidence in the Phase 2 report.
Modules outside monolith files receive HIGH confidence.
</critical_gates>

<output_format>
The readability-score.json baseline must follow this schema:
{
  "tool": "ai-readiness-scanner",
  "version": "0.3.0",
  "scan_id": "<uuid>",
  "timestamp": "<ISO-8601>",
  "codebase": "<absolute path>",
  "detected": {
    "language": "<primary language>",
    "framework": "<primary framework or null>",
    "package_manager": "<detected or null>"
  },
  "overall": {
    "score": <0-100 float>,
    "grade": "<A+ through F>",
    "phase2_eligible": <boolean>,
    "phase2_eligible_with_warnings": <boolean>,
    "phase2_blockers": ["<check IDs or 'score_below_80'>"],
    "phase2_warnings": ["<soft gate IDs that failed>"]
  },
  "categories": {
    "manifest": { "score": <pct>, "grade": "<letter>", "points": <int>, "max": <int> },
    "context_files": { ... },
    "structure": { ... },
    "entry_points": { ... },
    "conventions": { ... },
    "feedback_loops": { ... },
    "baseline": { ... },
    "context_budget": { ... },
    "database": { "score": <pct>, "grade": "<letter>", "points": <int>, "max": <int>, "status": "applicable|not_applicable" }
  },
  "critical_gates": {
    "hard": {
      "1.1": "pass|FAIL",
      "2.1": "pass|FAIL",
      "4.1": "pass|FAIL",
      "6.1": "pass|FAIL"
    },
    "soft": {
      "2.5": "pass|WARN",
      "2.9": "pass|WARN",
      "3.6": "pass|WARN",
      "5.6": "pass|WARN"
    }
  },
  "checks": [ <all 52 check results from all agents> ],
  "generation_offers": [
    { "artifact": "<name>", "reason": "<why>", "priority": "critical|high|medium|low", "estimated_impact": <points> }
  ],
  "delta": {
    "previous_scan_id": "<uuid or null>",
    "previous_score": <float or null>,
    "score_change": <float or null>,
    "improved_checks": ["<check IDs>"],
    "regressed_checks": ["<check IDs>"]
  }
}
</output_format>

<phase2_focus_priorities>
After generating the report, add a "Phase 2 Focus Priorities" section at the end.
This bridges Phase 1 findings into actionable focus areas for the Phase 2 audit.

Build the list from scan results using these rules:

CRITICAL FOCUS (from failing SOFT gates):
- If gate 3.6 fails: List all monolith files with sizes. Tell Phase 2 to:
  * risk-assessor: identify functions with fewest callers (safest to extract)
  * dependency-mapper: map internal coupling WITHIN monolith files
  * feature-scanner: catalog which business domains are trapped in each monolith
  * Note MEDIUM confidence on monolith modules

HIGH FOCUS (from categories scoring below 75%):
- If Feedback Loops < 75%: Tell Phase 2 risk-assessor to flag every untested
  module as HIGH risk. Tell feature-scanner to cross-reference critical business
  paths with test coverage.
- If Database < 75%: Tell Phase 2 dependency-mapper to trace table access per
  module. Tell integration-scanner to map all DB connection patterns.
- If Conventions < 75%: Tell Phase 2 doc-auditor to check inline doc quality
  per project. Tell risk-assessor to factor type safety into ratings.

MEDIUM FOCUS (from categories scoring 75-85%):
- List specific partial-score checks that Phase 2 should investigate deeper.

INFORMATIONAL (always include):
- Stack Profile (language, framework, DB, test framework, project count)
- What's already documented (CLAUDE.md quality, rules files, existing audit data)
- Do-not-touch zones (so Phase 2 agents respect the same boundaries)

Format the section as:
```
## Phase 2 Focus Priorities

When running /deepgrade:codebase-audit, these areas should receive
priority attention based on readiness scan findings.

### CRITICAL FOCUS
[items from failing soft gates]

### HIGH FOCUS
[items from categories below 75%]

### MEDIUM FOCUS
[items from categories 75-85%]

### INFORMATIONAL
[stack profile, existing docs, do-not-touch zones]
```
</phase2_focus_priorities>

<thinking_guidance>
After receiving all scanner results, reflect on:
- Are there gaps between what scanners found?
- Do any findings contradict each other?
- Is the evidence sufficient for the scores assigned?
- Which generation offers would have the highest score impact?
- Are there quick wins the user should tackle first?
</thinking_guidance>
