# Spec: Plugin Hardening v5 — Execution Plan

Created: 2026-07-29 (Phase 4) · Plan: [`plugin-hardening-v5`](../plans/2026-07-20-plugin-hardening-v5/manifest.md)
Derived from: [`approach.md`](../plans/2026-07-20-plugin-hardening-v5/approach.md) **v17** (scope lock, Codex GO 40/40, round 17) ·
[`acceptance-matrix.md`](../plans/2026-07-20-plugin-hardening-v5/acceptance-matrix.md) (per-item acceptance, authoritative)
Baseline: audit commit `4fb4b64` (plugin v4.31.0, code untouched since) · plan committed at `0b72995` · target **v5.0.0**

> **Authority note.** This spec is an *execution rendering* of the locked scope. `approach.md` §9 remains the single
> sequencing authority and §10 the single acceptance authority; `acceptance-matrix.md` is authoritative per item.
> If this spec ever disagrees with them, they win, and the fix is a spec edit — never a scope reinterpretation.
> Changes to locked decisions require a Change Record (`changes/CR-N.md`).

**Scope (locked):** 36 items = 33 verified findings (F01–F33) + 3 accepted additions (`.gitattributes`, wire the
orphan Layer-5 suite, marketplace manifest conformance), plus 1 droppable ride-along (`tools:` style). Conditional
dispositions recorded, never silent: F24 **PARTIAL by design**; F23 **NOT MET under lane I only**; F26 PreCompact
half PARTIAL only if both empirical paths fail.

**Execution pattern (locked):** Strangler Fig with interleaved test harness, in dependency-ordered waves (Option A).
Expected lane: **N (node exec form)** — selected empirically by gate G0 in Wave 0; lanes B/I fully specified as
fallbacks with identical wave structure.

---

## View 1 — Jira-Ready Tickets

Ticket IDs are `PHV5-NNN` (tens digit = wave). Every ticket's **full acceptance criteria live in its
`acceptance-matrix.md` row**; the criteria below are the falsifiable core, not a replacement.
"Band" uses §9.3's verified sizing: trivial < 10 min · small < 1 h · medium = few hours · large = day+.

### Wave 0 — Harness + gates *(risk: HIGH — this wave resolves every open gate)*

Rollback: pure additions; revert any commit, nothing user-facing shipped.
Internal order is mandatory (§9): snapshots → conformance fixes → probes → **only then** enable CI.

**PHV5-001 — Snapshot the 22 pre-reconciliation sources (A4)** · Band: small · Blocks: PHV5-005, Wave 6
Import both sides of the 9 shared troubleshooting files (18) + 4 sibling-only files to
`docs/plans/2026-07-20-plugin-hardening-v5/snapshots/{plugin-side,skill-side}/`; record content hashes and the
authoritative diff count via the pinned command `git diff --no-index --numstat` (300 = 78 added + 222 deleted at
2026-07-20; re-measure at snapshot). AC: clean clone contains all 22 sources; the superseded 296 figure appears
nowhere as authoritative. **Must land before anything touches the sibling** (R11 — the sibling is unversioned;
drift has already occurred).

**PHV5-002 — Repo conformance batch (A1, A2, A3) + baseline record** · Band: small · Blocks: PHV5-005
- `.gitattributes` with `*.sh text eol=lf` — AC: `git ls-files --eol -- '*.sh'` reports `w/lf` for every script.
- Wire `tests/codex-challenge-test.js` into `run-all.sh` as **Layer 5** — AC: totals move **115/4 → 156/4** (§10.1);
  runner fails if any layer script is missing (layer-count assertion).
- `.claude-plugin/marketplace.json`: delete duplicate `version`, **add missing top-level `description`**
  (strict validation fails on it today, reproduced) — AC: dual-manifest `claude plugin validate --strict` passes.
- Record the exact baseline (115/4: L1 84/4 · L2 15 · L3 9 · L4 7) and commit `tests/expected-failures.txt`
  naming the 4 expected F18/F19 reds.

