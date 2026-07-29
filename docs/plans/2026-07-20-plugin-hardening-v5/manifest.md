# Plan: Plugin Hardening v5

Created: 2026-07-20
Status: Phase 5 - Audit (current approach version and round state are authoritative in `approach.md`'s header and `status.json` — this line is deliberately version-agnostic after going stale twice)
Owner: Kyle (repo owner, `krwhynot`)
Mode: solo
Target release: **5.0.0**

**Objective:** Close the 33 in-scope conformance and correctness defects found by the structural
audit of `deepgrade-plugin` v4.31.0 and `troubleshooting-skill` against the official Claude Code
plugin/skill specification, so that every component the plugin advertises actually loads and runs.

## Plan Files (this folder)

| File | Phase | Created |
|------|-------|---------|
| [Brainstorm](brainstorm.md) | 1 | 2026-07-20 |
| [Reference data (33 in-scope + 32 backlog findings)](research/reference-data.json) | 1 | 2026-07-20 |
| [Research synthesis](research/findings.md) | 2 | 2026-07-20 |
| [Codebase scan (finding re-verification)](research/codebase-scan.md) | 2 | 2026-07-20 |
| [Test baseline](research/test-baseline.md) | 2 | 2026-07-20 |
| [Best practices (5 open questions)](research/best-practices.md) | 2 | 2026-07-20 |
| [Approach — SCOPE LOCK (current version and round history in its own header/§11)](approach.md) | 3 | 2026-07-20 |
| [Acceptance matrix — authoritative item→wave→files→tests](acceptance-matrix.md) | 3 | 2026-07-20 |
| [Consistency sweep — scripted Phase 3 gate (§10.5)](consistency-sweep.sh) | 3 | 2026-07-21 |
| [Confidence brief (10 entries)](confidence.md) | 3+5 | 2026-07-20 |
| [Codex audit prompt (copy-paste)](codex-audit-prompt.md) | 3 (pre-lock review) | 2026-07-20 |
| [Codex review report — all rounds, gap logs + provenance (scores in its own header)](codex-review.md) | 3 (pre-lock review) | 2026-07-20 |
| [Audit — 34/40 GREEN, gap-checked, 15/15 lint](audit.md) | 5 | 2026-07-29 |
| [Impact Review](impact-review.md) | 7 | Pending |
| [Test Plan](test-plan.md) | 8 | Pending |

## Project Documents (in docs/)

| Document | Type | Path | Created |
|----------|------|------|---------|
| [Spec: plugin-hardening-v5 (3 views: tickets, leadership, checklist)](../../specs/plugin-hardening-v5.md) | Spec (Phase 4) | docs/specs/plugin-hardening-v5.md | 2026-07-29 |

## Change Records

| CR | Date | Summary |
|----|------|---------|
| [CR-1](changes/CR-1.md) | 2026-07-21 | Owner **accepted** the weaker lane-N node-less signal (vendor hook-error notice), conditional on U6 proving its visible form; supplementary-warning and demote-lane-N alternatives declined |

## Codebase Files

| File | Type | Created |
|------|------|---------|
| (none yet) | | |

## Progress

| Phase | Status |
|-------|--------|
| 1. Brainstorm | Complete |
| 2. Research | Complete — stop rubric passed |
| 3. Pre-Plan | **Complete (2026-07-29).** Adversarial review PASSED — GO (Codex, perfect score; details in `codex-review.md` and `status.json`); owner signed off; plan directory committed at `0b72995` |
| 4. Plan | **Complete (2026-07-29)** — spec confirmed at the Phase 4 gate (33 tickets, 9 waves, est. 28–34 working days incl. buffer) |
| 5. Audit | **Complete (2026-07-29) — 34/40 GREEN, gap-checked YES, lint 15/15, zero regressions** (v1 30/40 → auto-revised → v2 34/40). Human-review gate is the next step |
| 6. Build | Not Started |
| 7. Impact Review | Not Started |
| 8. Test | Not Started |
| 9. Handoff | Not Started |

## Source

Structural audit workflow `wf_f737844e-590` — 142 agents, 6 official-spec extractions, 8 component
auditors, adversarial verification on every finding (3-lens majority vote for critical/high).
88 raw confirmations → 65 unique findings; 4 candidates refuted. Audited at commit `4fb4b64`,
plugin v4.31.0, on 2026-07-19.

Full report artifact: https://claude.ai/code/artifact/e4bc2b83-7e5c-46d2-8ae5-a763cd8d831f
