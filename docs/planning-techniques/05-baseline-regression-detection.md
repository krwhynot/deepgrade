# Baseline Regression Detection

## What It Is

Baseline Regression Detection is a technique that compares the current state of a plan or system against a stored baseline snapshot to identify exactly what improved, what regressed, and what is new — at a granular, per-element level rather than aggregate scores. The key insight is that aggregate scores can mask regressions: improving 3 areas while regressing 2 can produce the same total score. Element-level tracking catches what aggregate scores hide.

A baseline is a point-in-time snapshot stored as structured data (JSON) that represents the "known good" state. Each element in the plan — every coverage item, every assumption, every scenario, every lint rule — is tracked individually so that changes in any single element are visible regardless of what happens to the overall score.

## Enterprise Origin

**Cypress UI Coverage Results API and baseline comparison framework.** Cypress tracks tested element COUNTS per view (not percentages), compares against stored baselines, and separately reports regressions vs improvements vs new items. Their documentation states: "testing one new element might reveal many more elements that aren't tested yet, the score isn't useful for a fine-grained baseline comparison between runs. Comparing the number of tested elements gives a more accurate sense of whether one run has added or removed coverage."

**MITRE ATT&CK coverage tracking.** MITRE ATT&CK uses technique-level coverage mapping against detection capabilities. Each technique (e.g., T1059 Command and Scripting Interpreter) is individually tracked as covered, partially covered, or not covered. An organization's detection posture is measured by which specific techniques have detections — not by a single aggregate coverage percentage. A regression means a specific technique lost its detection, not that a score dropped.

**DORA metrics (DevOps Research and Assessment).** DORA tracks deployment frequency, lead time, change failure rate, and recovery time as separate metrics — not a single composite score. Each metric is independently measured and compared against its own baseline. An organization can improve deployment frequency while regressing on change failure rate, and both trends are visible independently.

## How It Works

1. **Capture a baseline snapshot** after each plan audit or phase completion:
   - Coverage Matrix item count and gap count
   - Assumption count: total, verified, unverified, waived
   - Scenario Matrix: 8 scenarios with individual status (covered/partial/gap)
   - Cross-Cutting Concerns: 12 concerns with individual status
   - Lint rule results: 10 rules with individual pass/fail
   - Dimension scores: 8 dimensions individually

2. **Store as JSON** with run metadata (date, plan version, run number):
   ```json
   {
     "run_number": 3,
     "date": "2026-03-19",
     "plan_version": "worldpay-canada-v2",
     "coverage_matrix": {
       "total_items": 12,
       "gap_count": 1,
       "items": [
         {"name": "bilingual receipts", "status": "covered"},
         {"name": "rollback procedure", "status": "gap"}
       ]
     },
     "assumptions": {
       "total": 8,
       "verified": 6,
       "unverified": 1,
       "waived": 1
     },
     "scenario_matrix": [
       {"id": 1, "name": "Happy path", "status": "covered"},
       {"id": 5, "name": "Scale/volume edge", "status": "partial"}
     ],
     "cross_cutting_concerns": [
       {"name": "API contract", "status": "ok"},
       {"name": "CORS", "status": "ok"},
       {"name": "Rate limiting", "status": "gap"}
     ],
     "lint_rules": [
       {"id": "LINT-01", "name": "No vague scope", "status": "pass"},
       {"id": "LINT-07", "name": "Rollback defined", "status": "fail"}
     ],
     "dimension_scores": [
       {"name": "Completeness", "score": 4},
       {"name": "Feasibility", "score": 5}
     ]
   }
   ```

3. **On next audit/check, compare current vs baseline per-element:**
   - **REGRESSION**: item was covered, now has a gap (flag as failure)
   - **IMPROVEMENT**: item had a gap, now covered (report as progress)
   - **NEW**: item didn't exist in baseline (report for awareness)
   - **MISSING**: item was in baseline but gone from current (flag as potential issue)

4. **Fail the build/gate ONLY on regressions** (not on pre-existing gaps). Pre-existing gaps are tech debt to be closed incrementally; regressions are new damage that must be addressed immediately.

5. **Generate a new baseline** after each comparison for future use.

