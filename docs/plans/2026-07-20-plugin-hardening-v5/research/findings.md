# Phase 2 — Combined Research Findings

**Plan:** `2026-07-20-plugin-hardening-v5`
**Date:** 2026-07-20
**Baseline:** commit `4fb4b64`, plugin v4.31.0, working tree clean
**Tracks combined:** Track 1 `research/codebase-scan.md` (finding verification) · Track 1b `research/test-baseline.md` (test suite baseline) · Track 3 `research/best-practices.md` (open-question research)

This document cross-references the three tracks against `brainstorm.md`. Where the tracks **disagree**, the disagreement is stated rather than averaged. Where research **failed** to resolve something, it is labeled as such.

---

## 1. What is true about our situation

### 1.1 The finding set is entirely real

All 33 in-scope findings re-check as **still valid at HEAD**. Zero withdrawn, zero downgraded. Four were confirmed by *execution*, not inspection: F18/F19 (`bash tests/layer1-config-wiring.sh` fails at HEAD), F24 (the grep+sed extractor was run against a quoted payload and confirmed to fail open), F25 (`--force-with-lease` was run through both regexes and matched), F22 (the live PreToolUse hook denied an unrelated read-only command during the research session itself).

The audit text is, however, **not safe to implement from directly**. Twelve findings carry scope corrections. Eight of those *grow* the work. The ones that change sizing or would send an implementer to lines that do not exist:

| Correction | Consequence for planning |
|---|---|
| F21 — the audit's enumeration is wrong for 2 of 3 command files (`doc.md` lists 3 MCP names, `troubleshoot.md` lists 4, not six each), and its *preferred* fix (hardcode `mcp__Ref__…`) is invalid | Estimate from the scan, not the audit; the preferred fix is dead |
| F17 — the orchestrating commands still call the **old** frontmatter names, so pipelines currently *work* | Renaming frontmatter alone converts a docs-only defect into 4 broken scanners + 1 broken Phase 1 agent |
| F24 — the fail-open path is reachable today only when `jq` is absent; once F06/F23 wire the scripts, grep becomes the only path and the hole goes **unconditional** | F24 must land *in the same batch* as the wiring, not after |
| F12 — token estimate overstated (~16–19K, not ~26K); line count 1528, not 1529 | Structural argument holds, the headline number does not |
| F19 — `README.md:160` (`**22 agents**`) is **correct** | Do not "fix" it |
| F06 — "wiring as-is would fail on macOS/Linux" is true only for *direct* invocation | `chmod` is hygiene, not a blocker, if exec form is used |

### 1.2 The dependency graph is not a DAG

Derived from the `depends_on` data, the graph contains cycles. It **cannot** be topologically sorted into a ticket order. Three strongly-connected components plus one root and six leaves:

- **K1 (18 findings)** — hooks + docs + commands knot. Must be decomposed **by file**, not by finding.
- **K2 (6 findings)** — agent frontmatter. All rewrite the same `tools:` line. One pass per agent file.
- **K3 (2 findings)** — F29 + F31, documentation templates. Fully independent island. **This is where work starts.**
- **Root:** F17 (only finding with `depends_on: []`).
- **Leaves:** F01, F08, F09, F24, F28, F30.

Track 1 explicitly flags that the K2→K1 edge is an **artifact of over-linking**, not a real constraint — the two clusters touch disjoint files. Use the file-overlap table for merge safety, not the graph.

`GUIDE.md` is touched by 11 findings and is the single highest merge-conflict risk in the repo. `tests/layer2-hook-simulation.sh` is touched by 7.

### 1.3 What the test suite can and cannot catch today

Baseline at HEAD: **1 of 4 layers failing, 156 passed / 4 failed.** All four failures are real defects (F18, F19), none are stale tests, none are Windows artifacts. `node tests/codex-challenge-test.js` passes 41/41 — but it is **not wired into `run-all.sh`**, so CI would report green without ever executing it.

Coverage against the 33 in-scope findings:

| Severity | In scope | Caught | Blind |
|---|---|---|---|
| critical | 1 | 0 | **1** |
| high | 5 | 0 | **5** |
| medium | 26 | 2 (1 partial) | 24 |
| low | 1 | 0 | 1 |
| **Total** | **33** | **2 (~6%)** | **31** |

**The suite is blind to the sole critical and all five highs.** The blind classes are exactly the defect classes the plan exists to fix: name uniqueness (no test), filename-to-`name:` agreement (no test), `tools:`/`allowed-tools:` parsing (zero references in any test file), reverse reference sweeps over `skills/`/`templates/`/`resources/` (never scanned), jq-absent guard branches (Layer 2 hard-requires jq and aborts without it), and negative guard tests (`--force-with-lease` untested).