**PHV5-003 — U7 compatibility-floor discovery** · Band: medium · Blocks: PHV5-005
Local, authenticated, one-time. Binary-search installable `@anthropic-ai/claude-code` versions over
[~2.1.140 … 2.1.216], ≤8 probes, each installed isolated (`npm i --prefix <sandbox>`); exercise all **eight**
relied-upon behaviors: hooks-folder precedence · exec-form args · `${CLAUDE_PLUGIN_ROOT}` substitution ·
structured hook output · `validate --strict` · explicit `shell: powershell` selection · parallel matching-hook
execution · pinned-GitHub-source-object resolution. AC: committed `research/` artifact (candidate list,
per-behavior pass/fail, chosen floor); a floor asserted from documentation alone fails this row.

**PHV5-004 — G0 launcher probe + U6 recording + G1 state** · Band: small–medium · Blocks: PHV5-005, Wave 4
Probe plugin in scratchpad (never committed), one `SessionStart` handler writing a marker file; launch
`claude --plugin-dir <probe>` **from PowerShell, never Git Bash** (inherited-PATH trap, §3.1.1). Candidates in
order: (n) exec-form `node` → (s) shell form → (b) exec-form `bash`; absolute-interpreter run is diagnostic-only
and **can never PASS**. Record U6: what the client surfaces when an exec-form command cannot spawn, **including
the node-less case** (node hidden from PATH). Resolve G1 to exactly one terminal state
(POSIX_RUNTIME_VERIFIED | CI_ONLY default).
AC (per matrix Gates row): per-candidate fire/no-fire recorded in `research/`; lane-N PASS **additionally requires
the CR-1 condition — U6 shows the node-absent failure in a user-visible form**; if invisible → G0 = **BLOCKED**,
Wave 0 **pauses before PHV5-005**, Wave 4 does not start, and a new owner CR per CR-1 §Return path is required.

**PHV5-005 — Hosted CI matrix + expected-red comparator** · Band: medium–large · Depends: 001–004
`.github/workflows/`: `windows-latest` + `ubuntu-latest` × floor (U7) + current; each runs the full suite **and**
dual-manifest `claude plugin validate --strict`; non-blocking latest-version canary; lane-qualified
parser-degradation jobs (hide node/jq only for those cases); **no secrets in any required job** (fork-PR safe,
R15). Comparator: job passes **iff** the failure set equals exactly `tests/expected-failures.txt`;
`continue-on-error` prohibited. AC: no job depends on untracked local state (fresh checkout).

**Wave 0 go/no-go:** GO ⇔ G0 selected a lane (not BLOCKED) · U6 + U7 artifacts committed · G1 terminal state
recorded · CI green under the comparator · all 22 snapshots + hashes committed. BLOCKED ⇒ owner CR, work pauses.

### Wave 1 — Island + root *(risk: LOW · rollback: revert per commit)*

**PHV5-010 — F29 + F31: template phantom agents + dead commands** · Band: small
4 template files under `skills/documentation/resources/`. AC: every "Deploy the X agent" names an agent existing
in `agents/` (fails at HEAD on 4 names); no `/audit`, `/create-prd`, `/create-brd`, `/create-adr` — only
namespaced `/deepgrade:*` from the SKILL.md whitelist.

**PHV5-011 — F17: agent name/filename drift (atomic)** · Band: small
5 agent files + callers `readiness-scan.md`, `codebase-audit.md`. Frontmatter `name` == filename for every
`agents/*.md`, **moved together with all 5 caller lines** — the reverse sweep (every referenced agent resolves)
is the landmine test. Then **PHV5-012 — F01 duplicate agent name** (2 agent files + 2 callers): `name:` values
unique across `agents/`; both report pipelines reference distinct, existing agents. Band: trivial–small.

**Wave 1 go/no-go:** new Layer-1/G assertions green; no reverse-sweep failures.

### Wave 2 — Agent frontmatter *(risk: LOW–MEDIUM · rule: ONE edit per agent file, never five passes)*

**PHV5-020 — Frontmatter batch: F02, F03, F07, F21, F27 + `tools:` ride-along** · Band: small–medium
Per §3.4: strip bare MCP names (`ref_*`/`*_exa`/`perplexity_*`); keep closed `tools:` allowlists; add
`Bash`+`Write` (`doc-auditor`, `integration-scanner`), `Agent` (`plan-scaffolder`, `plan-auditor` — and **no other**
agent gains it), `Write` on the 13 agents mandating `docs/audit/` outputs (**no `Edit` anywhere**); every agent
referencing a knowledge skill preloads via `skills:` or lists `Skill`; normalize `tools:` flow arrays to
comma-separated. Custom grep guard required — `claude plugin validate` passes on bare names.

