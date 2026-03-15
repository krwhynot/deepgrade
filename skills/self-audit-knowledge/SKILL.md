---
name: self-audit-knowledge
description: (deepgrade) Knowledge about LLM epistemic transparency, claim verification tiers, failure mode flags, cascade risk classification, and evidence basis formatting. Auto-invoked during codebase audits, plan audits, and report generation.
---

# LLM Self-Audit Framework

This skill defines how DeepGrade agents communicate the epistemic basis of
their findings. It ensures audit reports explicitly state which claims are
tool-verified vs. inferred, flag known LLM failure patterns, and score
cascade risk.

## Section A: Claim Verification Tiers

Every finding carries a verification tier indicating how the claim was derived:

- **Tier A (Tool-Verified):** Claims confirmed by deterministic tool output —
  glob matches, grep results, `wc -l` counts, manifest parsing. Near-zero
  hallucination risk. Always HIGH confidence unless truncated (flag
  `[ENUMERATION-MAY-BE-INCOMPLETE]`).

- **Tier B (Code-Reading):** Claims about runtime behavior, control flow, side
  effects derived from reading source files via Read tool. Moderate hallucination
  risk. Confidence depends on full-file vs. partial read.

- **Tier C (Pattern Inference):** Claims assembled from naming conventions,
  directory structure, file adjacency, or LLM reasoning. Highest hallucination
  risk. Always MEDIUM or LOW confidence.

## Section B: Evidence Basis Format

Findings use the format: `{Tier}-{Confidence}: {one-line verification method}`

Examples:
- `A-HIGH: glob matched 14 files with payment patterns`
- `B-MEDIUM: read primary handler, did not trace all call sites`
- `C-LOW: inferred from directory name "payments/" without reading contents`

## Section C: Failure Mode Flags (inline tags)

- `[ENUMERATION-MAY-BE-INCOMPLETE]` — list/count may have been truncated
- `[INFERRED-FROM-NAMING]` — conclusion from naming patterns, not code reading
- `[SIDE-EFFECTS-NOT-TRACED]` — primary behavior documented, cascades may be missing
- `[DEAD-CODE-UNCERTAIN]` — cannot confirm if code path is reachable

Plan audit failure mode flags (for plan-auditor and plan-scaffolder):
- `[PLAN-GAP-INFERRED]` — gap detected by absence of keywords, not by understanding plan intent
- `[SCOPE-ASSUMED]` — auditor assumed scope beyond what the plan explicitly states
- `[CODEBASE-CLAIM-NOT-VERIFIED]` — plan references code that the auditor couldn't verify

## Section D: Cascade Risk Levels

Assignment is **category-based, not count-based**. Numeric fan-out is unreliable —
a setter touching 3 files can break an entire UI flow, while a utility with 10
dependents may be cosmetic.

**Always CASCADE (regardless of fan-out count):**
- Anything touching auth/security paths
- Anything touching payment flows
- Anything touching required-mod / state mutation flows
- Any finding another scanner consumed as input (e.g., risk-assessor used
  dependency-mapper's fan-in)

**COVERAGE** — scope/completeness claim; if wrong, silent gaps in analysis

**CONTAINED** — self-contained finding; if wrong, affects only itself

A `[SEVERITY-OVERRIDE]` flag may be applied to force CASCADE on any finding where
the orchestrator determines the domain warrants it, even if it doesn't match the
categories above.

## Section E: The [VERIFIED] Re-Audit Rule

Any finding tagged HIGH confidence or [VERIFIED] becomes a *priority target* for
spot-checking during Phase 3 cross-validation. Rationale: high-confidence
hallucinations are the most dangerous failure class.

## Section F: Report Confidence Thresholds

- If >30% of findings are Tier C, downgrade overall report confidence one level
- If any HIGH-confidence finding fails spot-checking, review ALL findings from
  that scanner
- CASCADE + Tier C is the most dangerous combination — always spot-check these
