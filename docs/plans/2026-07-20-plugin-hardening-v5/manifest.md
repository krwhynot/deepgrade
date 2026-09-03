# Plan: Plugin Hardening v5

Created: 2026-07-20
Status: Phase 5 - Audit (current approach version and round state are authoritative in `approach.md`'s header and `status.json` — this line is deliberately version-agnostic after going stale twice)
Owner: Kyle (repo owner, `krwhynot`)
Mode: solo
Target release: **5.0.0**

**Objective:** Close the 33 in-scope conformance and correctness defects found by the structural
audit of `toque-plugin` v4.31.0 and `troubleshooting-skill` against the official Claude Code
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
| [G0 probe results — lane N selected, U6 settled](research/g0-probe-results.md) | 6 (Wave 0) | 2026-07-29 |
| [Validator scope probe — U1, later superseded by the Codex audit](research/validator-scope-probe.md) | 6 (Wave 2) | 2026-07-29 |
| [Hook adversarial review — 6 confirmed defects incl. an arbitrary write](research/hook-adversarial-review.md) | 6 (Wave 4) | 2026-07-29 |
| [Codex setup-audit prompt (scoped to Claude Code setup conformance)](codex-setup-audit-prompt.md) | 6 | 2026-07-29 |
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
| [CR-3](changes/CR-3.md) | 2026-07-29 | **ACCEPTED.** Extends acceptance row A1 from `*.sh` to also cover `*.js`: G0 selected lane N, so the hook guards are now node scripts, and `.gitattributes`'s own rationale ("the hook guards and the test suite are shell scripts") is no longer true of the tree. **Severity revised UPWARD at ratification, against the proposal's own text:** the falsifying control (clone HEAD with `core.autocrlf=true`) showed `file` reporting both `scripts/tq-git-guard.js` and `tests/codex-challenge-test.js` as "Node.js script **executable** … with CRLF line terminators" while the `.sh` beside them stayed clean — they carry a shebang and exec bit, so direct POSIX execution fails with `env: 'node\r'`, and `codex-challenge-test.js` runs Layer 5's 41 assertions. Comparable to CR-2, not below it. Only the shipped hook invocation (`node scripts/tq-*.js`) is genuinely unaffected. Guarded in `layer1` §14 via `git check-attr` with a derived-subject floor, plus a stale-rationale check |
| [CR-2](changes/CR-2.md) | 2026-07-29 | **ACCEPTED.** Supersedes acceptance-matrix row A1 on two points: (1) acceptance is the **fresh-clone working-tree check** — the `git ls-files --eol` clause reports `w/lf` with no `.gitattributes` at all and can never fail; (2) scope extends from `*.sh` to also cover `tests/fixtures/**`, since Layer 3 reads tab-separated fixture data where CRLF silently breaks every comparison (7/2 in a clean clone vs 9/0 locally) |

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
| 6. Build | **In Progress — Wave 0 (3 of 5) + Waves 1, 2, 3 COMPLETE.** **Wave 2 (2026-07-29): F02, F03, F07, F21, F27, F32 closed.** Every agent's `tools:` allowlist now matches what its own body requires; `Edit` deliberately granted to none. **U1 RESOLVED-NEGATIVE** (`research/validator-scope-probe.md`): `claude plugin validate --strict` does not read agent frontmatter at all — it passes on an agent whose `name:` line has been deleted — so the whole agent/command frontmatter defect class (F01, F02, F03, F07, F17, F21, F27) is invisible to it and `tests/layer1-config-wiring.sh` is its sole guard. Suite **115/4 → 156/4 → 167 → 172 → 183 pass / 0 fail**; 11 new assertions this wave, 13/13 mutations caught; `expected-failures.txt` **empty**. Earlier waves: **G0 RESOLVED → lane N (node-canonical); U6 resolved (notice user-visible, CR-1 stands); G1 = CI_ONLY** — lanes B/I not needed, Wave 4 unblocked; 22 sources snapshotted + hashed; clean-clone verified. **Findings closed: 14 of 33** — F01, F02, F03, F04, F07, F17, F18, F19, F20A, F21, F27, F29, F31, F32 — plus all 3 accepted scope additions and the `tools:` ride-along, so **18 of 36 in-scope items**. (Counted against `status.json`'s list; the figure carried here after Wave 1 read "10 of 33", which conflated findings with scope additions.) Remaining in Wave 0: PHV5-003 (U7 floor), PHV5-005 (CI matrix) — both need the owner |
| 7. Impact Review | Not Started |
| 8. Test | Not Started |
| 9. Handoff | Not Started |

## Source

Structural audit workflow `wf_f737844e-590` — 142 agents, 6 official-spec extractions, 8 component
auditors, adversarial verification on every finding (3-lens majority vote for critical/high).
88 raw confirmations → 65 unique findings; 4 candidates refuted. Audited at commit `4fb4b64`,
plugin v4.31.0, on 2026-07-19.

Full report artifact: https://claude.ai/code/artifact/e4bc2b83-7e5c-46d2-8ae5-a763cd8d831f
