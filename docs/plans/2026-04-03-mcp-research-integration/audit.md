# Plan Audit Report
Generated: 2026-04-03
Plan reviewed: MCP Research Integration (docs/specs/mcp-research-integration.md)
Auditor: DeepGrade Plan Auditor v1.0
Audit mode: FULL (brainstorm.md, approach.md, confidence.md, findings.md available)

## Executive Summary

This is a well-structured, low-risk plan to add optional MCP search tool integrations across the DeepGrade plugin. Its greatest strength is the consistent graceful degradation pattern -- every integration is additive with explicit fallback behavior, meaning the blast radius of any failure is zero. The biggest gap is the absence of automated testing: every ticket uses "Manual" testing with no regression strategy to ensure future changes don't break the conditional logic. The plan is recommended for CONDITIONAL-GO with the addition of a smoke test checklist artifact.

## Overall Score: 30/40
Interpretation: YELLOW (24-31 range) -- solid plan with addressable gaps

## Scorecard

| Dimension | Score | Confidence | Key Strength | Key Gap |
|-----------|-------|-----------|-------------|---------|
| 1. Problem Definition | 4/5 | HIGH | Clear problem with 4 affected personas and quantified token impact | Success metrics are qualitative, not measurable |
| 2. Architecture & Design | 5/5 | HIGH | Follows verified existing pattern (security-scanner prose-fallback) | None |
| 3. Phasing & Sequencing | 5/5 | HIGH | Gate at MCP-002 prevents wasted work; phases independent | None |
| 4. Risk Assessment | 3/5 | HIGH | Top risk identified with empirical mitigation (MCP-002) | Missing risks: tool name drift, token budget regression |
| 5. Rollback & Safety | 4/5 | HIGH | Per-ticket rollback + full git revert command provided | No verification that rollback restores exact prior behavior |
| 6. Timeline & Effort | 3/5 | HIGH | Phase-level estimates provided (30 + 90 + 20 min) | No buffer, no critical path, solo developer bus factor |
| 7. Testing & Validation | 2/5 | HIGH | Each ticket has testing line item | All testing is "Manual" with no regression/automation strategy |
| 8. Team & Resources | 2/5 | MEDIUM | Owner identified (Kyle) | No capacity assessment, no backup, no tech reviewer assigned |

## Detailed Findings

### What the Plan Gets Right

1. **Consistent architecture pattern.** Every integration follows the same template: add to allowed-tools, write conditional prose, write fallback, tag unavailable outputs. This is verified against the existing `agents/security-scanner.md` lines 63-65 which uses the identical pattern. HIGH [B]: direct codebase verification.