**PHV5-021 — F32: `skills/mcp-research/SKILL.md` convention** · Band: small
Skill states the suffix-match availability rule + qualified `mcp__<server>__<tool>` forms; no bare-name-equality
rule remains; **convention text matches F21's (same-string check) or the defect reships**.

**Wave 2 go/no-go:** frontmatter sweeps green; one-commit-per-file discipline visible in history.

### Wave 3 — Doc counts Pass A *(risk: LOW — clears the expected-red set)*

**PHV5-030 — F18 + F19 together** · Band: small
`CHANGELOG.md` entries for 4.30.0 + 4.31.0; README/help counts (knowledge-skills = 6; `README.md:160` "22 agents"
stays — it is correct). `layer1:248` cross-checks README↔CHANGELOG, so the pair is atomic. **Then empty
`tests/expected-failures.txt`** — CI becomes plainly green.
**PHV5-031 — F20A + F04** · Band: small — GUIDE version/counts/"9-phase"; update-flow docs: no "picks up changes
automatically", installs use `@deepgrade-marketplace`, live-edit only for `--plugin-dir`.

**Wave 3 go/no-go:** suite green with an **empty** expected-failures file (the 4 baseline reds cleared, no new ones).

### Wave 4 — Hooks epic *(risk: HIGH — security-behavior changes; lane known since Wave 0)*

Rollback: 4a is inert until 4b; 4b is **one commit** — single revert + `/reload-plugins` restores the old hooks.
Independent review (§10.4) runs **after 4c**, covering 4a–4c with runtime artifacts pinned.

**PHV5-040 — 4a: port + behavior ledger (lane N: 8 scripts → `scripts/dg-*.js`)** · Band: large (decomposed §9.3:
blocking guards medium + informational handlers medium + host/degradation proof small)
All 11 ledger rows (§3.1.4) satisfied in the surviving implementation — including row 1 (DB-deploy guard runs
**before** the non-git early-exit; `dg-git-guard.sh:27` pattern makes anything below it dead code), row 2
(backslash normalization), row 4 (SubagentStop — handler count becomes **8**), row 8 (tolerant read of both
tracker keys, §8.4). Per-row falsifying tests (e.g. `supabase db push` denied / `supabase db diff` allowed;
`DG_STRICT_GIT` default-off negative). Lane B alt: port rows 1–2 into `.sh` set. Lane I alt: consolidated inline
fixtures + quoting-lint test, **not yet in `plugin.json`**.

