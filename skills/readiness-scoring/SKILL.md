---
name: readiness-scoring
description: Knowledge about AI readiness scoring methodology, gate thresholds, confidence levels, and grading criteria. Auto-invoked when running readiness scans or interpreting readiness scores.
---

# AI Readiness Scoring Methodology

This skill contains the scoring rubric and methodology for Phase 1 AI Readiness scans.

## Grading Scale

| Grade | Score Range | Meaning |
|-------|-----------|---------|
| A+ | 97-100% | Exceptional. AI agents can work autonomously. |
| A | 93-96% | Excellent. Minor gaps only. |
| A- | 90-92% | Very good. A few improvements needed. |
| B+ | 87-89% | Good. Some gaps to address. |
| B | 83-86% | Above average. Several improvements needed. |
| B- | 80-82% | Adequate. Minimum for effective AI-assisted development. |
| C+ | 77-79% | Below target. Significant gaps. |
| C | 73-76% | Mediocre. Many improvements needed. |
| C- | 70-72% | Poor. Major gaps in AI readiness. |
| D+ | 67-69% | Very poor. Fundamental issues. |
| D | 63-66% | Failing. Most gates not met. |
| F | Below 63% | Not ready for AI-assisted development. |

## Nine Scoring Gates

Each gate has a max score. All gates use deterministic bash commands for measurement.

1. **Manifest** (max 9): Package manifest completeness
2. **Context Files** (max 10): CLAUDE.md and AI context quality
3. **Structure** (max 8): Directory organization and co-location
4. **Entry Points** (max 6): Startup and routing clarity
5. **Conventions** (max 13): Naming, linting, formatting consistency
6. **Feedback Loops** (max 11): CI/CD, hooks, test automation
7. **Baselines** (max 6): Audit baseline files present
8. **Context Budget** (max 13): Instruction efficiency
9. **Database** (max 14): Schema docs, migrations, connection patterns

## Confidence Thresholds

| Confidence | Meaning | Action |
|-----------|---------|--------|
| >= 0.90 | High. Proceed with findings. | Generate report. |
| 0.80-0.89 | Medium. Some uncertainty. | Offer deep scan option. |
| < 0.80 | Low. Significant gaps in analysis. | Flag for human review. |

## Key Principle: Deterministic Scoring

All checks use bash commands with explicit variable comparisons. No room for
agent interpretation. If a check produces a number, the score is determined by
fixed thresholds, not by judgment.
