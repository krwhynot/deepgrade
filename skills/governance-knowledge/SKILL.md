---
name: governance-knowledge
description: Knowledge about enterprise governance patterns, DORA metrics, quality gates, confidence decay, delta tracking, and characterization testing. Auto-invoked during delta scans, gate setup, security scans, and characterization test generation.
---

# Enterprise Governance Knowledge

This skill contains methodology and best practices for Phase 3 governance
components of the DeepGrade Developer Toolkit.

## DORA Metrics (DevOps Research and Assessment)

The four key metrics for software delivery performance:

| Metric | Elite | High | Medium | Low |
|--------|-------|------|--------|-----|
| Deployment Frequency | On-demand (multiple/day) | Weekly-monthly | Monthly-biannual | Biannual+ |
| Lead Time for Changes | <1 hour | 1 day-1 week | 1-6 months | 6+ months |
| Change Failure Rate | <5% | 5-10% | 10-15% | 15%+ |
| Mean Time to Recovery | <1 hour | <1 day | 1 day-1 week | 1+ week |

Source: DORA 2025 Report. 90% of developers now use AI tools daily.
Key finding: AI increases deployment frequency and reduces lead time,
but change failure rate RISES without quality gates.

## Confidence Decay Rules

Audit findings lose confidence over time if not re-verified:

| Days Since Verification | Status | Confidence Effect |
|------------------------|--------|-------------------|
| 0-30 | Fresh | No change |
| 31-60 | Aging | Downgrade one tier (HIGH to MEDIUM) |
| 61-90 | Stale | Downgrade two tiers (HIGH to LOW) |
| 91+ | Expired | Tag [REQUIRES RE-SCAN] |

Rationale: Codebases change. A finding from 90 days ago may no longer
be accurate. The decay forces periodic re-verification.

## Quality Gate Patterns

### SCAN Pipeline (from CodeIntelligently, 2026)
Four-stage quality gate for AI-generated code:
1. Static Checks (~30 sec): Placeholders, console.log, new dependencies
2. Context Matching (~2 min): Pattern conformance to architecture
3. Deep Analysis (~5 min): AI reviews AI with architecture context
4. Notification (~10 sec): Format and post results to PR

Teams with quality gates caught 73% more issues before production.
Human review time dropped 42%.

### Advisory Mode
New quality gates should start in WARNING mode for 2 weeks.
This builds trust and lets you tune false positives before blocking.
After 2 weeks, switch to blocking mode if false positive rate is <15%.

### Escape Hatches
Every blocking gate must have an override mechanism:
- PR label: "skip-risk-check" for emergencies
- Documented in gate-config.md with rationale requirement

## Characterization Testing

### Golden Master Pattern
1. Capture current behavior as test assertions
2. Tests document what code DOES, not what it SHOULD do
3. After refactoring, same tests verify behavioral parity
4. If test fails, refactored code behaves differently

### When to Use
- Before extracting functions from monolith files
- Before migrating VB.NET to C#
- Before upgrading frameworks or dependencies
- Before any change to code with zero existing test coverage

### Non-Testable Functions
Legacy code often can't be unit tested due to:
- Direct database access with no abstraction
- UI state dependencies (WinForms controls)
- Static/singleton state that can't be reset
- COM object dependencies

For these, use:
- Integration test stubs (with Skip attribute)
- Manual test scripts (markdown checklists)
- Documented behavioral contracts

## Delta Tracking

### What to Measure
Quick measurements (no full re-scan needed):
- Monolith file count and largest file LOC
- Test file count and ratio
- CRITICAL findings still open
- HIGH-risk module count
- Days since last full scan

### When to Re-Scan
- After completing a Phase 2 recommendation
- After extracting functions from a monolith
- After adding significant test coverage
- When stale findings exceed 5
- When days since last scan exceeds 30

## Security as Separate Loop

Security scanning must be independent from code review:
- Run SAST tools regardless of PR size or risk level
- Dependency scans on every build (not just PRs)
- Secrets scanning catches credentials before commit
- SSL/TLS verification prevents transport downgrades

"Keep security as a separate control loop: SAST, dependency scans,
secrets scanning, not 'looks fine.'" (CodeGeeks, 2026)
