# Data Source Validation (Infrastructure Verification)

## What It Is

Data Source Validation is a technique that verifies not just whether a plan CLAIMS something is tested or monitored, but whether the INFRASTRUCTURE to test or monitor actually exists. It is the difference between "we plan to monitor latency" and "the latency dashboard at grafana.internal/d/api-latency actually exists and is configured."

A plan can claim full coverage across all scenarios, but if the test files don't exist, the monitoring dashboards aren't configured, and the alert rules haven't been created, those claims are hollow. The plan says "all green" but reality is full of gaps. Data Source Validation closes the gap between claimed coverage and actual infrastructure by cross-referencing every coverage claim against verifiable artifacts.

This is not a judgment call. It is a deterministic, automatable check: does the thing that is claimed to exist actually exist? If a plan says "tested by test_billing_flow.py," either that file exists or it does not. If a plan says "monitored by the error-rate dashboard," either that dashboard configuration exists or it does not. There is no ambiguity.

## Enterprise Origin

**MITRE ATT&CK Coverage Matrix** tracking methodology is the primary source. The MITRE workbook highlights detection rules with red when "a detection rule exists without the necessary data source for detection." If you have a rule to detect LSASS memory access (T1003.001) but the data source for process access monitoring isn't enabled, your rule is useless. The detection rule claims coverage, but the infrastructure to deliver that coverage does not exist. The Techniques worksheet cross-references detection rules against available data sources and flags inconsistencies. Security teams consistently discovered they had detection rules for 80% of MITRE techniques but data sources for only 40%. Their actual coverage was 40%, not 80%.

**Cypress UI Coverage** validates that test runs actually exercised the claimed views, not just that test files exist. Cypress tracks which UI elements were interacted with during test execution and produces a coverage report showing which parts of the application were actually tested versus which parts the test suite merely claims to cover.

**SRE practices at Google** verify monitoring coverage against actual Prometheus/Grafana configurations, not documentation claims. The SRE Book documents the principle that monitoring must be verified as operational, not merely planned. An alerting rule that references a metric that is not being collected is equivalent to having no alerting at all.

## How It Works

### 1. Validate "Tested?" Claims in the Scenario Matrix

For every scenario that claims to be tested with a test reference:

- Verify the test file exists at the claimed path
- Verify the test file contains a test case matching the scenario description
- If the test file is missing or the test case is not found: flag as INCONSISTENCY

```bash
# Verify test file exists
test -f "$TEST_FILE_PATH" && echo "EXISTS" || echo "MISSING"
# Verify test contains matching test case
grep -c "$SCENARIO_KEYWORD" "$TEST_FILE_PATH"
```

### 2. Validate "Monitored?" Claims

For every scenario or component that claims to be monitored:

- Verify the monitoring configuration exists (dashboard JSON, alert rule YAML, Prometheus recording rules, etc.)
- Verify the metric or log source is configured to emit the required data
- If the monitoring configuration is missing: flag as INCONSISTENCY

### 3. Validate "Covered By" Claims in the Coverage Matrix

For every coverage claim that references a phase, ticket, or code path:

- Verify the referenced phase/ticket/code actually implements the claimed coverage
- Check that the implementation file exists and contains relevant code
- If the implementation is missing or does not match the claim: flag as INCONSISTENCY

### 4. Cross-Reference Claims Against Infrastructure

Perform a full cross-reference: all detection, test, and monitoring claims versus all available data sources and infrastructure. This is the MITRE pattern applied to software planning -- every claim must have a corresponding data source that makes the claim verifiable.

### 5. Produce an Infrastructure Verification Report

The output is a structured report:

- **Claims verified**: X out of Y total claims (Z% verification rate)
- **Inconsistencies found**: listed with severity (BLOCKER if a critical scenario has no test infrastructure, WARNING if a non-critical claim is unverified)
- **Missing infrastructure**: listed with creation recommendations (e.g., "Create test file tests/billing/test_rollback.py to cover rollback scenario")

## Why It Prevents Gaps

- **Closes the "documentation vs reality" gap.** Plans often claim coverage that does not exist. The plan author writes "tested by T1, T2, T3" as an aspiration, but T2 and T3 were never created. Without validation, this aspiration is treated as fact.