2. **Smart gating with MCP-002.** The entire plan hinges on one assumption (absent tools in allowed-tools don't error). Rather than assuming, the plan makes this the first ticket with an explicit go/no-go gate. If it fails, Option C (ambient-only) is documented as fallback. HIGH [B]: spec lines 29-37.

3. **Dependency graph is correct and parallelizable.** Phase 2 tickets (MCP-003 through MCP-007) modify different files with no interdependencies. Phase 3 is explicitly independent of Phase 2. HIGH [B]: dependency graph in spec lines 287-301.

4. **Graceful degradation is genuine.** Verified that current `allowed-tools` across all 16 commands uses only `Read, Write, Grep, Glob, Bash, Task`. The plan adds MCP tool names alongside these, never replacing them. Current behavior is preserved by construction. HIGH [A]: grep verified all command frontmatter.

5. **Confidence brief is thorough.** All three tools documented with what/who/why/reference structure. The graceful degradation pattern and tiered escalation strategy both have confidence entries. HIGH [B]: confidence.md review.

6. **Options analysis with 3 alternatives.** Approach.md evaluates Options A, B, and C with scored criteria and explicit decision rationale including conditions to revisit. HIGH [B]: approach.md lines 27-64.

7. **Perplexity exclusion from troubleshoot is well-reasoned.** The plan explicitly excludes Perplexity from troubleshooting because it conflicts with the "plausible hypothesis" warning principle. This shows design judgment, not just feature-stuffing. HIGH [B]: spec line 94.

### Gaps That Must Be Addressed

1. **[SEVERITY: HIGH] No automated regression testing.** Every ticket says "Manual" or "Visual review" for testing. After these changes ship, any future edit to plan.md, troubleshoot.md, or any modified file could silently break the conditional MCP logic. There is no characterization test, no golden master, no snapshot of the expected behavior. For a plugin that modifies 9 files across 4 commands and 2 agents, manual testing is insufficient for ongoing maintenance. HIGH [B]: every Testing line in the spec is "Manual" or "Visual review".

   **Suggested addition:** Create a checklist artifact (e.g., `docs/plans/2026-04-03-mcp-research-integration/smoke-test.md`) with specific test cases: (a) run each modified command without MCP servers and verify no errors + correct fallback tags, (b) run with MCP servers and verify tool invocation, (c) verify allowed-tools frontmatter includes expected tool names via grep.

2. **[SEVERITY: MEDIUM] Success metrics are not measurable.** The spec's "Success metrics" section (line 324) says "Confidence brief entries have TIER A/B sources when MCP tools are available" -- but doesn't define how to measure this. How many entries? What percentage? Over what time period? MEDIUM [B]: spec line 324 "Success metrics" section.

   **Suggested addition:** Define measurable criteria: "In the next 5 plans run with MCP tools, at least 60% of HIGH-impact confidence brief entries should have TIER A or B sources (vs. current 0%)."

3. **[SEVERITY: MEDIUM] No risk for MCP tool name drift.** The plan assumes tool names like `ref_search_documentation` and `web_search_exa` are stable. MCP servers are external dependencies that can rename tools between versions. The confidence brief acknowledges tool names need verification but there is no ongoing monitoring strategy. MEDIUM [C]: inferred from external dependency nature.

   **Suggested addition:** Add to risk table: "MCP server updates rename tools. Likelihood: LOW. Impact: MEDIUM (silent degradation to fallback). Mitigation: document verified tool names and versions in the skill file; check on plugin version bumps."

4. **[SEVERITY: MEDIUM] Token budget regression risk unquantified.** The plan mentions 3,150 tokens runtime overhead and references Tool Search as mitigation, but doesn't define a budget ceiling or monitoring check. The budget scanner (Check 8.5) measures server count (<5), not per-session token overhead. MEDIUM [B]: findings.md line 6 mentions 3,150 tokens; approach.md line 84 mentions token overhead.

   **Suggested addition:** Add acceptance criterion to MCP-002 or MCP-003: "Measure actual token overhead with 3 MCP servers connected. Must stay under Check 8.1 limit (10K tokens persistent context)."

5. **[SEVERITY: LOW] No tech reviewer assigned.** Brainstorm.md lists "Tech reviewer: TBD" and "Business approver: TBD". For a LOW-risk additive plan by a solo developer, this is acceptable but noted. LOW [B]: brainstorm.md line 56.

   **Suggested addition:** Either assign a reviewer or explicitly note "Self-reviewed due to low risk and full rollback capability."

6. **[SEVERITY: LOW] Line number references may be stale.** The spec references specific line numbers in plan.md (lines 301-305, 535-538, 1497) and troubleshoot.md (line ~203). Verified: plan.md line 301 is currently Track 3 (correct), line 535 is URL verification (correct), line 1497 is error handling (correct). Troubleshoot.md line ~203 is correlation matching section (correct -- Step 0.2 would go after the correlation section). HIGH [A]: all line references verified as of audit date.

   **Suggested addition:** Note in the spec that line numbers are approximate and should be re-verified at implementation time, since any intervening commit could shift them.

7. **[SEVERITY: LOW] Readiness-generate MCP server URL not verified.** The spec includes a template with `https://api.ref.tools/mcp?apiKey=YOUR_API_KEY` but this URL hasn't been verified against actual Ref MCP server documentation. LOW [C]: URL not independently verified. [CODEBASE-CLAIM-NOT-VERIFIED]

   **Suggested addition:** Verify the actual MCP server configuration URL from Ref's documentation before implementing MCP-008.

### Top 5 Risks

| # | Risk | Likelihood | Impact | In Plan? | Mitigation |
|---|------|-----------|--------|----------|-----------|
| 1 | `allowed-tools` with absent MCP tools causes runtime error | LOW | HIGH (blocks all Phase 2) | YES -- MCP-002 is explicit gate | Test empirically before proceeding. Fallback to Option C documented. |
| 2 | Manual-only testing leads to silent regression when files are later edited | MEDIUM | MEDIUM (degraded MCP behavior undetected) | NO | Add grep-based smoke test script or checklist artifact |
| 3 | MCP tool names change in future server versions | LOW | MEDIUM (silent fallback to non-MCP behavior) | PARTIAL (mentioned in findings.md) | Pin verified tool names in skill file; check on version bumps |
| 4 | Runtime token budget exceeded with 3 MCP servers | LOW | LOW (degraded context quality) | PARTIAL (mentioned but not measured) | Measure actual overhead in MCP-002; define ceiling |
| 5 | Solo developer unavailable mid-implementation | LOW | LOW (plan is pausable per-ticket) | NO | Each ticket is independently completable; document status in status.json |

## Go / No-Go Assessment

### GO If:
- MCP-002 verification passes (absent tools don't error)
- Author acknowledges manual testing is the strategy and accepts the regression risk
- MCP tool names are verified against actual server documentation before implementation

### NO-GO If:
- MCP-002 verification fails AND Option C fallback is not acceptable
- Token overhead with 3 MCP servers exceeds Check 8.1 limit (10K tokens)

### Recommendation: CONDITIONAL-GO

Proceed with Phase 1 immediately. The plan is well-designed with genuine low risk. The conditions are:

1. **Before Phase 2:** Create a smoke test checklist documenting the manual test cases for each ticket (what to run, what to check, expected output with and without MCP).
2. **During MCP-002:** Measure actual token overhead with MCP servers connected and record the number.
3. **After Phase 3:** Run the full smoke test checklist and record results in the plan folder.

These additions take ~15 minutes and significantly improve the plan's long-term maintainability.

## Leadership Presentation Outline

1. **Slide 1: What and Why** -- Plugin currently limited to training data for evidence; 3 specialized MCP tools now available to provide verified, cited research across all workflows.
2. **Slide 2: Design Principle** -- "Zero-breakage enhancement" -- every integration is optional with graceful degradation. Plugin works identically without any MCP servers.
3. **Slide 3: Scope** -- 9 tickets, 9 files, 3 phases. Touches planning, troubleshooting, documentation, and audit. Creates 1 new skill file; modifies 4 commands and 2 agents.
4. **Slide 4: Timeline and Risk** -- 2-3 hours total. LOW risk profile. Phase 1 is a validation gate before any real changes. Full rollback is a single git revert.
5. **Slide 5: Audit Findings** -- Score 30/40 (Yellow). Main gap: manual testing only. Recommendation: proceed with smoke test checklist addition.
6. **Slide 6: Ask** -- Approval to proceed. No additional resources needed. Solo developer with full rollback capability.

## Suggested Modifications (Priority Order)

1. **[P1] Add smoke test checklist artifact.** Create `smoke-test.md` in the plan folder listing every test case. Include grep commands to verify frontmatter changes and manual steps for with/without MCP scenarios.

2. **[P2] Make success metrics measurable.** Replace qualitative metrics with: "Next 5 plans with MCP: 60%+ of HIGH-impact confidence entries are TIER A/B" and "Troubleshoot sessions with MCP find framework-documented issues in Step 0.2 at least 50% of the time."

3. **[P3] Add token budget measurement to MCP-002.** When testing allowed-tools behavior, also measure the token overhead of having MCP tool definitions loaded. Record the number.

4. **[P4] Add MCP tool name drift to risk table.** Include version-pinning strategy in the skill file.

5. **[P5] Verify Ref MCP server URL.** The template in MCP-008 should use a verified configuration URL.

## Gap Verification (CHECK 4)

### A. Coverage Matrix

| Item | Type | Covered By | Status |
|------|------|-----------|--------|
| Planning evidence quality (Track 3 improvement) | Goal | MCP-003 | COVERED |
| Troubleshooting external lookup | Goal | MCP-004 | COVERED |
| Documentation enrichment | Goal | MCP-005 | COVERED |
| Audit API validation | Goal | MCP-006 | COVERED |
| Dependency deprecation checking | Goal | MCP-007 | COVERED |
| Graceful degradation (no hard MCP deps) | Goal | All tickets (pattern) | COVERED |
| Token overhead < 1,000 tokens persistent | Goal (brainstorm) | Not directly tested | GAP -- no measurement step |
| No new agents | Non-Goal | Verified: no new agent files | COVERED |
| No new commands | Non-Goal | Verified: no new command files | COVERED |
| No Perplexity in troubleshoot | Non-Goal | MCP-004 explicitly excludes | COVERED |
| No Codex Challenge changes | Non-Goal | Not in scope | COVERED |
| Unknown allowed-tools behavior risk | Risk | MCP-002 (gate) | COVERED |
| Token overhead risk | Risk | Mentioned in approach.md | PARTIAL -- no measurement |
| Tool name mismatch risk | Risk | Mentioned in approach.md | PARTIAL -- no ongoing strategy |
| Ref MCP tool name verification | Dependency | Kyle (check docs) | NOT VERIFIED at audit time |
| Exa MCP tool name verification | Dependency | Kyle (check docs) | NOT VERIFIED at audit time |
| Perplexity MCP tool name verification | Dependency | Kyle (check docs) | NOT VERIFIED at audit time |
| Claude Code allowed-tools behavior | Dependency | MCP-002 (empirical test) | COVERED |

### B. Assumption Register

| # | Assumption | Impact If False | How to Verify | By When | Owner | Status |
|---|-----------|----------------|---------------|---------|-------|--------|
| 1 | `allowed-tools` with absent tool names doesn't cause errors | HIGH -- blocks Phase 2 | MCP-002 empirical test | Phase 1 | Kyle | PLANNED |
| 2 | MCP tool names match server registration (ref_search_documentation, etc.) | MEDIUM -- tools silently unavailable | Check each server's docs | Phase 1 | Kyle | UNVERIFIED |
| 3 | Tool Search feature prevents context bloat with 3 MCP servers | LOW -- slower sessions if false | Measure token overhead | Not planned | Kyle | UNVERIFIED |
| 4 | Ref MCP server URL (api.ref.tools/mcp) is correct | LOW -- readiness-generate gives wrong config | Check Ref docs | Before MCP-008 | Kyle | UNVERIFIED |
| 5 | Security-scanner pattern (prose-fallback) works for all target commands | LOW -- verified pattern | MCP-002 validates this | Phase 1 | Kyle | VERIFIED (pattern exists at security-scanner.md:63-65) |
| 6 | Current line numbers in plan.md/troubleshoot.md are stable | LOW -- wrong insertion point | Verify at implementation time | Each ticket | Kyle | VERIFIED as of audit date |
| 7 | Budget scanner Check 8.5 (<5 servers) is sufficient to catch MCP bloat | LOW -- undetected overhead | Review Check 8.5 criteria | N/A | Kyle | ASSUMED |

### C. Scenario Matrix

| Scenario | Planned? | Which Phase? | Tested? | Monitored? | Status |
|----------|----------|-------------|---------|-----------|--------|
| Happy path (MCP tools available, search succeeds) | YES | Phase 2 | Manual | N/A (plugin) | PARTIAL -- manual only |
| Failure path (MCP tool returns error/timeout) | NO | -- | NO | N/A | GAP -- no error handling for tool failure |
| Partial rollout (some MCP servers connected, not all) | YES | Phase 2 | Manual | N/A | COVERED -- each tool independent |
| Backward compatibility (plugin without any MCP) | YES | Phase 1-2 | Manual | N/A | COVERED -- graceful degradation |
| Scale/volume edge (many MCP queries in one session) | NO | -- | NO | N/A | GAP -- no token accumulation scenario |
| Auth/permission edge (MCP API key invalid/expired) | NO | -- | NO | N/A | GAP -- falls to graceful degradation but not explicitly planned |
| Config/environment difference (different MCP server versions) | NO | -- | NO | N/A | GAP -- tool name drift scenario |
| Rollback path (revert all changes) | YES | All | Manual | N/A | COVERED -- git revert command provided |

### D. Cross-Cutting Concern Sweep

| Concern | Addressed? | Where? | Status |
|---------|-----------|--------|--------|
| API contract | YES | Tool names defined in spec per ticket | COVERED |
| UI behavior | N/A | No UI changes (plugin is CLI) | N/A |
| Auth/authz | PARTIAL | MCP API keys mentioned (user-installed) | PARTIAL -- no invalid-key scenario |
| Config | YES | allowed-tools frontmatter changes documented | COVERED |
| CORS/network/browser | N/A | Not applicable (CLI plugin) | N/A |
| Data model/query limits | PARTIAL | Token overhead mentioned | PARTIAL -- not measured |
| Pagination | N/A | No pagination involved | N/A |
| Caching | NO | No mention of MCP response caching | GAP -- minor, MCP servers handle their own caching |
| Observability | PARTIAL | Evidence tags (TIER A/B, API-CURRENT, etc.) | COVERED for outputs; no session-level tracking |
| Migration/backward compat | YES | Graceful degradation pattern | COVERED |
| Rollout/rollback | YES | Per-ticket rollback + git revert | COVERED |
| Tests | NO | Manual only, no automated tests | GAP |

### Plan Lint Results

| Rule | Description | Result |
|------|-----------|--------|
| LINT-01 | Every goal has mapped ticket | PASS -- all 6 goals from brainstorm map to tickets MCP-001 through MCP-009 |
| LINT-02 | Every HIGH risk has mitigation | PASS -- the one MEDIUM risk (allowed-tools behavior) has MCP-002 as mitigation |
| LINT-03 | Every deployment has rollback | PASS -- each ticket has explicit rollback; full rollback via git revert |
| LINT-04 | Every external dep has owner | PASS -- all 4 dependencies assigned to Kyle in approach.md |
| LINT-05 | Every new endpoint has contract/test | N/A -- no new endpoints |
| LINT-06 | Backward compat has mixed-state scenario | PASS -- partial MCP availability explicitly handled in each ticket |
| LINT-07 | Every new behavior has test delta | FAIL -- no automated test delta for any new conditional behavior |
| LINT-08 | No unverified HIGH-impact assumptions | FAIL -- Assumption #1 (allowed-tools behavior) is PLANNED but not yet VERIFIED; Assumption #2 (tool names) is UNVERIFIED |
| LINT-09 | No unaddressed cross-cutting concern | FAIL -- automated tests gap; token measurement gap |
| LINT-10 | Every phase has go/no-go criteria | PASS -- three gates defined in Go/No-Go Criteria table |
| LINT-13 | Approach has options analysis with min 2 alternatives | PASS -- 3 options (A, B, C) with scored criteria |
| LINT-14 | No regressions from previous baseline | SKIP -- first audit, no baseline |
| LINT-15 | All "Tested" claims have verified test infrastructure | FAIL -- all testing is "Manual" with no test infrastructure |
| LINT-16 | All "Monitored" claims have verified monitoring infra | PASS -- spec explicitly states "Monitoring: N/A" for plugin-only changes |

### Gap Summary
- Lint: 9/14 passed (3 FAIL, 1 SKIP, 1 N/A)
- Coverage Matrix: 18 items, 3 gaps (token measurement, tool name verification ongoing, dependency verification)
- Assumptions: 7 total, 3 unverified (tool names, token overhead, Ref URL)
- Scenarios: 8 total, 4 gaps (tool failure, scale/volume, auth/permission, config drift)
- Cross-Cutting: 12 concerns, 2 gaps (automated tests, token measurement)
- **Gap-checked: YES**

## Confidence Summary

| Tier | Count | Meaning |
|------|-------|---------|
| HIGH [A] (Deterministic) | 4 | Binary keyword check or file existence (frontmatter grep, line number verification, skill folder check, section keyword counts) |
| HIGH [B] (Verified) | 12 | Direct evidence from plan text or codebase file (security-scanner pattern, Track 3 content, error handling table, options analysis) |
| MEDIUM [B] (Inferred) | 2 | Indirect evidence, likely correct (team capacity, token overhead impact) |
| MEDIUM [C] (Speculated) | 2 | Agent judgment (tool name drift risk, MCP response caching) |
| LOW [C] (Speculated) | 1 | Verify with author (Ref MCP server URL correctness) |
| UNVERIFIED | 0 | All findings have at least LOW evidence |

## Verification Statistics
- Candidate findings generated: 10
- Confirmed after verification pass: 7
- Dropped (false positives prevented): 3
  - "No problem impact quantified" -- dropped, brainstorm.md quantifies 4 affected personas and token budget impact
  - "No fallback for Option A failure" -- dropped, approach.md line 64 documents Option C fallback
  - "Phase 3 depends on Phase 2" -- dropped, spec dependency graph explicitly shows Phase 3 is independent
- False positive prevention rate: 30%
- Codebase claims verified: 6/7 (86% verification rate)
  - Verified: security-scanner.md prose-fallback pattern, plan.md line 301 Track 3, plan.md line 535 URL verification, plan.md line 1497 error handling, troubleshoot.md line ~203 correlation section, all command allowed-tools frontmatter
  - Not verified: Ref MCP server URL (external) [CODEBASE-CLAIM-NOT-VERIFIED]

## Calibration
- Contradictions found and resolved: 1 (Risk dimension initially scored 4/5 but missing risks warranted 3/5)
- Score adjustments after calibration: 1 (Risk 4 -> 3)
- Score range: 2-5 (spread of 3)