**PHV5-041 — 4a: parser contract F24 + F22 + F25 + F26 implementation** · Band: medium (inside 040's lane band)
§3.1.6 exactly: enforce only what is parsed; **never deny on an unparsed payload**; malformed payload under a real
parser → fail closed; no parser → allow + static JSON `systemMessage` (never stderr on exit 0). Test corpus:
the F24 reproduction (`git commit -m "wip" && git push --force` → denied via parsed `tool_input.command`),
cross-field decoys (danger string only in `description`/`content` → allowed), quoted-text mentions → allowed,
exemption-position cases (`--force-with-lease`/`--dry-run` honored only inside the command field). F22:
`git reset --hard` → `permissionDecision:"ask"`, exit 0. F25: `--force-with-lease` allowed; `--force`/bare `-f`
denied. F26: all exit-0 output is JSON (settles U4); PreCompact fallback chain locked (§3.1.6).
Lane-qualified states: lane N = node-present (unit/CI) + node-absent (**local 4c evidence only — never a CI
assertion**); lanes B/I = jq-only / node-only / neither.

**PHV5-042 — 4a: Layer 2 rewrite** · Band: medium
`tests/layer2-hook-simulation.sh`: no positional-index extraction; every guard case runs the lane's unit-coverable
state set; delete the old `exit 2` + stderr-"WARNING" assertion (it enshrined F22).

**PHV5-043 — 4b: activation, ONE commit** · Band: small · Depends: 040–042 green
Lanes N/B: create `hooks/hooks.json`, **delete the inline `hooks` key in the same commit** (with both present the
folder is silently ignored), SubagentStop entry, update `layer1:111`, `:120-121`, `:265`, `README.md:84`
("Safety Hooks (7)" → 8), `GUIDE.md:5` — ~8 files. Lane I: swap proven handlers into `plugin.json`, delete
`scripts/`. **4b activates what 4a proved; it authors no new logic.**

**PHV5-044 — 4c: runtime proof (Layer 7)** · Band: medium first run · Depends: 043
`tests/layer7-runtime-proof.sh`: every shipped event **and** matcher observed firing (1) via `claude --plugin-dir`
and (2) from an **installed copy** on the §8.5 scratch channel — including the **node-less installed-copy case**
(lane N: vendor hook-error notice only, per CR-1; lanes B/I: bash handler's systemMessage). F26 visibility verified
live (settles U5; locked fallback if negative). Zero hook errors on healthy supported hosts.

**PHV5-045 — Wave 4 independent review (§10.4)** · Band: medium + small–medium remediation · Depends: 044
Non-Claude model family; input = pinned merge-candidate SHA + diff + approach.md + matrix rows + **4c runtime
artifacts**; output = committed `reviews/wave-4-round-M.md`; pass = explicit GO + zero unresolved critical/major;
max 2 rounds, then owner accept/override recorded as a CR **and named in the release notes** (R13).

**Wave 4 go/no-go:** GO ⇔ 4a suite green in lane states · 4b single activation commit · 4c both proof surfaces
observed (incl. node-less case) · review GO artifact committed. NO-GO on any review critical/major.

### Wave 5 — Command hygiene *(risk: MEDIUM · rollback: revert per commit)*

**PHV5-050 — Portability batch: F09, F10, F11, F13, F15** · Band: small each
`quick-cleanup.md` (no `$1` in bash blocks; **zero-arg case degrades safely** — negative test required),
`plan-export.md` (`${CLAUDE_PROJECT_DIR}`; `zip` with `Compress-Archive` fallback), `readiness-generate.md`
(no `/ai-readiness-*`; `argument-hint`; **no `tree` usage** — `tree -d -L 2` at `:61` is live today),
`plan-status.md` (guard tests `docs/plans`; no-arg behavioral smoke against this plan folder), `troubleshoot.md`.
**PHV5-051 — F14** · Band: trivial — `disable-model-invocation: true` on exactly `codebase-gates`, `plan-export`,
`readiness-generate`; **negative: not on `plan`** (§3.8 discovery-path decision).
**PHV5-052 — F08** · Band: small — gate-generator targets the `hooks` key of `.claude/settings.json` (merge), no
`.claude/hooks/hooks.json` reference, PowerShell variant for Windows.
**PHV5-053 — F28 + F30** · Band: small — no "Auto-invoked" phrasing, concrete triggers, reverse-reference sweep;
delete `commands/doc.md`, keep `skills/documentation` (skill carries `${CLAUDE_SKILL_DIR}` dispatch), no dangling
`/deepgrade:doc` references, counts updated.

**Wave 5 go/no-go:** hygiene sweeps green; command-count assertions consistent.

### Wave 6 — De-duplication *(risk: HIGH — R9 lossy-reconciliation; inputs = Wave 0 snapshots only)*

Rollback: `dist/` restorable from the immutable Wave 0 snapshots (rehearsed in Wave 8).

**PHV5-060 — Segmenter + inventory generator + exact-consumption checker** · Band: medium · Shared with Wave 7
Blank-line segmenter (measured: `commands/plan.md` → 304 blocks, max 22 lines), occurrence-addressed inventory
(file, index, hash) over **847 input / ~513 output blocks**; auto-seed hash-equal 1:1s **only** under topology
(allowed file pairings) + monotonic-order constraints — cross-file matches always route to the manual pass;
cardinality types `1:1 keep · N:1 · 1:N · grouped transform · drop · generated`; checker rejects gaps, overlaps,
unclaimed spans, transforms without complete output declarations.
**PHV5-061 — Reconciliation ledger + F33 + F16** · Band: large
Reconcile from snapshot hashes only; KB field sets unified (Plan-field disposition explicit); guardrail-miss token
format single across both products; every bundled-doc reference `${CLAUDE_PLUGIN_ROOT}`-anchored and resolving
from an installed copy.
**PHV5-062 — Renderer + `dist/` + Layer 6 drift gate** · Band: medium–large
`scripts/build-standalone-skill.sh` deterministic (clean clone → regenerate → byte-identical to committed
`dist/troubleshooting-skill/`); `tests/layer6-drift-check.sh` diffs `dist/` against **both** snapshots — any
source hunk neither surviving verbatim nor ledgered with a disposition fails; semantic checks also pass
(necessary, not sufficient).
**PHV5-063 — Wave 6 independent review** · Band: medium — §10.4; **review reads the drop list AND the full
transform table** (the gate makes loss explicit; the review is the control that reads it).

**Wave 6 go/no-go:** exact-consumption checker passes both sides · determinism proven · Layer 6 green · review GO.

### Wave 7 — Command→skill *(risk: HIGH — R3 bootstrapping; runs at END of Phase 6 from current HEAD)*

**PHV5-070 — Build `skills/plan/` + staging proof** · Band: medium–large on top of F12's large band
`SKILL.md` < 500 lines; references one level deep; `${CLAUDE_SKILL_DIR}` anchors; forward slashes; Phase 5
sub-templates stay inside `phase-5-audit.md`; reconcile the Step 0 boundary disagreement first.
Staging proof **out-of-band** (scratch copy with `commands/plan.md` removed, via `--plugin-dir` — the working tree
never hosts both surfaces): (a) fresh session starts Phase 1 · (b) fixture `status.json` resumes at the correct
phase · (c) `${CLAUDE_SKILL_DIR}` resolves · (d) **all nine phase boundaries** load their phase file ·
(e) **forced compaction** mid-plan, later phases still reachable (the migration's motive, tested directly) ·
(f) completeness manifest under the **same §3.3 occurrence/cardinality model** over the 1,528-line command ·
(g) invocation from an installed copy.
**PHV5-071 — Activation + recovery + review** · Band: small + medium–large review
One commit: add skill, delete `commands/plan.md`; §10.4 review before merge; recovery = **single revert** +
`/reload-plugins`, in-flight plan state needs no migration (proven by fixture (b)). Never leave both surfaces live.

**Wave 7 go/no-go:** all 7 staging-proof items pass · completeness manifest exact-consumption green · review GO.
Phases 7–8 of the planning workflow then run against the new skill.

### Wave 8 — Release *(risk: HIGH — R7/R14; gated on Waves 1–7)*

**PHV5-080 — Version + CHANGELOG + migration note + doc conformance** · Band: small–medium
`plugin.json` → 5.0.0 (**the version is the cache key** — without it nothing propagates); migration note carries:
four-command update sequence, lane prerequisite + first-use check, **F24 PARTIAL disposition**, compatibility
floor (U7), §8.3 corrected disable procedure (uninstall **then** `/reload-plugins`), temp-file disposal, F23
NOT-MET record iff lane I, G1-state phrasing. §9.2 conformance table: every row's claim true of the shipped lane.
**PHV5-081 — Final schema gate** · Band: trivial — dual-manifest `validate --strict` at the release commit on
floor + current (CI re-run).
**PHV5-082 — Rollback rehearsal (§8.5)** · Band: medium
Disposable channel, versions 0.0.1→0.0.2: forward rollback executed; `dist/` restore from Wave 0 snapshots
executed; **uninstall + `/reload-plugins` → guarded command no longer denied** (hook-silence check).
**PHV5-083 — Publication gate (R14)** · Band: small each flow
Two-commit sequence: (1) release commit + tag `v5.0.0` → (2) catalog commit pinning
`{"source":"github","repo":"krwhynot/deepgrade","ref":"v5.0.0","sha":"<full 40-char SHA>"}` → push both.
Flow A (credentialed profile, end-to-end): marketplace update → plugin update → reload → `plugin list --json`
asserts version + qualified id → guarded smoke in the same profile. Flow B (fresh `CLAUDE_CONFIG_DIR`):
marketplace add → install auth-free → list assertions → authenticate that profile → smoke on **its** copy.
Identity: **normalized installed-tree comparison** — archive of the catalog's authoritative `sha` (ref separately
asserted to resolve to it) vs `installPath`, cache metadata excluded. **The gate fails if any step is simulated.**
**PHV5-084 — POSIX runtime run** · Conditional: executes **iff** G1 = POSIX_RUNTIME_VERIFIED; otherwise the
release claim uses the CI_ONLY phrasing (suite + schema verified on Windows + Ubuntu; dispatch on Windows).

**Wave 8 go/no-go (release):** GO ⇔ 080–083 all pass · both flows proven un-simulated · installed-tree identity
holds. This is the ship decision.

---

## View 2 — Leadership Summary

**What this is.** The deepgrade Claude Code plugin (v4.31.0) passed a structural audit that verified 33 defects —
none architectural, all *wiring*: hooks defined in one place but implemented in another, docs asserting counts the
code contradicts, a test suite that covers 2 of 33 defects and actively asserts two of them as correct. v5.0.0
closes all 33 plus 3 conformance additions, with every conditional shortfall (F24 partial enforcement on
parser-less hosts; F23 under the remote lane-I contingency) recorded publicly rather than claimed away.

**Why now.** The suite's 94% blind spot means every future change lands unverified; the hook layer's fail-open
parser is a live security gap (reproduced by execution); and the untracked sibling skill has already drifted
(296 → 300 lines). Each wave closes part of the blind spot before the riskiest work runs.

**Confidence basis.** The scope lock survived a 17-round adversarial review by an independent model
(OpenAI Codex, `gpt-5.6-sol @ xhigh`), converging 19 → 40/40 GO with 74 findings, zero rejected. Two empirical
gates (G0 launcher lane, U7 compatibility floor) resolve in Wave 0 *before* any risky work starts, and the one
owner-accepted risk (CR-1: the weaker node-less failure signal) is conditional on Wave 0 evidence — if the
condition fails, the plan **pauses for an owner decision** rather than proceeding on assumption.

**Timeline** (solo maintainer; §9.3 verified bands; working days ≈ focused days, not calendar):

| Wave | Content | Est. effort | Cumulative | Hard dependency |
|------|---------|------------:|-----------:|-----------------|
| 0 | Gates, snapshots, floor, CI | 3–4 d | 4 d | — (starts immediately) |
| 1–3 | Mechanical fixes, suite goes green | 2–3 d | 7 d | — (1 and 3 unblocked even during Wave 0) |
| 4 (a/b/c + review) | Hooks epic, lane N expected | 5–7 d | 14 d | **G0 lane from Wave 0** |
| 5 | Command hygiene | 1–2 d | 16 d | — |
| 6 (+ review) | Reconciliation, dist/, drift gate | 5–6 d | 22 d | Wave 0 snapshots |
| 7 (+ review) | plan.md → skill, staging proof | 3–4 d | 26 d | Waves 1–6 |
| 8 | Release, rehearsal, publication | 2 d | 28 d | Waves 1–7; G1 for POSIX step only |

**≈ 28 working days ≈ 5–6 calendar weeks** at solo pace, including three independent reviews with remediation and
budgeted second rounds. Critical path: Wave 0 → 4 → 6 → 7 → 8 (Waves 1/3/5 can interleave). Worst-case lane (I)
adds ≈ 1 large item, same as lane N (§9.3 lane delta) — lane choice does not move the estimate materially.

**Top risks and their controls** (full register: approach.md §5):

| Risk | Control |
|------|---------|
| R1 mis-sequenced cutover opens a security window | 4a builds + tests before 4b activates; 4b authors nothing |
| R2 test suite enshrines defects | Layer 2 rewritten inside 4a; baseline pinned (115/4) so expected-red ≠ new-red |
| R3 the plan workflow edits itself | Wave 7 activation contract: staging proof in scratch, single-revert recovery |
| R9 lossy reconciliation passes clean-looking gates | Occurrence-addressed ledger + exact-consumption checker + review reads drop list |
| R10 node-less installs lose the guard layer (lane N) | Honest degradation contract; CR-1 owner acceptance conditional on U6 evidence |
| R14 release never reaches the public path | Two-commit SHA pin + both install flows proven end-to-end, un-simulated |

**Go/no-go for leadership:** the ship decision is Wave 8's gate. Before it, three independent review GOs
(Waves 4, 6, 7) and the Wave 0 gate must all be on record; any owner override of a review is a named Change
Record in the release notes — visible, never quiet.

---

## View 3 — Working Checklist

Verification command classes (§10.3): **U** suite · **G** grep guard · **C** CI · **R** runtime proof ·
**I** installed-copy proof · **B** rollback rehearsal.

**Wave 0** *(order is mandatory)*
- [ ] 1. Snapshot 22 sources + hashes + pinned diff count → verify: clean clone lists all 22 [C, U]
- [ ] 2. `.gitattributes` → verify: `git ls-files --eol -- '*.sh'` all `w/lf` [U, C]
- [ ] 3. Wire Layer 5 → verify: `run-all.sh` totals 156/4 [U]
- [ ] 4. marketplace.json conformance → verify: dual-manifest `validate --strict` passes [U, C]
- [ ] 5. Commit `tests/expected-failures.txt` (the 4 F18/F19 reds)
- [ ] 6. U7 floor discovery → verify: `research/` artifact, 8 behaviors, chosen floor [C, G]
- [ ] 7. G0 probe from PowerShell (n → s → b) + U6 recording incl. node-less case → verify: lane recorded; if
      lane N, CR-1 visibility evidence attached; **if BLOCKED, STOP — owner CR required** [R]
- [ ] 8. G1 terminal state recorded (POSIX_RUNTIME_VERIFIED | CI_ONLY)
- [ ] 9. Enable CI matrix → verify: both OS jobs green under expected-red comparator; canary non-blocking [C]

**Waves 1–3**
- [ ] F29/F31 template sweep green [G] · F17 atomic rename + reverse sweep [U, G] · F01 uniqueness [U, G]
- [ ] Wave 2 batch, one edit per agent file; F21/F32 same-string convention check [U, G]
- [ ] F18+F19 atomic; **empty expected-failures.txt**; CI plainly green [U, C]
- [ ] F20A + F04 sweeps green [U, G]

**Wave 4** *(lane from G0; lane N shown)*
- [ ] 4a: port 8 scripts to JS; 11 ledger rows each with falsifying test [U]
- [ ] 4a: F24 corpus (reproduction payload denied; decoys allowed; exemption-position; malformed → fail-closed) [U, C]
- [ ] 4a: F22 ask-JSON · F25 lease · F26 JSON outputs (U4 settled) [U]
- [ ] 4a: Layer 2 rewritten, no positional indices [U]
- [ ] 4b: ONE activation commit (~8 files); folder + manifest-key never both present [U, R, I]
- [ ] 4c: Layer 7 — every event + matcher fires via `--plugin-dir` AND installed copy; node-less installed-copy
      case observed; F26 visibility (U5) settled [R, I]
- [ ] §10.4 review after 4c → committed `reviews/wave-4-round-M.md`, GO [—]

**Wave 5**
- [ ] F09 (incl. zero-arg negative) · F10 · F11 · F13 · F15 (no `tree`) sweeps green [G, U]
- [ ] F14 on exactly 3 commands, not `plan` [U] · F08 settings-merge target [G] · F28 · F30 (delete `doc.md`) [U, G]

**Wave 6**
- [ ] Segmenter + inventory + checker built (shared with Wave 7) → verify: rejects gaps/overlaps/unclaimed [U]
- [ ] Ledger complete: exact consumption both sides; drop list + transform table written [U]
- [ ] F33 schema unified · F16 `${CLAUDE_PLUGIN_ROOT}` anchors resolve from installed copy [U, G, I]
- [ ] Renderer deterministic (clean clone byte-identical) · Layer 6 green [U, C]
- [ ] §10.4 review (reads drop list + transform table) → GO [—]

**Wave 7**
- [ ] `skills/plan/` built; SKILL.md < 500 lines; staging proof (a)–(g) all pass in scratch copy [U, G, R, I]
- [ ] Activation commit; review → GO; recovery rehearsed (single revert + `/reload-plugins`) [B]

**Wave 8**
- [ ] 5.0.0 bump + CHANGELOG + migration note (all required contents per PHV5-080) [U, G]
- [ ] Final dual-manifest `validate --strict` on floor + current [C, U]
- [ ] Rollback rehearsal: 0.0.1→0.0.2, dist/ restore, uninstall+reload hook-silence [B, I]
- [ ] Publication: two commits (tag, then SHA-pinned catalog), push; Flow A; Flow B; installed-tree identity [I, B]
- [ ] G1-conditional POSIX run, else CI_ONLY release phrasing
- [ ] Ship.

---

## Testing Methodology Selection (per deliverable class)

Per the Testing Methodology Selection Framework (`docs/planning-techniques/10-testing-methodology-selection.md`).
Not everything is "unit tests"; each class gets the methodology its failure mode demands.

| Deliverable | Methodology | Why |
|-------------|-------------|-----|
| Doc/config conformance fixes (Waves 1–3, 5) | **TDD** (red→green) | Every acceptance test is falsifying — written to fail at HEAD (F17 reverse sweep, F01 uniqueness, count checks), pass after fix. The matrix predates the fixes. |
| Bash→JS guard port (4a, ledger rows) | **Characterization / Golden Master** | The 11-row behavior ledger IS the golden master: current inline+script behavior captured (both directions) before the port; the port must reproduce it. |
| New guard semantics (F24 states, F22 ask, F25 lease) | **TDD + Contract Testing** | The §3.1.6 parser contract is a payload contract with lane-qualified states; the corpus (decoys, exemption-position, malformed) is contract-driven, authored in Phase 3. |
| Hook runtime behavior (4c) | **Exploratory + runtime proof (Layer 7)** | U5/U6 are empirical unknowns by design — 4c observes, records, and converts observations into repeatable Layer 7 assertions. |
| Reconciliation + `dist/` (Wave 6) | **Characterization / Golden Master + Approval** | Wave 0 snapshots are the immutable baseline; exact-consumption checker proves nothing lost un-ledgered; the human review *approves* the drop list and transform table. |
| Renderer (Wave 6) | **Snapshot / Approval** | Determinism = regenerate-and-compare byte-identical to committed `dist/`. |
| plan.md → skill (Wave 7) | **Characterization + ATDD** | Completeness manifest = golden master over the 1,528-line command; the 7 staging-proof scenarios are acceptance-driven sign-off criteria, incl. the forced-compaction scenario that motivates the change. |
| Release + rollback (Wave 8) | **Shadow / Parallel (rehearsal) + Contract (schema)** | The disposable channel rehearses the real cutover with stand-in versions before the public path is touched; `validate --strict` is the vendor contract gate. |

**Separate Test Authorship (AI requirement):** the falsifying acceptance criteria were authored in Phase 3 and
adversarially reviewed across 17 Codex rounds — they are **fixed inputs** to implementation, not artifacts of it.
The implementing agent transcribes matrix rows into executable tests; each §10.4 wave review (non-Claude model
family) verifies the tests match their matrix rows before GO. **AI Failure Mode Checklist** applied at each wave
review: logic drift (diff vs matrix row), stale dependencies (CI floor job), hidden business-rule violations
(behavior ledger), tautological tests (every test must fail on the pre-fix tree or a mutated fixture — the sweep's
own negative-control pattern, §10.5), happy-path-only coverage (each guard case carries positive AND negative
assertions by matrix mandate). Expand/Contract (Methodology 11) is N/A — no database exists in this plugin.

---

## Operational Readiness (release)

- **Monitoring:** CI matrix (windows+ubuntu × floor+current) with expected-red comparator; non-blocking
  latest-version canary catches vendor drift; hook-error notices are the in-product signal for runtime-less hosts
  (U6-documented form).
- **Config rollout:** the migration note is the rollout document (four-command sequence; the version bump is the
  cache key). Third-party auto-update is off by default — reaching existing users *requires* the bump.
- **Incident fallback:** forward rollback as 5.0.1 (§8.2 — revert is not rollback; there is no unpublish);
  immediate disablement via uninstall + `/reload-plugins` or `DG_DISABLE_GUARDS=1` + restart (§8.3, rehearsed);
  `dg-*` temp files always safely deletable (§8.4).
- **Success metrics:** CI plainly green post-Wave-3 and staying green; zero hook errors on healthy supported
  hosts (4c + U7 floor evidence); both publication flows proven; installed-tree identity equal to the catalog SHA;
  zero silent scope escapes (every PARTIAL/NOT-MET named in release notes).

---

*Gate: this spec requires owner confirmation before Phase 5 (Audit) runs against it.*