- **Catches the MITRE problem.** "Detection rule exists but data source doesn't" translates directly to software: "test file exists but doesn't actually test the scenario" or "monitoring is claimed but the dashboard was never configured."

- **Prevents false confidence.** A plan showing all-green in the Scenario Matrix but with missing test files gives dangerous false assurance. Stakeholders, managers, and the plan author themselves believe the plan is well-covered when it is not.

- **Forces infrastructure creation before the build phase.** When infrastructure is validated as part of the audit, missing test files and monitoring configs are surfaced before build begins, not discovered as an afterthought during QA or production incidents.

- **Automated verification is fast and deterministic.** No judgment is required. File existence is binary. This check can run in seconds and produces unambiguous results.

- **Catches stale references.** Test files that existed when the plan was written but were since deleted or renamed are caught. Monitoring dashboards that were reconfigured to track different metrics are caught. The plan's claims are validated against the current state of the codebase, not the state at the time the plan was authored.

## Status Before Implementation

Our Scenario Matrix (Audit Output C) checks if scenarios are marked as "Tested?" and "Monitored?" but accepts string values at face value. If the plan says "T1, T2, T3" in the Tested column, we do not verify that T1, T2, and T3 actually exist as test cases. The plan could reference entirely fictional test files and our audit would not flag the discrepancy.

Our Cross-Cutting Concern Sweep (Audit Output D) checks if concerns are "Addressed?" with a section reference, but does not verify the referenced section actually implements what it claims. A plan could reference "Section 3.2" as addressing authentication concerns, but Section 3.2 might discuss database schema with no mention of authentication.

The plan-auditor's Step 3 "Verify Claims Against Codebase" checks file paths and function names but does not cross-reference test/monitoring infrastructure against coverage claims. It verifies that the code being changed exists, but not that the test and monitoring infrastructure claimed to cover that code exists.

The result is that our audit can produce a high-confidence score for a plan that has significant infrastructure gaps. A plan that claims 8/8 scenarios are tested but only 5/8 test files exist would pass our current audit without any flags.

## Implementation (Completed)

### Add Infrastructure Verification as a Sub-Step in Phase 5 Audit

After gap matrices are built, run infrastructure verification against all claims in the Scenario Matrix and Coverage Matrix.

**For each Scenario Matrix "Tested?" entry with a test reference:**

```bash
# Verify test file exists
test -f "$TEST_FILE_PATH" && echo "EXISTS" || echo "MISSING"
# Verify test contains matching test case
grep -c "$SCENARIO_KEYWORD" "$TEST_FILE_PATH"
```

**For each "Monitored?" entry:** Check for dashboard configurations, alert rule files, or monitoring setup files in the repository. Look for Grafana JSON files, Prometheus YAML rules, Datadog monitor definitions, or equivalent monitoring-as-code artifacts.

**For Coverage Matrix "Covered By" entries:** Verify the referenced files contain implementation relevant to the claim. A file path reference should point to a file that exists and contains code related to the claimed coverage.

### New Audit Report Section

Add to the audit report output:

```
Infrastructure Verification: X/Y claims verified (Z% rate)
- Verified: [list of confirmed claims]
- INFRA-GAP: [list of claims with missing infrastructure]
- Stale: [list of claims referencing deleted/moved files]
```

### New Severity Level

Flag inconsistencies as a new severity level: **INFRA-GAP** (claimed but infrastructure missing). This is distinct from a regular gap (scenario not addressed) because the plan author believed it was addressed -- the false confidence makes it more dangerous than a known gap.

### New Lint Rules

- **LINT-15**: All "Tested" claims have verified test infrastructure. Every entry in the Scenario Matrix "Tested?" column that references a test file must point to a file that exists and contains a relevant test case.

- **LINT-16**: All "Monitored" claims have verified monitoring infrastructure. Every entry in the Scenario Matrix "Monitored?" column that references monitoring must have a corresponding configuration artifact in the repository.

## References

- MITRE ATT&CK Coverage Matrix (github.com/quitehacker/mitre-attack-enterprise-matrix-in-excel-for-soc)
- Cypress UI Coverage (docs.cypress.io/ui-coverage)
- Google SRE Book, "Monitoring Distributed Systems" (sre.google/sre-book/monitoring-distributed-systems/)
- MITRE ATT&CK Framework (attack.mitre.org)