6. **Store baselines in version control** alongside the plan, in the plan folder: `docs/plans/{date}-{name}/baseline.json`

## Why It Prevents Gaps

- **Catches regressions that aggregate scores mask.** Improving 3 areas while regressing 2 produces the same total score. Per-element comparison surfaces both the improvements and the regressions independently.
- **Allows incremental gap closure.** Fix existing gaps over time without blocking deployments. The baseline only gates on regressions from the known-good state, not on pre-existing gaps.
- **Separates "new gaps introduced" from "existing gaps."** Regressions (new gaps) always block. Existing gaps (tech debt) are fixed incrementally. This distinction is critical for maintaining velocity while improving quality.
- **Per-element tracking provides actionable specificity.** "Scenario 5: Scale/volume edge regressed from covered to partial" is actionable. "Score dropped 2 points" is not.
- **Baseline history creates a trend line** showing plan health over time. Multiple baselines stored as an array reveal whether quality is steadily improving, plateauing, or oscillating.
- **Branch-specific baselines** allow different standards for main vs feature branches, similar to Cypress profiles. A feature branch baseline can be more permissive during development while the main branch baseline enforces the strictest standard.

## Status Before Implementation

Our `/deepgrade:codebase-delta` scanner tracks aggregate codebase scores over time but not per-element plan metrics. A plan audit might improve 3 lint rules but regress on 2 scenario matrix items, and we'd report "6/10 lint rules pass" without noting that 2 previously-passing rules now fail. We have no per-concern baseline comparison. We also don't distinguish between pre-existing gaps and newly introduced regressions.

When a plan is re-audited after changes, the new audit produces a fresh score. If the score is the same or higher, we report success. But that score could hide element-level regressions masked by improvements elsewhere. There is no mechanism to flag "Scenario 5 was covered in the last audit but is now a gap" — only "the plan has 1 scenario gap."

## Implementation (Completed)

- **Add per-element baseline snapshot to status.json** after each Phase 5 Audit. Structure:
  ```json
  {
    "baseline": {
      "run_number": 3,
      "date": "2026-03-19",
      "lint_results": {
        "LINT-01": "pass",
        "LINT-02": "pass",
        "LINT-07": "fail"
      },
      "coverage_items": [
        {"name": "bilingual receipts", "status": "covered"},
        {"name": "rollback procedure", "status": "gap"}
      ],
      "scenario_statuses": [
        {"id": 1, "status": "covered"},
        {"id": 5, "status": "partial"}
      ],
      "concern_statuses": [
        {"name": "API contract", "status": "ok"},
        {"name": "Rate limiting", "status": "gap"}
      ],
      "dimension_scores": [
        {"name": "Completeness", "score": 4},
        {"name": "Feasibility", "score": 5}
      ]
    }
  }
  ```
- **Add baseline comparison logic to /deepgrade:codebase-delta** when a plan is active. When both a previous baseline and a current audit exist, run per-element comparison before reporting results.
- **Report three categories separately:**
  - **Regressions** (block): items that were covered/passing and are now gap/failing
  - **Improvements** (celebrate): items that were gap/failing and are now covered/passing
  - **New Items** (track): items not present in the previous baseline
- **Auto-generate new baseline JSON** after each comparison. The new baseline becomes the reference for the next run.
- **Add "Compare to Baseline" step to Phase 5 Audit** when re-auditing an existing plan. Before generating the audit report, load the previous baseline and run the comparison. Include the comparison results in the audit output.
- **Track baseline history as array in status.json** for trend analysis. Each baseline snapshot is appended, not overwritten, creating a full history of plan health over time.
- **Add LINT-14: No regressions from previous baseline** (hard gate). This lint rule fails the audit if any element that was covered/passing in the previous baseline is now a gap/failing. Pre-existing gaps do not trigger this rule.

## References

- Cypress UI Coverage Results API (docs.cypress.io/ui-coverage/results-api)
- Cypress "Block pull requests and set policies" guide (docs.cypress.io/ui-coverage/guides/block-pull-requests)
- MITRE ATT&CK Coverage Tracker (github.com/quitehacker/mitre-attack-enterprise-matrix-in-excel-for-soc)
- DORA Metrics (dora.dev)