Two tests **enshrine defects as correct behavior** and will turn red the moment the defect is fixed:

- **F22** — Layer 2 Test 5 asserts `HOOK_EXIT -eq 2` *and* stderr containing `"WARNING"`. It locks in the exact exit-2-while-saying-WARNING contradiction the finding reports.
- **F23** — Layer 2 extracts hooks by **positional index** from inline `plugin.json`. Any migration to `hooks/hooks.json` makes it exit `FATAL: Failed to extract hook command`. The harness is structurally welded to the architecture F23 removes.

Track 1b also surfaced a defect **not in the 33**: `agents/security-scanner.md` carries a malformed nested-array allowlist `tools: [["Read", "Grep", "Glob", "Bash"]]`. No test validates allowlist shape. Scope-addition candidate.

Two latent Windows portability risks in the harness itself: `core.autocrlf=true` with no `.gitattributes` (Layer 3's `grep -qxF` and `cut -f2` break on a stray carriage return; passes today only because this working tree happens to hold LF), and `layer1:145` uses GNU-only `head -n -1`.

### 1.4 What the official docs say we should do

Track 3 produced **Tier A** (fetched vendor documentation) answers for the structural questions. The load-bearing facts:

- **Hooks:** `hooks/hooks.json` is the documented default location, reinforced by the file-locations table, the canonical directory tree, the migration guide, and `claude plugin init --template hooks`. Inline is legal but non-idiomatic. **You cannot keep both** — with a `hooks/` folder *and* a manifest `hooks` key, v2.1.140+ silently ignores the folder and only warns. Migration must be atomic. Exec form (`"command":"bash","args":["${CLAUDE_PLUGIN_ROOT}/..."]`) is independently recommended for path placeholders, makes the exec bit irrelevant, and pins the interpreter — which matters because `shell` **defaults to `powershell` on Windows when Git Bash isn't installed**, where every current `bash -c '...'` string fails outright.
- **Command size:** "Keep SKILL.md under 500 lines" is stated in three official places. More decisive, and this is a **correctness** argument not a tidiness one: skill content enters the conversation once and is never re-read, and after auto-compaction Claude Code "re-attaches the most recent invocation of each skill after the summary, **keeping the first 5,000 tokens of each**." A 9-phase workflow is precisely the workload that triggers compaction. At 16–19K tokens, Phases 5–9 of `plan.md` are silently discarded mid-workflow with no error.
- **Commands are legacy:** "Custom commands have been merged into skills... both create `/deploy` and work the same way." The authoring guide says `commands/` is "Skills as flat Markdown files. **Use `skills/` for new plugins**." `skills/plan/SKILL.md` produces `/deepgrade:plan` — byte-identical to today. Zero user-facing change.
- **Versioning:** version is the **cache key**. "Pushing new commits without bumping it has no effect." A security fix to a DeepGrade hook reaches **zero existing users** unless `plugin.json` version changes. Third-party marketplaces have auto-update **off by default**. Mid-session, hooks keep the old version's path until `/reload-plugins`.
- **MCP identifiers:** `mcp__<server>__<tool>`, one identifier across permission rules, `allowed-tools`, subagent `tools`, and hook matchers. Subagent `tools:` is a hard allowlist where **partial** non-resolution is tolerated silently; `allowed-tools:` is a one-turn permission grant that "does not restrict which tools are available," so an unresolvable entry there is an inert no-op.
- **Hook output channels:** stdout is context only for `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart`. For `Stop`/`SubagentStop` the documented channel is `hookSpecificOutput.additionalContext`. **`PreCompact` supports only top-level `decision: "block"`** — there is no documented way to show a non-blocking PreCompact message.

### 1.5 Where the tracks disagree — read this before Phase 3

Four genuine cross-track contradictions. None are cosmetic.

**(a) F02/F07 vs. Q5 Option A — direct collision.** Track 3's recommended MCP fix is to replace `tools:` with `disallowedTools: Write, Edit` on `dependency-mapper.md` and `integration-scanner.md`. Both of those agents are also covered by F02/F07, which grant them **Write** precisely because their bodies mandate writing to `docs/audit/` and downstream commands read those files back. Applying Q5 Option A as literally written would **re-break the exact defect F02/F07 fixes**. If Option A is chosen it must be `disallowedTools: Edit` (Write retained), and the read-only posture must be carried by the reworded prose constraint instead.

**(b) F14 vs. Q2 on `disable-model-invocation` for `plan`.** F14 says leave `plan.md` model-invocable — disabling strips its description from context and breaks the discovery path `help.md` advertises. Track 3 recommends adding it, citing the docs' named use case (side-effecting workflows) and treating listing-budget relief as a benefit. They agree on the *mechanism* and disagree on whether it is desirable. This is a real Phase 4 decision, and it is the same decision as open question 6.

**(c) F26 vs. Q1 on PreCompact.** F26 prescribes converting `dg-pre-compact.sh:13` to a `systemMessage` carrying plan name, phase, and resume command. Track 3's Tier A reading is that PreCompact supports *only* `decision: "block"` and has no documented non-blocking surface — making that half of F26 **undeliverable as specified**. The two tracks also use different JSON keys for the Stop hook (`systemMessage` vs `hookSpecificOutput.additionalContext`). The exact key per event must be settled empirically before F26 is implemented.

**(d) F33 vs. Q3 on where the canonical techniques live.** Both tracks agree the *skill's distilled content* is canonical and the plugin `docs/` copy dies. They disagree on the **home**: F33 says `git rm -r docs/troubleshooting-techniques/` and leave the standalone skill where it is; Q3 says pull the content **into the plugin repo** as `skills/troubleshooting/references/techniques/` plus a generator and a `git diff --exit-code` drift gate. Q3's version creates a **new skill**, which collides with the brainstorm non-goal "No new commands, agents, or skills." Q3's argument for its position is strong and factual: `../troubleshooting-skill` **is not a git repository**, so F33's step (B) writes into an untracked directory that nothing versions, validates, or tests.

**Minor, worth catching now:** the two decompositions of `plan.md` disagree on where Step 0 (lines 141–247) lives. F12's phase-boundary list starts at 248 and never assigns Step 0; Q2 puts it in the router. F12 also counts 9 phase files, Q2 counts 10. Reconcile before implementation, not during.

---

## 2. Answers to the brainstorm open questions

### Q1 — Do `scripts/dg-*.sh` or the inline `plugin.json` one-liners become source of truth?

**RESOLVED.** The scripts win. Migrate to `hooks/hooks.json` referencing `${CLAUDE_PLUGIN_ROOT}/scripts/*.sh` in **exec form with an explicit `bash` launcher**, and delete the inline `hooks` key in the **same commit** (keeping both makes the new file silently ignored). Tier A backed on every point: documented default location, exec-form recommendation for path placeholders, and the PowerShell-fallback risk on Windows hosts without Git Bash.

The drifted features are therefore **restored, not dropped** — drift items 1, 2, 4, 5, 6 resolve by construction (F05).

**One bounded sub-decision remains for Phase 3:** F05(c) — the two behaviors that are *stricter* in the scripts (`dg-git-guard.sh:41-44` blocks commit on staging count; `:70-71` blocks every commit/push without a sub-120-minute build marker) are exit-2 denies that will fire constantly. Track 1 recommends gating both behind `DG_STRICT_GIT`. Decide the default.

### Q2 — Is `plan.md` (F12) split, trimmed, or left alone?

**RESOLVED.** Split into `skills/plan/SKILL.md` (router under 500 lines) plus one bundled file per phase. Both tracks independently reach the same structure. Research upgraded this from "spec-idiomatic tidiness" to a **correctness defect**: the 5,000-token post-compaction re-attach cap silently discards the Phase 5–9 instructions from a 16–19K-token file, with no error, in exactly the long sessions a 9-phase workflow produces.

The brainstorm's stated worry — "changes how the flagship workflow is invoked" — is **resolved as a non-issue**. `skills/plan/SKILL.md` in a plugin named `deepgrade` produces `/deepgrade:plan`, identical to today. Zero user-facing change.

Authoring constraints Phase 4 must respect: references **one level deep only** (a second hop causes silent `head -100` partial reads), anchor with `${CLAUDE_SKILL_DIR}` (survives relocation better than `${CLAUDE_PLUGIN_ROOT}/skills/plan/...`), forward slashes only, table of contents on any reference file over 100 lines. Phase 5's four sub-templates must stay **inside** `phase-5-audit.md`.

Unresolved sub-question, deferred with Q6: whether to add `disable-model-invocation: true` (see 1.5b). `troubleshoot.md` and `codex-challenge.md` stay deferred per F12.

### Q3 — Which copy of the nine troubleshooting techniques is canonical?

**PARTIALLY RESOLVED — the content question is answered, the home question is a Phase 3 decision.**

Answered: the **standalone skill's distilled runtime prose is canonical for technique content**; the plugin's `docs/troubleshooting-techniques/` copies carry planning-era "Status Before Implementation" / "Implementation" sections that have no business in an agent's context, and are dead payload (zero references anywhere). The plugin remains canonical for the `Plan` linkage field, which the skill's `kb-schema.md` lacks. Corroborated from both sides: `commands/troubleshoot.md:747` already matches the *skill's* token format, so the plugin's own doc copy is stale relative to the plugin itself.

Not answered — **Phase 3 must choose the home:**

- **F33's shape:** delete the plugin copy, leave the standalone skill as an external sibling. Minimal, but the sibling is not under version control.
- **Q3's shape:** move content into the plugin repo as a skill, add `scripts/build-standalone-skill.sh`, gate with `tests/layer5-drift-check.sh` using `git diff --no-index --exit-code`. Structurally prevents drift instead of merely detecting it — but creates a new skill, colliding with a stated non-goal.

Two facts that must inform the choice regardless: symlinks are **disqualified** here by three independently verified silent failure modes (sibling directory resolves outside the marketplace so it is skipped for security; `core.symlinks=false` in this repo; default Git Bash `ln -s` silently *copies*). And whether the marketplace cache copy recurses git submodules is **undocumented**, so submodules carry a catastrophic silent failure mode (empty skill directory shipped to every installer).

Hard cost either way: **all 9 of 9 files have drifted, 296 differing lines, with genuine one-sided content on BOTH sides** (file 08). A naive generate-from-one-side **destroys content**. Reconcile by hand once, then generate forward.

### Q4 — Does v5.0.0 signal breaking changes, and do 4.x users need a migration note?

**RESOLVED on mechanics (Tier A); the semver classification itself is labeled engineering inference (Tier C).**

- **The structural moves are NOT breaking.** Inline hooks to `hooks/hooks.json` has no invocation surface and only needs `/reload-plugins`. `commands/plan.md` to `skills/plan/SKILL.md` is not breaking as long as the name is preserved.
- **What justifies MAJOR is hook *behavior*.** Any change that newly blocks a previously-allowed action is behaviorally breaking even with no identifier change. F24's fail-closed branch (`exit 2` when jq is absent and extraction is lossy) is exactly that. If F05(c) ships the stricter script guards ungated, so are those. **v5.0.0 is justified — on hook denial semantics, not on file relocation.** F22 (deny to ask) and F25 (permit `--force-with-lease`) are loosenings and do not themselves force MAJOR.
- **Yes, 4.x users need a migration note**, and for a reason the brainstorm did not anticipate: third-party marketplaces have **auto-update disabled by default**, and hooks keep the *old* version's path mid-session until `/reload-plugins`. The note must carry the four-command sequence (`/plugin marketplace update deepgrade-marketplace`, `/plugin update deepgrade`, `/reload-plugins`, `/plugin list`).
- **Operationally decisive:** the version is the cache key. If `plugin.json` is not bumped, **none of this hardening reaches a single existing user**, silently.
- **New scope candidate not in the 33:** `plugin.json` and `marketplace.json` both declare `4.31.0`. They agree today, so nothing is broken — but the docs warn Claude Code uses the `plugin.json` value "without warning," so a maintainer who bumps only `marketplace.json` ships nothing. Recommend deleting `version` from the marketplace entry.

### Q5 — Are the MCP-dependent research paths fixed to qualified names, or removed?

**PARTIALLY RESOLVED — the rejection is firm, the replacement is a Phase 3 decision.**

Firmly answered, and both tracks agree: **hardcoding qualified names is wrong and must not be done.** The server segment is chosen by the *installing user*. Three different prefix shapes were observed live in this environment (`mcp__claude_ai_Ref_MCP__...`, `mcp__exa__...`, `mcp__perplexity__...`) — the same logical tool under two different server prefixes. The audit's preferred fix (`mcp__Ref__...`) fails on the author's own machine. Hardcoding is **strictly worse than omitting**, because in an allowlist it buys nothing while manufacturing false confidence.

Also firmly answered: the **command** side is trivial. `allowed-tools:` is a one-turn permission grant, not a restriction, so the bare names in `plan.md:4`, `doc.md:4`, `troubleshoot.md:4` are inert no-ops — strip them, no behavior change. Track 3's content correction stands too: `get_code_context_exa`, `crawling_exa`, `web_search_advanced_exa` do not exist on either Exa server here (F32). And `claude plugin validate` **passes despite unresolvable bare names** — this defect class needs a custom grep guard, CI will never catch it.

Not answered — **Phase 3 must choose for the two agents:**

- **B (conservative):** delete the bare names, keep the closed `tools:` allowlist. Deterministic, immune to issue #13605, but permanently forfeits MCP research even for users who *do* have the servers.
- **A (denylist inversion):** `disallowedTools:` so the agents inherit whatever the user actually has. Documented pattern, true graceful degradation — **but see 1.5(a): it must be `Edit` only, not `Write, Edit`, or it re-breaks F02/F07.** Benefit is contingent on plugin-subagent MCP inheritance actually working (issue #13605, closed, fix release unverified, Windows behavior unconfirmed).

Whatever is chosen, **F32 must state the identical convention** in `skills/mcp-research/SKILL.md` or the same defect reships.

### Q6 — Should `disable-model-invocation` be set on side-effectful commands (F14), and which ones?

**DEFERRED TO PHASE 4.** Not externally researched — Track 3 covered five questions and this was not among them.

Carried forward for the Phase 4 decision, not treated as settled:

- F14's verified answer is **three** commands: `codebase-gates.md` (writes six artifacts including a GitHub workflow), `plan-export.md` (moves a zip into the project root), `readiness-generate.md` (writes `CLAUDE.md`, `.claude/settings.json` `permissions.deny`, `.mcp.json`, seed files). F14 verified no command auto-chains into these three, so no internal handoff breaks, and `layer1:140-152` only asserts a description key exists, so the field is test-safe.
- F14 explicitly argues **against** setting it on `plan.md`; Track 3's Q2 argues **for** it. Unresolved (1.5b).
- Read-only scans stay untouched.

---

## 3. Viable implementation path

One concrete end-to-end sequence, derived from the mandatory-sequencing table and the file-overlap data. Waves are ordered; work **within** a wave is parallelizable except where noted. K1 and K2 are treated as parallelizable across branches per Track 1's caveat on the over-linked edge.

**Wave 0 — Harness prep (no behavior change, unblocks measurement).**
Add `.gitattributes` (`tests/fixtures/** text eol=lf`, `*.sh text eol=lf`) before the CRLF landmine detonates. Wire `codex-challenge-test.js` into `run-all.sh` as Layer 5. Record the baseline verbatim: 156 pass / 4 fail, Layer 1 red on F18/F19.

**Wave 1 — The independent island and the true root.**
K3: **F29 + F31** together (both rewrite the same blocks in the same four template files). Then **F17 then F01** in that order and as one atomic commit each — F17 must rename frontmatter *and* the five caller lines together, or four scanners and a Phase 1 agent break. Add the name-uniqueness and filename-to-`name:` assertions to Layer 1 in the same commit; they catch F01 + F17 and are the highest-value test additions available.

**Wave 2 — Agent frontmatter, one pass per file (K2).**
Requires the Q5 decision first. **F02 + F03 + F07 + F21 + F27** rewritten as a **single edit per agent file**, never five passes. Reword the five contradicting read-only constraints (`doc-auditor:154`, `integration-scanner:141`, `dependency-mapper:173`, `feature-scanner:124`, `risk-assessor:182`) to the wording already shipping at `delta-scanner.md:203`. Fold in the `security-scanner.md` nested-array fix. Add the `tools:`/`allowed-tools:` shape-and-cross-check test.

**Wave 3 — Doc counts, Pass A (clears the red suite).**
**F18 + F19 + F20A + F04.** F18 and F19 must land together (`layer1:248` cross-checks README against CHANGELOG; neither alone clears the suite). Do **not** touch `README.md:160` (correct) or `README.md:163` (owned by F05/F06). Recover 4.30.0 scope from `git show c1a9457 --stat`, not from the audit summary. Extend Layer 1 with a skills-count assertion — the missed half of F19 — and with GUIDE version/count checks.

**Wave 4 — The hooks epic (one sequenced unit, the highest-risk work).**
Order is mandatory and stated verbatim in the fix approaches:

1. **F06 + F23 as ONE commit** — create `hooks/hooks.json` (8 exec-form handlers), delete `plugin.json:20-101`, `git update-index --chmod=+x scripts/*.sh`, port the PATH preamble and jq-first extraction **into each script** (they are grep-only today).
2. **F24 in the same batch** — non-negotiable. Fail-closed on the three *blocking* guards; keep the four informational hooks fail-open.
3. **F25 and F22 with or before F24** — all three edit the same deny branches in `dg-git-guard.sh`.
4. **F05 after** — drift items 1/2/4/5/6 resolve by construction; port the tracker JSON schema explicitly and decide F05(c).
5. **F26 after F05** — depends on which script bodies survive. Settle the exact JSON key per event first (1.5c); expect the PreCompact half to be dropped.
6. Rewrite `tests/layer2-hook-simulation.sh` in the same epic: de-index the extraction, flip Test 5 to assert `exit 0` plus `permissionDecision: "ask"`, add `--force-with-lease` negative tests, and run every case **twice — with and without jq on PATH**.
7. **F20 Pass B** once the hook behavior is final.

**Wave 5 — Command hygiene, grouped by file.**
**F09** alone. **F11 + F14** as one combined frontmatter edit. **F13 + F15** (same fence in `plan-status.md`). **F10 + F15** (same zip/mv block at `plan-export.md:339-344`). **F08** (retarget `gate-generator` to `.claude/settings.json`, add the Windows `.ps1` branch, replace `python3 -c` parsers). Add the reverse reference sweep over `commands/`, `skills/`, `templates/`, `resources/`.

**Wave 6 — De-duplication.**
**F33 first, then F16.** Canonicality must be decided before F16 wires `docs/troubleshooting-techniques/` that F33 wants deleted. If Q3 resolves to the in-plugin generator shape, add `tests/layer5-drift-check.sh` here.

**Wave 7 — F12, last, from a pinned copy.**
Pilot `plan.md` only. Reconcile the Step 0 boundary disagreement first. Update `tests/layer1-config-wiring.sh:336-353` and `tests/layer4-behavioral-smoke.sh:50-51` **before** deleting `commands/plan.md`, plus README and GUIDE counts.

**Wave 8 — Release.**
Bump `plugin.json` to 5.0.0, delete `version` from the marketplace entry, write the CHANGELOG entry and the 4.x migration note, run `claude plugin validate .`, and verify `bash tests/run-all.sh` is green.

**Parallelization note:** Waves 1, 2, 3 and 5 touch largely disjoint files and can overlap across branches — with the exception of `GUIDE.md`, which 11 findings touch and which should be serialized through a single branch regardless of wave.

---

## 4. Top risks with mitigation ideas

**R1 — Bootstrapping: `commands/plan.md` is both the running workflow and finding F12.** *(explicit brainstorm constraint)*
Editing it mid-plan swaps the workflow out from under the work in progress, and F12 is not a small edit — it deletes the file and relocates 1,528 lines into 10 new ones.
*Mitigations:* the dependency data already forces F12 last (it depends on F14, F15, F16, F19, F20 and breaks two test files), so the natural ordering and the constraint agree. Before Wave 7, pin a copy: `git show 4fb4b64:commands/plan.md > <scratchpad>/plan-pinned.md` and drive the remaining phases from the pinned copy. Do not begin Wave 7 until Phases 3–8 of this plan are complete. Do not leave both `commands/plan.md` and `skills/plan/SKILL.md` live even briefly — two components resolving to `/deepgrade:plan` reproduces the F30 duplicate-entry defect.

**R2 — Windows/POSIX portability: fixes get authored and verified on exactly one platform.** *(explicit brainstorm constraint)*
F15 (missing `zip`/`python3`/`pdftotext`/`pandoc`/`tree`, `grep -oP`), F24 (jq-less fallback), F08 (Unix-only generated hook scripts), F06 (mode bits), plus `layer1:145`'s GNU-only `head -n -1` and the unguarded CRLF exposure are *precisely* portability defects. Verification happens on Windows 11 / Git Bash only. There is no POSIX or macOS host in the loop, so a POSIX regression ships blind.
*Mitigations:* land `.gitattributes` in Wave 0 before anything else. Use exec form with an explicit `bash` launcher — it removes the exec-bit dependency *and* prevents the silent PowerShell fallback from mangling commands on a Git-Bash-less Windows host. Prefer `command -v` guards with named fallbacks (`powershell Compress-Archive` for `zip`, `find -maxdepth` for `tree`, jq-then-sed for `python3`) over silent `2>/dev/null`. Add `shellcheck scripts/*.sh` to `run-all.sh`. Run the whole suite in a Linux container before tagging 5.0.0 — this is the single cheapest way to close the blind spot. If no POSIX host is available, state the limitation in the release notes rather than claiming portability was verified.

**R3 — The test suite enshrines two of the defects and is blind to 31 of 33.**
F22 and F23 will turn Layer 2 red *by design*, and Layer 2 is structurally welded to the inline-hook positional indices F23 removes. Meanwhile 94% of the work is unverifiable by the existing harness, so a fix can silently regress.
*Mitigations:* treat test additions as **part of** each wave, not a follow-up — the ordering in section 3 already interleaves them. Rewrite Layer 2 in the same epic as F06/F23, never after. Record the exact 156/4 baseline first so "expected red" is distinguishable from "new red." Add the four highest-value assertions early (name uniqueness, `tools:` shape, reverse reference sweep, jq-absent double-run) — they cover the critical, all five highs, and F24/F25.

**R4 — The hooks epic is one large indivisible commit that opens a security hole mid-flight.**
F06+F23 must be one commit spanning 13–16 files, and the moment the scripts are wired, F24's fail-open goes from *conditional* to *unconditional*. Fixing F24 afterward ships a live security regression.
*Mitigations:* treat Wave 4 steps 1–3 as a single reviewable unit with a hard gate: the F24 fail-closed tests must pass in the same commit that wires the scripts. Keep the `DG_STRICT_GIT` decision explicit and defaulted to *off* unless deliberately chosen — `dg-git-guard.sh:70-71` would otherwise block every commit and push without a fresh build marker, stranding the maintainer mid-plan.

**R5 — Cross-track contradictions implemented independently.**
Q5 Option A as written cancels F02/F07. F26's PreCompact fix is undeliverable as specified. F14 and Q2 disagree about `plan`.
*Mitigations:* resolve all four (section 1.5) in Phase 3 options analysis *before* Wave 2 begins. Wave 2 is explicitly gated on the Q5 decision.

**R6 — Edits outside version control.**
`../troubleshooting-skill` is **not a git repository**. F33's step (B) writes into it. Anything done there is unversioned, unreviewable, and invisible to `claude plugin validate` and the test suite.
*Mitigations:* stage the edit in scratchpad and record it in the plan so it is not silently lost. This is also the strongest argument for Q3's in-plugin-canonical shape, which eliminates the problem rather than working around it.

**R7 — The release ships to nobody.**
The version is the cache key. Without a `plugin.json` bump, none of this reaches an existing user, with no error. The dual-version setup in `marketplace.json` is a latent trap.
*Mitigations:* Wave 8 gates on the bump. Delete `version` from the marketplace entry. Add a pre-push or CI check that fails when plugin files change without a version bump and a matching CHANGELOG entry.

**R8 — `GUIDE.md` merge conflicts.** 11 findings touch it.
*Mitigation:* serialize all GUIDE edits through one branch; Pass A (counts/version) is unblocked and can ship in Wave 3, Pass B waits for Wave 4.

**R9 — The plugin audits itself.** *(explicit brainstorm constraint)*
Changes to agents and skills alter the behavior of the tools used to verify the changes.
*Mitigation:* verification leans on `tests/run-all.sh` and the per-finding shell verify commands already captured in `codebase-scan.md`, never on agent self-report.

**R10 — Scope creep from research-generated additions.**
Track 3 surfaced work not in the 33: marketplace `version` removal, `.gitattributes`, `references/` plus `assets/` directory renaming, the drift generator and Layer 5 gate, README update-procedure section. Track 1b surfaced the `security-scanner` nested-array bug.
*Mitigation:* Phase 3 must explicitly accept or defer each. The `references/`/`assets/` rename is flagged by its own author as **cosmetic** — defer it. `.gitattributes`, the marketplace version field, and the `security-scanner` fix are cheap and directly serve stated goals — accept. The generator and Layer 5 gate are contingent on the Q3 home decision.

---

## 5. What we still don't know

| # | Unknown | Status |
|---|---|---|
| U1 | Whether `claude plugin validate` accepts `skills:` in agent frontmatter (F27's *preferred* fix, which preloads without granting a new tool) | **NON-BLOCKING** — documented fallback exists (append `Skill` to the allowlist); resolve by running the validator |
| U2 | Whether `user-invocable: false` is accepted on a skill (F30) | **NON-BLOCKING** — fallback is the stripped description alone |
| U3 | Whether plugin-defined subagents actually inherit MCP tools. Issue #13605 is closed; the fixing release could not be verified from official docs, nor confirmed on Windows | **NON-BLOCKING for scope lock** (Option A is no worse than Option B when inheritance is broken). **BLOCKING for any claim that MCP research capability was restored** — do not advertise it in the CHANGELOG without an empirical check |
| U4 | The exact non-blocking output key per hook event — `systemMessage` vs `hookSpecificOutput.additionalContext`. The two tracks use different keys for Stop | **NON-BLOCKING for scope**; must be settled empirically before F26 is implemented |
| U5 | Whether PreCompact can surface a non-blocking message at all. Tier A reading says no | **NON-BLOCKING** — outcome is either "drop the PreCompact half of F26" or "accept debug-only"; either way the scope shrinks, not grows |
| U6 | Whether the marketplace cache copy recurses git submodules — undocumented, no source supports or refutes it | **NON-BLOCKING** — submodules are rejected on this basis; only matters if Q3 reverses that |
| U7 | Behavior on a genuinely Git-Bash-less Windows host. Exec form fails *loudly* there rather than being mangled, but no such host was tested | **NON-BLOCKING for scope**; the honest options (declare Git Bash a prerequisite, or ship parallel `.ps1`) are both cheap. Must be stated in the release notes |
| U8 | Whether the plan owner accepts Q3's shape, which creates a new skill and collides with the "no new skills" non-goal | **NON-BLOCKING for Phase 2 exit** — it is exactly the decision Phase 3 options analysis exists to make. **BLOCKING for Wave 6** — the artifact set changes depending on the answer |
| U9 | Whether `DG_STRICT_GIT` defaults on or off (F05c) | **NON-BLOCKING** — Phase 3 decision, bounded, with a safe default (off) |
| U10 | Whether the fixes hold on POSIX/macOS. No such host is in the verification loop | **NON-BLOCKING for scope lock. BLOCKING for the goal "fixes must be validated for both Windows and POSIX"** — either add a Linux container run to Wave 8 or downgrade the claim |
| U11 | Whether the `security-scanner.md` nested-array allowlist and the other Track 1b out-of-set discoveries enter scope | **NON-BLOCKING** — trivial fix, Phase 3 accept/defer |
| U12 | Exact `4.30.0` release scope for the CHANGELOG backfill | **NON-BLOCKING** — recoverable from `git show c1a9457 --stat` |

**Nothing in this list blocks locking scope.** Two items (U3, U10) block specific *claims* rather than specific *work*, and both have a stated honest fallback: don't make the claim.

---

## 6. Stop-rubric check

### Are all brainstorm open questions answered or deferred?

**Yes.**

| Q | Verdict |
|---|---|
| 1 — hooks source of truth | **RESOLVED** — scripts win; `hooks/hooks.json` plus exec-form bash, atomic. One bounded sub-decision (`DG_STRICT_GIT` default) remains for Phase 3 |
| 2 — `plan.md` disposition | **RESOLVED** — split into `skills/plan/`; upgraded from tidiness to correctness by the 5,000-token compaction cap; invocation name unchanged |
| 3 — technique canonicality | **PARTIALLY RESOLVED** — content question answered (skill's distilled prose canonical, plugin `docs/` copy dies); **home** is a Phase 3 decision between two clearly specified options |
| 4 — v5.0.0 and migration note | **RESOLVED** — structural moves are not breaking; the MAJOR trigger is F24's new blocking behavior; a migration note **is** required because third-party auto-update is off by default |
| 5 — MCP research paths | **PARTIALLY RESOLVED** — hardcoding firmly rejected, command side trivially resolved; agent-side choice between denylist inversion and strip-only is a Phase 3 decision, with a mandatory correction to the researched recommendation |
| 6 — `disable-model-invocation` | **DEFERRED TO PHASE 4** as instructed; not externally researched. F14's three-command answer carried forward, with the `plan.md` sub-question flagged as contested |

Three fully resolved, two narrowed to bounded Phase 3 decisions with options already enumerated, one deliberately deferred. **PASS.**

### Is there a viable implementation path?

**Yes.** Section 3 gives a concrete 9-wave end-to-end sequence honoring every mandatory-sequencing constraint in the dependency data (F17 before F01, F06+F23 as one commit, F24 in that batch, F05 after, F26 after F05, F33 before F16, F18 with F19, F11 with F14, F13/F10 with F15, F12 last) and every same-file conflict zone. It starts at the genuinely independent island (K3) and the true root (F17), so work can begin immediately without waiting on any Phase 3 decision. Only Wave 2 (gated on Q5) and Wave 6 (gated on Q3) depend on unresolved decisions, and both sit behind waves that do not. **PASS.**

### Do top risks have mitigations?

**Yes — all ten, including both explicit brainstorm constraints.** The bootstrapping constraint (R1) is mitigated by the pinned-copy technique *and* by the fact that the dependency data independently forces F12 last. The Windows/POSIX constraint (R2) is mitigated by early `.gitattributes`, exec-form invocation, `command -v` fallback guards, `shellcheck`, and a container run — with an honest downgrade path if no POSIX host materializes. **PASS.**

### Are remaining unknowns non-blocking?

**Yes, for scope lock.** All twelve are non-blocking for locking scope. Two (U3, U10) block specific *claims* rather than any *work*, and both have a stated fallback of not making the claim. One (U8) is blocking for Wave 6 specifically but is assigned to Phase 3, which is where it belongs. **PASS.**

### Verdict

**STOP RUBRIC PASSED — Phase 2 is complete. Proceed to Phase 3 options analysis.**

Phase 3 carries a short, specific agenda: (1) Q3's home decision, (2) Q5's agent-side decision *with* the F02/F07 correction applied, (3) F05(c)'s `DG_STRICT_GIT` default, (4) the four cross-track contradictions in section 1.5, and (5) accept/defer on the five research-generated scope additions in R10.
