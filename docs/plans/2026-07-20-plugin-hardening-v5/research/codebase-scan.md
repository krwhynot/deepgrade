# Phase 2 — Codebase Scan

**Date:** 2026-07-20
**Commit verified against:** `4fb4b64` (HEAD)
**Repo root:** `C:/Users/NewAdmin/Projects/plugin/toque-plugin` (note: the git root *is* `toque-plugin`; repo-relative paths omit that prefix)

## What was verified

All 33 audit findings were re-checked against the working tree at HEAD. For each finding the verification pass captured: (a) whether the defect still reproduces, with exact `file:line` evidence; (b) the concrete files that must change; (c) a fix approach at line-level granularity; (d) effort, risk, and inter-finding dependencies; (e) an executable verification command.

Several findings were confirmed by **execution**, not inspection alone — notably F18/F19 (`bash tests/layer1-config-wiring.sh` was run and fails at HEAD), F24 (the grep+sed extractor was run against the malicious payload and confirmed to fail open), F25 (`--force-with-lease` was run through both regexes and confirmed to match), and F22 (the live PreToolUse hook denied an unrelated read-only command during this session).

---

## Summary

| Metric | Count |
|---|---|
| Findings re-checked | 33 |
| **Still valid at HEAD** | **33 (100%)** |
| Invalidated / no longer reproduce | **0** |
| Downgraded in severity | **0** |
| Confirmed but with **material scope corrections** | **12** |
| Confirmed and **broader than the audit stated** | **8** |

### Nothing was invalidated — but 12 findings had their scope corrected

No finding was withdrawn. However, twelve carry corrections that change ticket sizing or would mislead an implementer working from the original audit text. These are the items to re-read before estimating.

**Scope corrections that SHRINK or soften the claim:**

| ID | Correction |
|---|---|
| F12 | Token estimate overstated. `commands/plan.md` is 64,757 chars / 9,529 words ≈ **16–19K tokens, not ~26K**. Line counts also off by one (plan.md 1528 not 1529; troubleshoot.md 838 not 839). The structural argument holds; the number does not. |
| F23 | Handler length overstated ~28%. Measured max is **859 chars, not ~1,100** (SessionStart 491, PreToolUse/Bash 859, PostToolUse/Write 761, PreCompact 215). Finding stands on the structural argument only. |
| F06 | Overstatement: "wiring them as-is would fail on macOS/Linux" is true only for *direct* invocation. The recommended `{"command":"bash","args":["…/script.sh"]}` form does **not** require the exec bit. `chmod` is hygiene, not a blocker. |
| F21 | Audit enumeration wrong for 2 of 3 files. `commands/doc.md:4` lists **3** MCP names, `commands/troubleshoot.md:4` lists **4** — not six each. An implementer following the audit text would edit lines that do not exist. The audit's *preferred* fix (hardcode `mcp__Ref__…`) is also invalid: three different prefix shapes were observed live. |
| F11 | Citation slip: audit cited "lines 37–38"; line 38 is `</workflow>`. Only line 37 is an occurrence. |
| F30 | "The skill name `documentation` is exactly the overly generic naming pattern the docs warn against" is a **judgement call, not a defect**. The substantive defect is the duplicated trigger surface. |
| F05 | Audit's file paths carry a spurious `toque-plugin/` prefix. |
| F16 | Audit omitted `METHODOLOGY.md:353` and `:1132` — correctly so; those are human-facing repo links in a doc no runtime component loads, and must **not** be prefixed. |

**Scope corrections that GROW the claim (these add work):**

| ID | Correction |
|---|---|
| F02 | Extra defect: both agent bodies carry a self-contradicting `Read-only. Do not modify any files.` constraint (`doc-auditor.md:154`, `integration-scanner.md:141`) that must also be reworded when Write is granted. |
| F07 | Three agents carry absolute read-only constraints that survive the tools fix and must be reworded: `dependency-mapper.md:173`, `feature-scanner.md:124`, `risk-assessor.md:182`. |
| F08 | Larger blast radius: `commands/codebase-gates.md:34`/`:46` and `GUIDE.md:309` also advertise the wrong artifact path. |
| F15 | Tool list incomplete. Audit missed `readiness-generate.md:61` (`tree -d -L 2`, absent on stock Git Bash, no fallback) and `plan-export.md:75`/`:129` (`grep -oP`, PCRE, fails on BSD/macOS grep). |
| F20 | Audit missed a **second** `8-phase` occurrence at `GUIDE.md:221`. |
| F04 | Same defect class also at `CHANGELOG.md:77` (`claude --plugin-dir ./toque` presented as the install instruction). |
| F24 | Scope nuance that changes sequencing: today the fail-open path is reachable only when `jq` is absent. Once F06/F23 wire the scripts, grep becomes the **only** path and the hole becomes **unconditional**. F24 must land in the same batch as the wiring, not after. |
| F32 | Understated. Beyond qualification, the "Verified Tool Names" list is stale on **content**: `get_code_context_exa`, `crawling_exa`, `web_search_advanced_exa` do not exist on either Exa server in this environment. |
| F33 | Sharpened: `commands/troubleshoot.md:747` already matches the *skill's* token format, so the plugin's own doc copy is stale relative to the plugin itself. The genuine cross-source gap is only the `Plan` field. |
| F17 | Load-bearing detail: the orchestrating commands still use the OLD frontmatter names, so pipelines currently **work**. Renaming frontmatter without updating the five caller lines converts a docs-only defect into four broken scanner deployments plus a broken Phase 1 audit agent. |
| F19 | `README.md:160` (`**22 agents**`) is **correct** and must not be changed. |

---

## All findings

> **Note on severity:** the verification dataset does not carry a severity field. Risk and Effort are the shipped ordering signals and are reproduced verbatim below; a Severity column is omitted rather than back-filled with invented values.

| ID | Area | Effort | Risk | Files | Still valid |
|---|---|---|---|---|---|
| F01 | Agents — identity collision | trivial | low | 4 | Yes |
| F02 | Agents — tools allowlist | trivial | low | 2 | Yes |
| F03 | Agents — tools allowlist | trivial | medium | 2 | Yes |
| F04 | Docs — install/update flow | small | low | 4 | Yes |
| F05 | Hooks — inline/script drift | large | high | 13 | Yes |
| F06 | Hooks — dead script payload | medium | high | 16 | Yes |
| F07 | Agents — missing Write tool | small | low | 13 | Yes |
| F08 | Agents — hook output path | medium | medium | 3 | Yes |
| F09 | Commands — arg substitution | trivial | low | 1 | Yes |
| F10 | Commands — undefined var / arg | trivial | low | 1 | Yes |
| F11 | Commands — dead command names | trivial | low | 2 | Yes |
| F12 | Commands — oversized files | large | high | 10 | Yes |
| F13 | Commands — wrong path guard | trivial | low | 1 | Yes |
| F14 | Commands — model invocability | trivial | low | 3 | Yes |
| F15 | Commands — portability | medium | medium | 5 | Yes |
| F16 | Paths — plugin root resolution | small | low | 4 | Yes |
| F17 | Agents — name/filename drift | small | medium | 7 | Yes |
| F18 | Docs — CHANGELOG behind | small | low | 1 | Yes |
| F19 | Docs — README counts | trivial | low | 1 | Yes |
| F20 | Docs — GUIDE counts/behavior | medium | low | 1 | Yes |
| F21 | MCP — bare tool identifiers | small | medium | 5 | Yes |
| F22 | Hooks — deny mislabeled warn | small | medium | 6 | Yes |
| F23 | Hooks — inline unmaintainable | medium | high | 6 | Yes |
| F24 | Hooks — parser fails open | small | medium | 9 | Yes |
| F25 | Hooks — force-with-lease FP | trivial | low | 5 | Yes |
| F26 | Hooks — output never surfaces | small | low | 7 | Yes |
| F27 | Agents — skill unreachable | small | medium | 7 | Yes |
| F28 | Skills — no invocation path | medium | low | 11 | Yes |
| F29 | Skills — phantom agents | small | low | 4 | Yes |
| F30 | Skills — entry-point collision | medium | medium | 5 | Yes |
| F31 | Skills — dead command refs | trivial | low | 4 | Yes |
| F32 | Skills — bare MCP names | small | low | 2 | Yes |
| F33 | Docs — duplicated technique set | large | medium | 11 | Yes |

---

## Dependency / conflict analysis

### The dependency graph is not a DAG

Derived directly from the `depends_on` data, the graph contains **cycles**. It therefore cannot be topologically sorted into a linear ticket order. The correct reading is that mutually-dependent findings are **one unit of work**, not a sequence.

Three strongly-connected components (mutual-dependency knots) and two independent nodes fall out:

| Cluster | Members | Size | Reading |
|---|---|---|---|
| **K1 — hooks + docs + commands knot** | F04, F05, F06, F10, F11, F12, F13, F14, F15, F16, F18, F19, F20, F22, F23, F25, F26, F33 | 18 | Every member is reachable from every other. Cannot be sequenced; must be decomposed by *file*, not by finding. |
| **K2 — agent frontmatter knot** | F02, F03, F07, F21, F27, F32 | 6 | All five findings rewrite the same `tools:` lines. One pass per agent file. |
| **K3 — documentation templates** | F29, F31 | 2 | Fully independent island — depends on nothing outside itself. **Start here.** |
| Root | F17 | 1 | The only finding with `depends_on: []`. True entry point. |
| Leaves | F01, F08, F09, F24, F28, F30 | 6 | Depend on a cluster but nothing depends on them. Schedule last within their batch. |

**Caveat on the graph itself:** K2 formally depends on K1 (via `F03 → F16` and `F21 → F14`), but K1 has no path back into K2. That edge direction is an artifact of over-linking in the dependency data rather than a real ordering constraint — the agent `tools:` lines and the hooks rewrite touch disjoint files. Treat K1 and K2 as **parallelizable across teams**, and rely on the file-overlap table below rather than the graph for merge safety.

### Mandatory sequencing (explicitly stated in the fix approaches)

| Constraint | Reason |
|---|---|
| **F17 before F01** | F17 performs the atomic frontmatter+caller rename. F01 resolves the duplicate `report-generator` identity created by the same half-finished 4.27.0 change. |
| **F06 and F23 are one commit** | Both delete `.claude-plugin/plugin.json` lines 20–101 and create `hooks/hooks.json`. Stated verbatim: "these are one edit, not two… never schedule them in parallel." |
| **F24 in the same batch as F06/F23** | Once the scripts are wired, grep becomes the only parse path and the fail-open hole goes from conditional to unconditional. Fixing it after wiring ships a live security regression. |
| **F05 after F06/F23** | The structural move makes `scripts/` authoritative; drift items 1, 2, 4, 5, 6 resolve by construction. Only the tracker JSON schema conflict needs explicit porting. |
| **F25 and F22 before/with F24** | All three edit the same deny branches in `scripts/tq-git-guard.sh`. |
| **F26 after F05** | The systemMessage conversion depends on which script bodies survive the drift reconciliation. |
| **F33 before F16** | F16 recommends wiring `docs/troubleshooting-techniques/`; F33 recommends deleting it. Canonicality must be decided first or the two fixes contradict. |
| **F31 with F29** | Both rewrite the same blocks in the same four template files. |
| **F18 with F19** | `tests/layer1-config-wiring.sh:248` cross-checks README against CHANGELOG. Neither alone clears the suite. |
| **F11 with F14** | Both edit `commands/readiness-generate.md` frontmatter (argument-hint + disable-model-invocation). Stated: "make it one combined frontmatter edit to avoid a conflicting patch." |
| **F13 with F15** | Same bash fence in `commands/plan-status.md` (line 11 guard, line 22 python3 call). |
| **F10 with F15** | Same zip/mv block at `commands/plan-export.md:339–344`. |
| **F32 must match F21** | Whatever MCP naming convention F21 adopts must be stated identically in `skills/mcp-research/SKILL.md`. Divergence reships the same defect. |
| **F20 Pass B blocked on F05/F06** | The correct GUIDE wording for the hook behavior sections is determined by whether the scripts get wired. Pass A (pure count/version fixes) is unblocked and can ship immediately. |
| **F12 last** | Depends on F14, F15, F16, F19, F20 and breaks two test files. Pilot on `plan.md` only. |

### Same-file parallel-edit conflicts

These pairs/groups touch identical lines or blocks. Never assign to concurrent branches.

| Conflict zone | Findings | Collision |
|---|---|---|
| `.claude-plugin/plugin.json` lines 20–101 | F05, F06, F23 | Same block deleted/replaced by all three. |
| `scripts/tq-git-guard.sh` deny branches | F05, F06, F22, F24, F25 | Lines 9, 17–25 rewritten by four separate findings. |
| Agent `tools:` frontmatter line | F02, F03, F07, F21, F27 | Five findings rewrite one line per agent file. |
| `commands/readiness-generate.md` frontmatter | F11, F14 | Adjacent inserts into a 4-line block. |
| `commands/plan-export.md:339–344` | F10, F15 | Same zip/mv pair. |
| `commands/plan-status.md` fence 11–27 | F13, F15 | Same fence. |
| `skills/documentation/resources/*-template.md` | F29, F31 | Overlapping line ranges in all four files. |
| `skills/documentation/SKILL.md` | F30, F32 | Description line + MCP name qualification. |
| `commands/help.md` | F12, F28, F30 | Command count, skill count, documentation row. |
| `tests/layer2-hook-simulation.sh` | F05, F06, F22, F23, F24, F25, F26 | Seven findings add or rewrite tests in one file. |
| `GUIDE.md` | 11 findings (see hotspots) | Highest-conflict file in the repo. |

---

## File hotspots

Files touched by the most findings. These are the merge-conflict risks and the natural ticket boundaries.

| File | Findings | Count |
|---|---|---|
| `GUIDE.md` | F04, F05, F06, F08, F12, F20, F22, F23, F25, F26, F30 | **11** |
| `hooks/hooks.json` (new) | F05, F06, F22, F23, F24, F25, F26 | **7** |
| `METHODOLOGY.md` | F05, F06, F22, F23, F24, F25, F26 | **7** |
| `README.md` | F04, F05, F06, F12, F19, F22, F30 | **7** |
| `tests/layer2-hook-simulation.sh` | F05, F06, F22, F23, F24, F25, F26 | **7** |
| `scripts/tq-git-guard.sh` | F05, F06, F22, F24, F25 | **5** |
| `tests/layer1-config-wiring.sh` | F05, F06, F12, F23 | **4** |
| `commands/troubleshoot.md` | F12, F15, F21, F33 | **4** |
| `scripts/tq-session-stop.sh` | F05, F06, F24, F26 | **4** |
| `.claude-plugin/plugin.json` | F05, F06, F23 | 3 |
| `scripts/tq-migration-guard.sh` | F05, F06, F24 | 3 |
| `scripts/tq-track-change.sh` | F05, F06, F24 | 3 |
| `scripts/tq-track-test.sh` | F05, F06, F24 | 3 |
| `scripts/tq-session-start.sh` | F05, F06, F26 | 3 |
| `commands/plan.md` | F12, F16, F21 | 3 |
| `commands/help.md` | F12, F28, F30 | 3 |
| `commands/codebase-audit.md` | F01, F17, F28 | 3 |
| `commands/readiness-scan.md` | F01, F17, F28 | 3 |
| `commands/plan-export.md` | F10, F14, F15 | 3 |
| `commands/readiness-generate.md` | F11, F14, F15 | 3 |
| `commands/codebase-gates.md` | F08, F14, F28 | 3 |
| `agents/doc-auditor.md` | F02, F17, F27 | 3 |
| `agents/integration-scanner.md` | F02, F21, F27 | 3 |
| `agents/dependency-mapper.md` | F07, F21, F27 | 3 |
| `agents/plan-scaffolder.md` | F03, F16, F27 | 3 |
| `agents/plan-auditor.md` | F03, F16, F27 | 3 |
| `agents/{risk-assessor,feature-scanner}.md` | F07, F27 | 2 each |
| `agents/{entry,context,feedback,budget}-scanner.md` | F07, F17 | 2 each |
| `agents/readiness-report-generator.md` | F01, F11 | 2 |
| `skills/documentation/SKILL.md` | F30, F32 | 2 |
| `skills/mcp-research/SKILL.md` | F28, F32 | 2 |
| `skills/documentation/resources/{adr,brd,prd,readme}-template.md` | F29, F31 | 2 each |
| `commands/{quick-cleanup,plan-status,codex-challenge,doc}.md` | see table above | 2 each |
| `CHANGELOG.md` | F04, F18 | 2 |
| `CONTRIBUTING.md` | F04, F06 | 2 |
| `scripts/tq-subagent-stop.sh` | F06, F24 | 2 |
| `scripts/tq-pre-compact.sh` | F06, F26 | 2 |

**Natural ticket groupings implied by the hotspots:**

1. **Hooks runtime** — `hooks/hooks.json`, `.claude-plugin/plugin.json`, all 8 `scripts/*.sh`, `tests/layer2` → F06 + F23 + F24 + F25 + F22 + F05 + F26 as one sequenced epic.
2. **Agent frontmatter** — one pass per agent file covering F02 + F03 + F07 + F21 + F27, with F17 landing first.
3. **Doc counts/versions** — `README.md` + `CHANGELOG.md` + `GUIDE.md` Pass A → F18 + F19 + F20A + F04.
4. **Documentation skill/templates** — F29 + F31 + F30 + F32 + F28.
5. **Command hygiene** — F09 + F10 + F11 + F13 + F14 + F15 grouped by file.
6. **Deferred** — F12 (pilot only), F33 (canonicality decision), F16 (blocked on F33).

---

## Per-finding detail

### F01 — Duplicate agent identity `report-generator`

**Evidence.** `agents/readiness-report-generator.md:2` and `agents/toque-report-generator.md:2` both declare `name: report-generator`. `.claude-plugin/plugin.json` has no `agents` key, so identity comes solely from frontmatter — both register as `toque:report-generator` and only one wins the filesystem read order. Callers use the ambiguous name at `commands/readiness-scan.md:106` and `commands/codebase-audit.md:192` (prose also at `:58`, `:232`). Docs already use the intended unique names (`commands/help.md:107`/`:122`, `GUIDE.md:480-481`) and `CHANGELOG.md:65` claims the split already shipped — this is a half-finished 4.27.0 change.

**Fix.** Set line 2 of each agent to its filename-matching name. Update `readiness-scan.md:106` → `readiness-report-generator`; `codebase-audit.md:192`, `:58`, `:232` → `toque-report-generator`. No file renames; no doc edits.

**Verify.**
```
grep -h '^name:' agents/*.md | sort | uniq -d          # must print nothing
grep -rn 'report-generator' commands/ | grep -vE 'readiness-report-generator|toque-report-generator'
```

---

### F02 — `doc-auditor` and `integration-scanner` cannot run their own bodies

**Evidence.** `agents/doc-auditor.md:6` is `tools: Read, Grep, Glob` — no Bash, no Write — yet the body is bash-driven (lines 32-43, 46-55, 58-66, 71-80, 91-97, 100-105) and line 10 mandates writing `docs/audit/documentation-audit.md`. `agents/integration-scanner.md:6` is `tools: Read, Grep, Glob, ref_search_documentation, ref_read_url` with bash blocks at 32-46, 49-61, 64-71, 74-87 and the same write mandate at line 10. Downstream consumers (`commands/codebase-audit.md:123`/`:134`, Step 3.1) require those files to exist. **Extra defect:** `doc-auditor.md:154` and `integration-scanner.md:141` both say `Read-only. Do not modify any files.`

**Fix.** Both line 6 → `tools: Read, Grep, Glob, Bash, Write` (drop the bare MCP names from integration-scanner; coordinate with F21). Reword both constraint lines to `- Read-only for source files. You may only WRITE to docs/audit/.` (wording already used at `agents/delta-scanner.md:203`).

**Verify.**
```
grep -n '^tools:' agents/doc-auditor.md agents/integration-scanner.md
grep -n 'Read-only. Do not modify any files.' agents/doc-auditor.md agents/integration-scanner.md   # empty
```

---

### F03 — Planner agents cannot spawn their documented subagents

**Evidence.** `agents/plan-scaffolder.md:11` is `tools: ["Read","Grep","Glob","Bash","Write"]` while its body at lines 41-43 mandates deploying 3 analyst subagents in parallel (per-analyst model selection at 47-83). `agents/plan-auditor.md:11` has the identical array; body lines 215-217 mandate 4 specialist reviewers (five are actually defined at 220/226/232/238/244), with an Opus/Sonnet cost split at 305-308 and a Step 4.5 verification pass at 312 consuming "all 4 subagent outputs". Neither list contains `Agent`/`Task`.

**Fix.** Preferred: append `"Agent"` to both arrays (both already declare `model: opus` at line 9, so the orchestrator/analyst split stays meaningful). Alternative (redesign, not mechanical): delete plan-scaffolder Step 2 (41-83) and plan-auditor Step 4 (215-308) and move the fan-out into `commands/quick-plan.md` / `commands/quick-audit.md`, which already have `Task` — this also requires rewriting plan-auditor:312.

**Verify.**
```
grep -n '^tools:' agents/plan-scaffolder.md agents/plan-auditor.md   # Agent present in both
```
Behavioral: run `/toque:quick-plan` and confirm 3 nested analyst invocations in the transcript.

---

### F04 — Install and update instructions are wrong and mutually inconsistent

**Evidence.** `GUIDE.md:831-838` claims `git pull` suffices and "No reinstall needed — the plugin marketplace entry points to the directory". False for the installed flow: `.claude-plugin/plugin.json:3` pins `"version": "4.31.0"` and `marketplace.json:11` repeats it. Four divergent install syntaxes: `GUIDE.md:796`, `:801`, `:805` all omit the `@toque-marketplace` suffix; `CONTRIBUTING.md:9` omits the preceding `marketplace add` entirely; `README.md:25`/`:31` use the correct qualified form. Marketplace name confirmed `toque-marketplace` (`marketplace.json:2`), plugin name `toque` (`:8`). **Also:** `CHANGELOG.md:77` presents `claude --plugin-dir ./toque` as the install instruction.

**Fix.** Rewrite GUIDE §9 (787-826) to mirror `README.md:22-44`. Replace GUIDE §10 (831-838) with two separated flows: installed users (`/plugin marketplace update toque-marketplace` → `/plugin update toque`, noting updates require a maintainer version bump) and plugin developers (`claude --plugin-dir ./toque`). Delete the "No reinstall needed" sentence. `CONTRIBUTING.md:9` → `claude --plugin-dir ./toque`. Leave `CHANGELOG.md:77` history intact or annotate it.

**Verify.**
```
grep -rn 'plugin install toque' GUIDE.md CONTRIBUTING.md README.md   # all hits qualified
grep -n 'No reinstall needed' GUIDE.md                                    # zero
grep -n 'plugin marketplace update toque-marketplace' GUIDE.md        # exactly one
```

---

### F05 — Inline hooks have drifted from `scripts/` in six ways

**Evidence.** (1) Migration guard: `plugin.json:39` covers only `*/migrations/*|*/Migrations/*` + `.sql`; `scripts/tq-migration-guard.sh:12` covers migrate/alembic/drizzle/changelog and lines 19-23 accept four additional filename patterns. (2) `plugin.json:49` stops at three Layer-1 greps; `tq-git-guard.sh:30-47` (staging sanity) and `:49-71` (build verification) have no inline counterpart. (3) `plugin.json:61` writes `{"session_changes":N,"total":N}`; `tq-track-change.sh:19`/`:28` writes `total_changes_since_audit` and `:32-35` emits the delta nudge at `TQ_CHANGE_THRESHOLD` (default 15, line 14). **Empirically confirmed incompatibility:** given the inline-written file, the script's extractor returns EMPTY → TOTAL defaults to 0 → a wired script resets the audit counter every session. (4) `plugin.json:83` lacks the "no tests ran" branch present at `tq-session-stop.sh:21-33`. (5) `plugin.json:27` lacks the phase/staleness suffix present at `tq-session-start.sh:11-26`. (6) `plugin.json:71` matches fewer test/build runners than `tq-track-test.sh:15-30` (missing pnpm/yarn/mocha/ava/tox/go/msbuild). Doc drift: `METHODOLOGY.md:1811` cites the scripts as the source for the shipped-hook table; `GUIDE.md:625`/`:629`/`:645` document script-only behavior as shipped.

**Fix.** Do **not** fix independently. After F06/F23 wire the scripts, drift items 1, 2, 4, 5, 6 resolve by construction. Then: (b) standardize tracker JSON on the script form and add a legacy-key migration in `tq-track-change.sh` after line 23; (c) explicitly decide on the two behaviors that are *stricter* in the scripts — `tq-git-guard.sh:41-44` (blocks commit on staging count) and `:70-71` (blocks every commit/push without a <120min build marker), both exit-2 denies that will fire constantly. Recommend gating both behind `TQ_STRICT_GIT`. (d) Re-sync `METHODOLOGY.md:1798-1811`, `GUIDE.md:625-629`/`:641-645`, `README.md:163`, `CONTRIBUTING.md:19`.

**Verify.**
```
jq -e '.hooks' .claude-plugin/plugin.json                                  # non-zero (key removed)
echo '{"session_changes":3,"total":3}' > /tmp/tq-baseline-v5b
printf '{"session_id":"v5b","tool_input":{"file_path":"a.txt"}}' | bash scripts/tq-track-change.sh
jq -e '.total_changes_since_audit == 4' /tmp/tq-baseline-v5b
```

---

### F06 — All eight `scripts/*.sh` are dead payload

**Evidence.** `find . -name hooks.json` returns nothing (`tests/hooks/` is an empty directory). A repo-wide grep for the eight script basenames across `*.json` and `*.sh` matches only inside the audit's own notes — zero references from any hook configuration. `jq -r '.hooks|keys[]' .claude-plugin/plugin.json` returns PostToolUse, PreCompact, PreToolUse, SessionStart, Stop — **SubagentStop is absent**, so `scripts/tq-subagent-stop.sh` has no counterpart event and can never fire. `git ls-files -s scripts/` shows mode 100644 for all eight (the working tree's rwxr-xr-x is Windows `core.filemode` spoofing). **Also:** `plugin.json:95` (PreCompact) and `tq-pre-compact.sh` differ — the script requires `status.json` (line 8) while the inline version does not, so wiring silences PreCompact for plans without it.

**Fix.** Create `hooks/hooks.json` mapping all 8 events to exec-form handlers `{"type":"command","command":"bash","args":["${CLAUDE_PLUGIN_ROOT}/scripts/<name>.sh"],"timeout":<5/10/15>}`. Delete `plugin.json` lines 20-101. **Port the PATH preamble and jq-first extraction into each script** — the scripts are grep-only today (`tq-git-guard.sh:9`, `tq-migration-guard.sh:6`, `tq-track-change.sh:7-8`), so wiring as-is would *downgrade* parsing and make F24 unconditional. Run `git update-index --chmod=+x scripts/*.sh`. Two test blockers in the same commit: `tests/layer1-config-wiring.sh:111` asserts `hooks` is a required plugin.json field; `tests/layer2-hook-simulation.sh:48-53` extracts by array index. Adding SubagentStop makes 8 handlers, so `README.md:84-97` needs the heading changed to (8) plus a new row; also flip `README.md:163` and `CONTRIBUTING.md:19`.

**Verify.**
```
jq -e '.hooks' .claude-plugin/plugin.json          # non-zero
jq -r '[.[][]|.hooks[]]|length' hooks/hooks.json   # 8
git ls-files -s scripts/ | grep -c 100755          # 8
printf '{"tool_input":{"command":"git push --force origin main"}}' | bash scripts/tq-git-guard.sh; echo $?   # 2
```

---

### F07 — 13 scanner agents lack the Write tool their bodies mandate

**Evidence.** All 13 `tools:` lines and all 13 write mandates re-read at HEAD. Missing Write: `baseline-scanner.md:6`, `entry-scanner.md:6`, `convention-scanner.md:6`, `feedback-scanner.md:6`, `manifest-scanner.md:6`, `structure-scanner.md:6`, `context-scanner.md:6`, `budget-scanner.md:6`, `database-scanner.md:6`, `feature-scanner.md:6`, `risk-assessor.md:6`, `dependency-mapper.md:6`, `security-scanner.md:11`. Corresponding mandates at `baseline:65`, `entry:94`, `convention:99`, `feedback:106`, `manifest:58`, `structure:214`, `context:266`, `budget:428`, `database:570`, `feature:10`, `risk-assessor:11`, `dependency-mapper:10`, `security:29`. The "no temp scripts" clauses (`baseline:70`, `entry:99`, `structure:219`) close the workaround. Three blanket read-only constraints contradict outright: `dependency-mapper:173`, `feature-scanner:124`, `risk-assessor:182`. Pipeline-breaking: `readiness-scan.md` Phase 3 and `codebase-audit.md` Step 3.1 read these files back.

**Fix.** Append `, Write` to each `tools:` line (13 single-line edits), preserving each file's existing syntax style (bare list vs JSON array — `security-scanner.md:11` keeps the array form). Drop or fully-qualify the MCP names on `dependency-mapper.md:6` (same line as F21). Reword the three contradicting constraints to `- Read-only for source files. You may only WRITE to docs/audit/.`

**Verify.**
```
grep -L '^tools:.*Write' agents/{baseline,entry,convention,feedback,manifest,structure,context,budget,database}-scanner.md agents/{feature-scanner,risk-assessor,dependency-mapper,security-scanner}.md   # empty
grep -rn 'Read-only. Do not modify any files.\|Read-only analysis only.' agents/   # empty
```

---

### F08 — `gate-generator` writes hooks to a path Claude Code never loads

**Evidence.** `agents/gate-generator.md` targets `.claude/hooks/hooks.json` at lines 6, 27, 60, 88, 109, with a full hooks template at 113-140. That is not a documented load path — project hooks load from `.claude/settings.json`; `hooks/hooks.json` is the plugin-root format. The generated PostToolUse risk warnings and PreToolUse do-not-touch guard therefore never fire. Portability: generated scripts are `#!/bin/bash` (159, 250), parse stdin via `python3 -c` (165, 291, 337), and instruct `chmod +x` (237, 405). **Missed callers:** `commands/codebase-gates.md:34`/`:46` and `GUIDE.md:309` advertise the same wrong path. Noted in passing: two sections are both numbered "Step 4.5" (145, 243), and the tracker uses `TP_` env prefixes (256-257, 432-433) not `TQ_`.

**Fix.** Retarget lines 6, 27, 60, 88, 109 to `.claude/settings.json` and rewrite the 113-140 template to merge under the top-level `hooks` key (keep the MERGE-don't-overwrite instruction). Add a Windows branch at lines 122/133 emitting `.ps1` equivalents with `"shell":"powershell"`. Replace `python3 -c` parsers (165-169, 291-313, 337-377) with a jq-first / `python3`-or-`py -3` fallback chain. Make `chmod +x` conditional (237, 405). Update `codebase-gates.md:34`/`:46` and `GUIDE.md:309`.

**Verify.**
```
grep -rn '\.claude/hooks/hooks.json' agents/ commands/ GUIDE.md   # zero
grep -n 'python3' agents/gate-generator.md                        # only inside fallback chains
```
Behavioral: run `/toque:codebase-gates` against a fixture with a pre-existing `.claude/settings.json` hook; assert it survives, the new entry lands under `hooks`, and `.claude/hooks/hooks.json` was not created.

---

### F09 — `quick-cleanup` reads the wrong argument

**Evidence.** `commands/quick-cleanup.md:73` is `FOLDER="$1"` inside the Step 1 fence (72-87; consumed at 75 and 84). Under 0-based `$N` substitution, `$1` resolves to `topic-name`, not `folder-path` — the argument-hint at line 3 is `[folder-path] [topic-name] [--plan plan-name]`. `grep -rnE '\$[0-9]' commands/` matches only this file and `plan-export.md:29-32`. **Adjacent latent defect (not this finding):** lines 318-321 reference `${TODAY}`/`${PLAN_NAME}` set only in the unrelated fence at 19-21; separate Bash invocations do not share shell state.

**Fix.** Line 73 → `FOLDER="{folder-path from $ARGUMENTS}"`. Do **not** substitute `$0` — with zero arguments an unmatched placeholder stays literal and bash expands `$0` to the shell name, a silent wrong-path failure. Optionally add a substitution note above the fence. Leave the legitimate in-fence `"$FILE"`/`"$ext"` variables (74-86, 173-210) alone.

**Verify.**
```
grep -nE '\$[0-9]' commands/quick-cleanup.md   # zero
```

---

### F10 — `plan-export` moves the zip to filesystem root

**Evidence.** `commands/plan-export.md:344` is `mv "$ZIP_NAME" "${PROJECT_ROOT}/${ZIP_NAME}"`; `grep -rn PROJECT_ROOT commands/ agents/ skills/` returns this line only — the variable is never assigned, so it expands empty and the target becomes `/<plan>-export.zip`. Separately, lines 29, 30, 31, 32 use `$1` four times while argument-hint (line 3) declares a single `[plan-name]` (which is `$0` under 0-based indexing). `commands/doc.md:16` already uses `${CLAUDE_PLUGIN_ROOT}` correctly; no file yet uses `${CLAUDE_PROJECT_DIR}`.

**Fix.** Line 344 → `${CLAUDE_PROJECT_DIR}/${ZIP_NAME}`. Lines 29-32: replace every `$1` with the literal placeholder `{plan-name}` and add a substitution sentence above the fence at line 27. Do not use `$0`. Land with F15 (same block at 339-344).

**Verify.**
```
grep -n 'PROJECT_ROOT' commands/plan-export.md    # only ${CLAUDE_PROJECT_DIR}
grep -nE '\$[0-9]' commands/plan-export.md        # zero
```

---

### F11 — `readiness-generate` advertises four dead command names

**Evidence.** `/ai-readiness-*` at `commands/readiness-generate.md:2` (description, three occurrences), `:12`, `:37`, `:453`. Frontmatter is lines 1-4 and lacks `argument-hint` despite parsing `[number]|all-critical|all` at 23-27. **Wider scope:** `agents/readiness-report-generator.md:86`, `:122`, `:123` emit the same dead strings into the user-facing report. `CHANGELOG.md:78` is a historical migration note — leave it. `commands/readiness-scan.md:183` is a JSON identifier, not a command — leave it.

**Fix.** Replace all occurrences with `/toque:readiness-*`. Add `argument-hint: "[number|all-critical|all]"` between lines 2 and 3 — combine with F14's frontmatter edit.

**Verify.**
```
grep -rn '/ai-readiness' commands/ agents/     # zero
grep -n 'argument-hint' commands/readiness-generate.md   # line 3
```

---

### F12 — Three command files exceed practical context retention

**Evidence.** `commands/plan.md` 1528 lines / 64,757 chars / 9,529 words (**≈16–19K tokens, not the ~26K claimed**); `troubleshoot.md` 838; `codex-challenge.md` 533. Structural claim holds: `<workflow>` spans 140-1486 with Phase 4 at 586, 5 at 642, 6 at 1013, 7 at 1126, 8 at 1321, 9 at 1455 — everything from the audit rubric onward sits past the ~5K-token mark (≈line 400). No supporting-file mechanism in use: the only `${CLAUDE_PLUGIN_ROOT}` reference in `commands/` is `doc.md:16`. **Collateral:** `tests/layer1-config-wiring.sh:336-353` counts `commands/*.md` against README, and `tests/layer4-behavioral-smoke.sh:50-51` fails if help.md names a command with no `commands/<name>.md`.

**Fix.** Do this **last**, piloting `plan.md` only. Create `skills/plan/SKILL.md` with the frontmatter plus lines 7-140 and a dispatcher table; move each phase into `skills/plan/phases/phase-N-<name>.md` using boundaries 248-273, 274-350, 351-585, 586-641, 642-1012, 1013-1125, 1126-1320, 1321-1454, 1455-1486; load exactly one phase per turn via `${CLAUDE_PLUGIN_ROOT}`. Keep 1488-1528 in SKILL.md. Delete `commands/plan.md` only after updating both test files plus README and GUIDE counts. Defer `troubleshoot.md` and `codex-challenge.md`.

**Verify.**
```
wc -l skills/plan/SKILL.md            # < 500
ls skills/plan/phases/ | wc -l        # 9
grep -c 'CLAUDE_PLUGIN_ROOT' skills/plan/SKILL.md   # >= 9
bash tests/run-all.sh                 # passes
```

---

### F13 — `plan-status` guards the wrong directory

**Evidence.** `commands/plan-status.md:11` is `if [ ! -d "plans" ]; then` with `echo "No plans found."` at 12 and `exit 0` at 13, while the loop at 16 is `for d in docs/plans/*/`. In this repo `docs/plans` exists and `./plans` does not, so the no-argument overview short-circuits at line 13 and never reaches the loop. Every other command writes to `docs/plans/` (`quick-cleanup.md:21`, `plan.md:151`, `plan-export.md:29`, `troubleshoot.md:84`). Line 17 already has a `[ ! -d "$d" ] && continue` null-glob guard.

**Fix.** Line 11 → `if [ ! -d "docs/plans" ]; then`. (Deleting 11-14 is equally correct but loses the friendly message.) Batch with F15's line-22 python3 rewrite — same fence.

**Verify.**
```
grep -n 'if \[ ! -d' commands/plan-status.md   # docs/plans, no bare "plans"
```

---

### F14 — Three destructive commands are model-invocable

**Evidence.** `grep -rn 'disable-model-invocation' .` matches only inside the audit's own notes — zero hits in `commands/`. All 17 command frontmatters carry only description / argument-hint / allowed-tools, and all 17 appear as model-invocable entries in this session's skill listing. Side effects: `codebase-gates.md:33-38` writes six artifacts including `.github/workflows/toque-gate.yml`; `plan-export.md:344` moves a zip into the project root; `readiness-generate.md` writes `CLAUDE.md`, `.claude/settings.json` `permissions.deny` (211-223), `.mcp.json` (348-414), seed files (416-424). **Collateral checked:** no command auto-chains into these three, so no internal handoff breaks. `tests/layer1-config-wiring.sh:140-152` only asserts a description key exists, so the added field is test-safe.

**Fix.** Add `disable-model-invocation: true` to exactly three frontmatters: `codebase-gates.md` (after line 3), `plan-export.md` (after line 4), `readiness-generate.md` (after line 3, combined with F11's argument-hint). Leave `plan.md` invocable — it is interactive and gated by approval tiers (71-77), and disabling it strips its description from context and breaks the discovery path help.md advertises. Leave read-only scans untouched.

**Verify.**
```
grep -l 'disable-model-invocation: true' commands/*.md   # exactly 3
bash tests/layer1-config-wiring.sh                        # frontmatter checks pass
```

---

### F15 — Commands depend on tools absent from stock Windows Git Bash

**Evidence.** `plan-export.md:341` `zip -r` with no fallback (Git for Windows ships no `zip.exe`); `:49`, `:130`, `:339` hardcode `/tmp`. `plan-status.md:22` `PHASE=$(python3 -c` with `2>/dev/null` swallowing failure into an empty phase; `troubleshoot.md:89` the same. `quick-cleanup.md:174` pdftotext, `:177` PyPDF2, `:194` pandoc, `:204` python3 csv — this one **does** degrade gracefully (213-217, constraint 433). **Missed by the audit:** `readiness-generate.md:61` runs `tree -d -L 2` (absent, no fallback), and `plan-export.md:75`/`:129` use `grep -oP` (PCRE, fails on BSD/macOS grep).

**Fix.** (1) `plan-export.md:339-344`: guard with `command -v zip` and a `powershell Compress-Archive` fallback; change `/tmp` at 49/130/339 to `"${TMPDIR:-/tmp}"`. (2) `plan-status.md:22-27` and `troubleshoot.md:89-93`: replace the python3 heredoc with the jq-then-sed fallback already used at `tests/layer3-fixture-lint.sh:33-40` — `current_phase` is a flat top-level string (verified against `plan.md:170`), so the sed form is exact. (3) `readiness-generate.md:61` → `find . -maxdepth 2 -type d -not -path '*/.git/*'`. (4) `quick-cleanup.md`: add one `[MANUAL REVIEW]` fallback line before 173. Optionally convert `grep -oP` → `grep -oE`.

**Verify.**
```
grep -n 'zip -r' commands/plan-export.md      # wrapped by command -v guard
grep -rn 'python3' commands/                   # only quick-cleanup fallbacks
grep -rn 'tree -d' commands/                   # zero
grep -c '"/tmp' commands/plan-export.md        # 0
```

---

### F16 — Five runtime references use bare project-relative paths

**Evidence.** `commands/plan.md:609`, `commands/plan.md:1334`, `commands/codex-challenge.md:25`, `agents/plan-scaffolder.md:178`, `agents/plan-auditor.md:137` all reference `docs/planning-techniques/…` without a plugin-root prefix. Both target files ship (`docs/planning-techniques/` has 13 files). Contrast case: `grep -rn 'CLAUDE_PLUGIN_ROOT' --include=*.md commands/ agents/ skills/` returns exactly one line (`commands/doc.md:16`). Dead-directory claim also holds: zero references to `docs/troubleshooting-techniques/` anywhere, while the directory has 9 files. **Refinement:** `METHODOLOGY.md:353`/`:1132` also reference the directory but are repo-browsing links in a doc no runtime component loads — correctly out of scope, must **not** be prefixed.

**Fix.** Insert `${CLAUDE_PLUGIN_ROOT}/` before `docs/planning-techniques/` at exactly those five lines. Do not touch METHODOLOGY.md. Decide `docs/troubleshooting-techniques/` separately — **F33 must resolve canonicality first**; F16's minimal suggestion (add a reference from `commands/troubleshoot.md`) directly conflicts with F33's recommendation to delete.

**Verify.**
```
grep -rnE '(^|[^/{]) *docs/planning-techniques' commands/ agents/        # zero
grep -rc 'CLAUDE_PLUGIN_ROOT}/docs/planning-techniques' commands/ agents/ # totals 5
```

---

### F17 — Five agents have frontmatter names that no longer match their files

**Evidence.** `context-scanner.md:2` = `context-file-scanner`; `entry-scanner.md:2` = `entry-point-scanner`; `feedback-scanner.md:2` = `feedback-loop-scanner`; `budget-scanner.md:2` = `context-budget-scanner`; `doc-auditor.md:2` = `documentation-auditor`. Docs advertise the file-based names that do not resolve (`help.md:99`/`:101`/`:103`/`:105`/`:119`; `GUIDE.md:457`/`:459`/`:461`/`:463`/`:472`), and `CHANGELOG.md:66-70` claims all five renames shipped. **Load-bearing:** the orchestrating commands still use the OLD names (`readiness-scan.md:50`/`:52`/`:54`/`:56`, `codebase-audit.md:123`), so pipelines currently work — renaming frontmatter alone breaks four scanners plus a Phase 1 agent. No test asserts name/filename equality (`layer1:157-178` only checks `name:` exists; `:404-444` cross-references by filename).

**Fix.** Atomic, one commit. Rename line 2 of all five agents to match filenames. Update `readiness-scan.md:50`/`:52`/`:54`/`:56` and `codebase-audit.md:123`. **Leave output paths untouched** — `entry-point-scan.json`, `context-budget-scan.json` etc. are contract filenames consumed by Phase 3 synthesis and by the agents' own bodies (`entry-scanner.md:94`, `budget-scanner.md:428`). `codebase-audit.md:52`/`:148` and `METHODOLOGY.md:1575` already say `doc-auditor` and become correct for free. No README/GUIDE/help.md edits needed.

**Verify.**
```
for f in agents/*.md; do n=$(grep -m1 '^name:' "$f" | sed 's/^name: *//'); b=$(basename "$f" .md); [ "$n" = "$b" ] || echo "MISMATCH $f -> $n"; done   # empty
grep -rn 'context-file-scanner\|entry-point-scanner\|feedback-loop-scanner\|context-budget-scanner\|documentation-auditor' commands/ agents/   # empty
```

---

### F18 — CHANGELOG is two releases behind the manifest

**Evidence.** `CHANGELOG.md:3` is `## 4.29.0 (2026-03-22)`; `plugin.json:3` and `marketplace.json:11` are `4.31.0`. **Executed at HEAD:** `bash tests/layer1-config-wiring.sh` exits non-zero with `[FAIL] Version mismatch: plugin.json=4.31.0 CHANGELOG=4.29.0` and `[FAIL] Version mismatch: README=4.27.1 CHANGELOG=4.29.0` (84 passed, 4 failed). Extraction logic at `layer1:229` requires the exact `## X.Y.Z` heading form at the top of the file. Content is recoverable: HEAD `4fb4b64` is the MCP integration commit with its spec at `docs/specs/mcp-research-integration.md`.

**Fix.** Insert two sections above line 3 in `## X.Y.Z (YYYY-MM-DD)` form. `## 4.31.0` — new `mcp-research` skill plus optional MCP tools wired into plan/troubleshoot/doc and dependency-mapper/integration-scanner, per the checked-in spec. `## 4.30.0` — recover exact scope from `git show c1a9457 --stat` rather than trusting the audit's one-line summary. Derive dates from commit dates.

**Verify.**
```
grep -m1 -oE '^## v?[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md   # ## 4.31.0
bash tests/layer1-config-wiring.sh | grep 'Version mismatch.*CHANGELOG'   # empty
```

---

### F19 — README counts are wrong in three places

**Evidence.** `README.md:169` says `Current: v4.27.1` vs actual 4.31.0 (three releases behind). `README.md:46` says `## Commands (16)` while `ls commands/*.md | wc -l` = 17; the four tables (50-82) hold 4+4+4+4 = 16 rows and `/toque:codex-challenge` appears nowhere in README. `README.md:161` says `**5 skills**` while `ls -d skills/*/ | wc -l` = 6 (`mcp-research` omitted). Two of three confirmed by the repo's own gate. **`README.md:160` (`**22 agents**`) is CORRECT — do not change it.** The skill count is not asserted by layer1 and needs manual verification.

**Fix.** Four edits: `:169` → `Current: v4.31.0` (keep the exact `Current: vX.Y.Z` shape — `layer1:216` greps it literally); `:46` → `## Commands (17)`; add a `/toque:codex-challenge` row after `:64` matching `help.md:28`; `:161` → `**6 skills** - Docs, governance, readiness, knowledge, self-audit, mcp-research`. Do **not** touch `README.md:163` — currently accurate but becomes wrong under either F05/F06 resolution; let that finding own the line.

**Verify.**
```
grep -c 'Current: v4.31.0' README.md              # 1
grep -o 'Commands ([0-9]*)' README.md             # Commands (17)
grep -o '\*\*[0-9]* skills\*\*' README.md          # **6 skills**
```
Full clearance of `layer1` requires F18 to land too (cross-check at `layer1:248`).

---

### F20 — GUIDE is stale on version, counts, phase count, and hook behavior

**Evidence.** Version: `GUIDE.md:3` `v4.28.0`, `:8` badge, `:921` footer badge — actual 4.31.0. Counts: `:5` `**16 Commands** • **22 Agents** • **5 Skills** • **7 Safety Hooks**` and `:164` `**16 total**` (actual 17 commands, 6 skills; 22 agents correct); `:500` `### The 5 Skills` with five entries at 502-510; `:138-143` Layer 3 table lists only 4. `grep -c 'codex-challenge' GUIDE.md` = 0 and `grep -c 'mcp-research' GUIDE.md` = 0. Phase count: `:208` labels a 9-item list "8-phase", and — **missed by the audit** — `:221` repeats `8-phase`; both contradict `plan.md:2`/`:9`/`:56` and `help.md:12`/`:16`/`:34`/`:183`. Unshipped behavior documented as shipped: `:625`, `:629` (`TQ_CHANGE_THRESHOLD` nudge), `:641`, `:645` (no-tests-ran warning), `:562` (flow diagram node).

**Fix.** **Pass A (unblocked):** `v4.28.0` → `v4.31.0` at 3, 8, 921; `:5` → `**17 Commands** • **22 Agents** • **6 Skills** • **7 Safety Hooks**`; `:164` → `**17 total**`; `:208` and `:221` → `9-phase`; `:500` → `### The 6 Skills` plus an mcp-research paragraph after 510; add mcp-research to the 138-143 table; add a codex-challenge entry after 275. **Pass B (blocked on F05/F06):** if the scripts get wired, 625-629/641-645/562 stay as written; otherwise rewrite them to describe only what `plugin.json` actually does and drop the `TQ_CHANGE_THRESHOLD` sentence.

**Verify.**
```
grep -c '4\.28\.0' GUIDE.md      # 0
grep -c '8-phase' GUIDE.md       # 0
grep -o '\*\*[0-9]* Commands\*\*' GUIDE.md   # **17 Commands**
grep -o '\*\*[0-9]* Skills\*\*' GUIDE.md     # **6 Skills**
```
Pass B gate: every behavior sentence remaining in GUIDE §7 must be greppable in `.claude-plugin/plugin.json`.

---

### F21 — Bare MCP tool names in tool allowlists never match

**Evidence.** `agents/dependency-mapper.md:6` and `agents/integration-scanner.md:6` list bare `ref_search_documentation`/`ref_read_url`. `commands/plan.md:4` lists all six. **Audit enumeration wrong:** `commands/doc.md:4` lists only **three** and `commands/troubleshoot.md:4` only **four** — an implementer working from the audit text would edit lines that do not exist. Total scope is 6 bare identifiers across 5 frontmatter lines. No `.mcp.json` ships (`.claude-plugin/` holds only marketplace.json and plugin.json), so prefixes are install-specific — **three different prefix shapes observed live**: `mcp__claude_ai_Ref_MCP__…`, `mcp__exa__…`, `mcp__perplexity__…`. This invalidates the audit's preferred fix of hardcoding `mcp__Ref__…`.

**Fix.** Take the audit's **second** option — drop the bare names rather than guess prefixes. `dependency-mapper.md:6` → `tools: Read, Grep, Glob, Bash`; `integration-scanner.md:6` → `tools: Read, Grep, Glob`; `plan.md:4`, `doc.md:4`, `troubleshoot.md:4` → `allowed-tools: Read, Write, Grep, Glob, Bash, Task`. For **commands** this is complete and safe — `allowed-tools` is first-turn convenience only. For **agents** `tools:` is a hard allowlist, so removal makes MCP genuinely unavailable inside those two subagents — already the de-facto state; the durable fix is to let the orchestrating command do the lookups and pass results in, or ship a documented `.mcp.json`. Prose bodies (`dependency-mapper.md:182-198`, `integration-scanner.md:150-168`, `plan.md:303-312`, `troubleshoot.md:285-292`) are model-facing instructions, not identifiers — F32's territory.

**Verify.**
```
grep -rnE '^(tools|allowed-tools):.*(ref_search_documentation|ref_read_url|web_search_exa|get_code_context_exa|perplexity_)' agents/ commands/   # zero
bash tests/layer1-config-wiring.sh
```

---

### F22 — Hard-reset guard denies while claiming to warn

**Evidence.** `.claude-plugin/plugin.json:49` matches `git\s+reset\s+--hard`, prints `[Toque] WARNING: …`, and `exit 2` — on PreToolUse that is a hard **deny**, mislabeled. `scripts/tq-git-guard.sh:22-25` is worse: it asks "Are you sure?" then exits 2, a question with no answering mechanism. `tests/layer2-hook-simulation.sh:212-218` codifies the contradiction (comment "SHOULD BLOCK", asserts exit 2 and stderr contains "WARNING", named "Blocks hard reset (exit 2)"). The suite passes 15/15 at HEAD, so this test **will fail the moment the hook is corrected**. Live confirmation: an unrelated read-only verification command was denied by this hook merely for containing the force-push pattern. Docs disagree: `GUIDE.md:609` and `METHODOLOGY.md:861`/`:889` say BLOCKED while `GUIDE.md:613` quotes WARNING.

**Fix.** Replace the deny branch with a PreToolUse `ask` decision — print `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"…"}}` to **stdout** and `exit 0`. Leave force-push and DB-deploy at exit 2 with BLOCKED wording. Apply the same to `tq-git-guard.sh:22-25`. Rewrite `layer2` Test 5 (212-218) to assert exit 0 plus the ask decision. Update `GUIDE.md:607-613`, `:151`, `METHODOLOGY.md:861`/`:889`. Scope boundary: `METHODOLOGY.md:1782` rule 4 ("STOP HOOKS MUST EXIT 0") is unaffected — this is PreToolUse.

**Verify.**
```
printf '{"tool_input":{"command":"git reset --hard HEAD~1"}}' | bash scripts/tq-git-guard.sh > /tmp/o; echo "exit=$?"
jq -e '.hookSpecificOutput.permissionDecision=="ask"' /tmp/o
printf '{"tool_input":{"command":"git push --force origin main"}}' | bash scripts/tq-git-guard.sh; echo $?   # 2
```

---

### F23 — Hook logic is inline, single-line, and unlintable

**Evidence.** The entire hooks config is inline at `.claude-plugin/plugin.json:20-101`; no `hooks.json` exists; `grep -c CLAUDE_PLUGIN_ROOT .claude-plugin/plugin.json` is 0 despite a purpose-built `scripts/`. Every handler embeds the `'"'"'` quadruple-escape sequence inside a single-quoted `bash -c`. **Measurement corrected:** handler lengths are SessionStart 491, PreToolUse/Write 550, PreToolUse/Bash 859, PostToolUse/Write 761, PostToolUse/Bash 725, Stop 572, PreCompact 215 — max **859**, not ~1,100 (~28% inflated). The array-index coupling claim is exact: `tests/layer2-hook-simulation.sh:48-53` extracts via `.hooks.PreToolUse[0].hooks[0].command`, binding test identity to JSON array position.

**Fix.** Identical mechanical change to F06 — **one edit, not two**. Create `hooks/hooks.json` with exec-form handlers; delete `plugin.json:20-101`. F23-specific additions: (a) add `shellcheck scripts/*.sh` to `tests/run-all.sh` or CI, since lintability is the stated benefit; (b) update `METHODOLOGY.md:1830` (cites plugin.json lines 49/61/71/83) and `METHODOLOGY.md:1802-1807` (deep-links to `plugin.json#L46`/`#L36`/`#L58`/`#L68`/`#L77`) — all seven anchors go stale on deletion. **Never schedule in parallel with F06.**

**Verify.**
```
jq -e '.hooks' .claude-plugin/plugin.json   # non-zero
jq -e . hooks/hooks.json                     # 0
grep -c 'bash -c' hooks/hooks.json           # 0
grep -n 'plugin.json#L' METHODOLOGY.md       # no hook anchors
shellcheck scripts/*.sh
```

---

### F24 — Hook input parser fails open on quoted payloads

**Evidence.** Fallback pattern at `plugin.json:39`, `:49`, `:61`, `:71`, `:83` and at `tq-git-guard.sh:9`, `tq-migration-guard.sh:6`, `tq-track-change.sh:7-8`, `tq-track-test.sh:7-8`, `tq-session-stop.sh:8`, `tq-subagent-stop.sh:12`. **Executed:** input `{"tool_input":{"command":"git commit -m \"wip\" && git push --force"}}` through `grep -o '"command":"[^"]*"' | head -1 | sed …` yields literally `git commit -m \` — which does **not** match `git\s+push.*--force`, so the hook reaches `exit 0` and permits the force push. Same result for the hard-reset variant. Contradicts the plugin's own rule at `METHODOLOGY.md:1769-1770` ("NEVER FAIL OPEN"), self-acknowledged at `:1809`. **Sequencing nuance:** today this path is reachable only when jq is absent (`plugin.json:49` tries jq first) and jq is present on this host. If F06/F23 wire the current scripts as-is, grep becomes the **only** path and the hole becomes unconditional.

**Fix.** Add a shared preamble to the three **blocking** guards (git, migration, DB-deploy — the last lives inside tq-git-guard.sh): export PATH; try `jq -r '.tool_input.command // empty'`; if jq produced a value, proceed; if jq is unavailable, detect lossy extraction (payload contains an escaped quote, OR grep result empty while raw input contains `"command":`) and `exit 2` with `[Toque] BLOCKED: cannot parse hook input reliably (jq not installed)`. Keep the **informational** hooks (track-change, track-test, session-stop, subagent-stop) fail-open — they gate nothing and blocking a session over a counter is worse. Add layer2 regression tests for both branches. Update `METHODOLOGY.md:1813-1830` to document the fail-closed rule.

**Verify.**
```
printf '{"tool_input":{"command":"git commit -m \\"wip\\" && git push --force"}}' | bash scripts/tq-git-guard.sh; echo $?   # 2
PATH=/usr/bin:/bin bash -c 'printf ... | bash scripts/tq-git-guard.sh'   # 2, stderr matches "cannot parse"
```

---

### F25 — Force-push guard blocks the safe alternative it recommends

**Evidence.** Confirmed for **both** implementations by execution. `plugin.json:49` uses `grep -qE "git\s+push.*--force"`; running `echo 'git push --force-with-lease origin main'` through it **matches** → denied. `tq-git-guard.sh:17` uses `…--force\b`; the `\b` does not help since the boundary between `e` and `-` satisfies it — also **matches**. `tq-git-guard.sh:18` then advises "Use --force-with-lease if needed" — advice for a command the same regex blocks, i.e. an unexitable retry loop for an agent that follows it. No existing test covers `--force-with-lease` (`layer2:204-210` tests only plain `--force`).

**Fix.** Insert an explicit allow-check ahead of the deny rather than tightening the regex: `grep -qE 'git\s+push[^|;&]*--force-with-lease'` → skip the deny. Prefer the scoped `[^|;&]*` form so a `--force-with-lease` substring elsewhere in a compound command cannot launder a real `--force`. Correct the message to "git push --force is not allowed. Use --force-with-lease instead (permitted)." Apply to whichever copy survives F06/F23. Add two layer2 tests next to Test 4.

**Verify.**
```
printf '{"tool_input":{"command":"git push --force-with-lease origin main"}}' | bash scripts/tq-git-guard.sh; echo $?          # 0
printf '{"tool_input":{"command":"git push --force origin main"}}' | bash scripts/tq-git-guard.sh; echo $?                     # 2
printf '{"tool_input":{"command":"git push --force origin main # --force-with-lease"}}' | bash scripts/tq-git-guard.sh; echo $? # 2
```

---

### F26 — Hook output is written to streams that are discarded

**Evidence.** Stop (`plugin.json:83`) ends with bare text on stdout + exit 0, on an event where non-JSON stdout is discarded. PreCompact (`plugin.json:95`) same — and delivering the resume instruction is that hook's entire purpose. SessionStart (`plugin.json:27`) sends the jq-missing warning to `>&2` then exits 0, suppressing it; its second echo (the "Active plan" line) correctly uses stdout and **is** surfaced, since SessionStart is one of the two events where plain stdout becomes context. Script copies are worse in one case: `tq-session-stop.sh:30` and `:35` write **both** messages to stderr. Docs promise the invisible output: `GUIDE.md:645` quotes the expected line, `:649` claims PreCompact injects plan context.

**Fix.** Convert user-facing output on exit-0 paths to JSON on stdout. `tq-session-stop.sh:30`/`:35` → `printf '{"systemMessage":"[Toque] %s"}\n' "$MSG"`, keeping `exit 0` per `METHODOLOGY.md:1782` rule 4; escape the payload (backslash and double-quote) or build with jq. `tq-pre-compact.sh:13` → a systemMessage carrying plan name, phase, and the resume command. SessionStart: move only the jq warning into JSON — **do not** convert the "Active plan" line, which is legitimately consumed as context; if both are needed, emit one object using `systemMessage` plus `hookSpecificOutput.additionalContext` rather than mixing raw text and JSON on one stream. Add layer2 assertions that each handler's stdout parses as JSON. Fix `GUIDE.md:641-649`.

**Verify.**
```
echo '{"session_changes":4,"total_changes_since_audit":4}' > /tmp/tq-baseline-v26
printf '{"session_id":"v26"}' | bash scripts/tq-session-stop.sh | jq -e '.systemMessage|test("files changed")'
bash scripts/tq-session-stop.sh < /dev/null 2>&1 | grep -c '^\[Toque\]'   # 0
```

---

### F27 — Seven agents reference a skill they cannot load

**Evidence.** `skills/self-audit-knowledge/SKILL.md:3` claims auto-invocation during codebase audits, plan audits, and report generation. All seven citing agents instruct using it but none can: `risk-assessor.md:6` vs `:189`; `dependency-mapper.md:6` vs `:180`; `integration-scanner.md:6` vs `:148`; `feature-scanner.md:6` vs `:131`; `doc-auditor.md:6` vs `:160`; `plan-auditor.md:11` vs `:81`; `plan-scaffolder.md:11` vs `:254`. `grep -rn '^skills:' agents/` returns **zero** matches; no agent lists the `Skill` tool; bodies use the bare name, not the namespaced `toque:self-audit-knowledge`. The mcp-research half also confirmed: `grep -rn 'mcp-research' agents/ commands/` returns zero — absent even from the help.md skills table (`help.md:144-154`).

**Fix.** Per agent: (1) append `Skill` to the tools allowlist, preserving each file's syntax style, folding into the same tools-line rewrite as F02/F07/F21; (2) change every "Reference the self-audit-knowledge skill" to "Invoke the Skill tool with skill name `toque:self-audit-knowledge`" at the seven cited lines. **Preferred alternative if `claude plugin validate` accepts it:** add `skills: ["toque:self-audit-knowledge"]` to frontmatter instead (preloads without granting a new tool). Do **not** ship both. Last resort: inline Sections A–D of the skill (~40 lines) into each body. **Do all four tools-line findings in ONE pass per file.**

**Verify.**
```
grep -rn 'the self-audit-knowledge skill' agents/          # 0
grep -rn 'toque:self-audit-knowledge' agents/ | wc -l  # 7
claude plugin validate ./toque-plugin                   # exit 0
bash tests/layer1-config-wiring.sh                          # frontmatter parse intact
```

---

### F28 — Four skills claim an auto-invocation mechanism that does not exist

**Evidence.** `toque-knowledge/SKILL.md:3`, `governance-knowledge/SKILL.md:3`, `readiness-scoring/SKILL.md:3`, `mcp-research/SKILL.md:3` all assert "Auto-invoked…". A repo-wide grep for all five knowledge-skill names across `commands/` and `agents/` returns only: `help.md:150`/`:152`/`:153`/`:154` (a listing table whose heading at `:144` says "Knowledge Skills (5)" and omits mcp-research entirely), `codebase-audit.md:238` (prose, no invocation), `toque-knowledge/SKILL.md:63` (skill-to-skill cross-reference), and the seven agent-body mentions from F27. Zero commands invoke the Skill tool; the only `${CLAUDE_PLUGIN_ROOT}/skills` reference in `commands/` is `doc.md:16`. Descriptions are also noun-phrase form rather than third-person action form, and "codebase audits" appears as a trigger in both `toque-knowledge:3` and `self-audit-knowledge:3`.

**Fix.** (1) Rewrite each line-3 description: drop "Auto-invoked…", replace with concrete third-person triggers; keep the leading `(toque)` prefix. (2) Make loading deterministic by adding an explicit early instruction to the orchestrating commands — `codebase-audit.md` and `readiness-scan.md` → toque-knowledge + self-audit-knowledge; `readiness-scan.md` → readiness-scoring; `codebase-delta.md`, `codebase-gates.md`, `codebase-security.md`, `codebase-characterize.md` → governance-knowledge. Verify each target's `allowed-tools` includes `Skill`; add where missing. (3) `help.md:144` → "Knowledge Skills (6)" plus an mcp-research row.

**Verify.**
```
grep -rn 'Auto-invoked' skills/                          # 0
grep -rln 'toque:governance-knowledge' commands/     # 4 files
grep -rln 'toque:toque-knowledge' commands/      # 2 files
grep -n 'Knowledge Skills (6)' commands/help.md
```

---

### F29 — Four templates instruct deploying agents that do not exist

**Evidence.** `adr-template.md:49`, `brd-template.md:57`, `prd-template.md:60`, `readme-template.md:42` each say "Deploy the **X-generator** agent with:". `ls agents/` shows 22 files, none named adr/brd/prd/readme-generator, and a repo-wide grep for those four names (excluding `docs/plans/`) hits **only** those four lines — no agent file, no manifest entry, no other caller. The "The agent will:" blocks that follow (`adr:54-61`, `brd:62-67`, `prd:65-70`, `readme:46`) promise steps no shipped component performs. Sibling templates are already correct: `spec-template.md` and `release-notes-template.md` contain no such instruction.

**Fix.** Rewrite inline (option B) — do **not** add four agents, which would inflate the agent count asserted in `README.md:160` and GUIDE and add four more files to keep in sync. Replace each "Deploy the **X-generator** agent with: … The agent will: 1..N" block with a direct second-person instruction list executed by the current conversation, preserving the numbered post-steps verbatim. Apply at `adr:47-61` (→ `docs/adr/ADR-{NNN}-{topic}.md`), `brd:55-67` (→ `docs/brd/{domain}.md`), `prd:58-70` (→ `docs/prd/{domain}/`), `readme:40-46` (→ `{project-path}/README.md`). Word count and step order stay identical.

**Verify.**
```
grep -rn 'adr-generator\|brd-generator\|prd-generator\|readme-generator' skills/ commands/ agents/   # 0
grep -c 'Deploy the' skills/documentation/resources/*.md   # 0 for all six
```

---

### F30 — `/toque:doc` and the `documentation` skill are competing entry points

**Evidence.** `commands/doc.md:2` and `skills/documentation/SKILL.md:3` carry near-identical descriptions, and **both currently register as separate invocable entries** — this session's skill listing shows `toque:doc` AND `toque:documentation`. The collision is observable, not theoretical. The behavioral difference is real: `doc.md:7-13` carries a `<plan_awareness>` block and `doc.md:16` anchors dispatch with `${CLAUDE_PLUGIN_ROOT}`; SKILL.md has neither — its resource links (`:22-27`) are bare relative paths and its dispatch section (`:140-143`) says only "Read the selected resources/*.md template". `GUIDE.md:510` documents the intended single surface. **Overstatement:** "the skill name `documentation` is exactly the overly generic naming pattern the docs warn against" is a judgement call; the substantive defect is the duplicated trigger surface.

**Fix.** Keep `commands/doc.md` as the single entry point — deleting it breaks eight downstream references (`codex-challenge.md:529`, `plan-export.md:400`, `plan.md:1523`, `quick-cleanup.md:350`/`:351`/`:422`/`:423`, `troubleshoot.md:834`, `spec-template.md:203-205`, `SKILL.md:155`). Demote the skill: (1) rewrite `SKILL.md:3` to non-competing reference wording with the trigger keyword list stripped; (2) add `user-invocable: false` **only after** confirming `claude plugin validate` accepts it — if rejected, the stripped description alone is the fix; (3) move `<plan_awareness>` semantics into the skill before `:140` so behavior matches whichever path fires; (4) change `:22-27` relative links to `${CLAUDE_PLUGIN_ROOT}/skills/documentation/resources/<file>` (same class as F16, do it here); (5) correct `help.md:151` and `GUIDE.md:510`.

**Verify.**
```
grep -n 'Triggers on' skills/documentation/SKILL.md        # 0
grep -c 'CLAUDE_PLUGIN_ROOT' skills/documentation/SKILL.md # >= 6
grep -n 'Plan Awareness' skills/documentation/SKILL.md
claude plugin validate ./toque-plugin
```
Post-redeploy the listing must show `toque:doc` but not `toque:documentation` (or the latter with reference-only wording).

---

### F31 — Templates suggest four commands that do not exist

**Evidence.** All seven citations exact. `adr-template.md:12`, `brd-template.md:9`, `prd-template.md:9`, `readme-template.md:9` each read `Run /audit first.`. Chain suggestions: `brd-template.md:77` (`/create-prd`), `prd-template.md:81` (`/create-brd`), `prd-template.md:96` (`/create-adr`). `ls commands/` (17 files) contains no `audit.md`, `create-prd.md`, `create-brd.md`, or `create-adr.md`, and plugin commands are namespaced `/toque:<name>` regardless. This contradicts the parent skill's own whitelist at `SKILL.md:147-165` ("ONLY suggest commands that exist as files… NEVER suggest a command that is not in this list"), which lists `/toque:codebase-audit` (`:157`) and `/toque:doc […]` (`:155`). `spec-template.md:203-208` already uses the correct forms.

**Fix.** Seven literal string replacements, no logic change. `Run /audit first.` → `Run /toque:codebase-audit first.` (×4). `brd:77` → `/toque:doc prd [feature]`. `prd:81` → `/toque:doc brd [domain]`. `prd:96` → `/toque:doc adr [feature topic]`. Every target already appears in the whitelist, so no whitelist edit is needed.

**Verify.**
```
grep -rn 'Run /audit\|/create-prd\|/create-brd\|/create-adr\|/create-readme' skills/   # 0
grep -rn '/toque:codebase-audit' skills/documentation/resources/ | wc -l           # 4
grep -rho '/toque:[a-z-]*' skills/documentation/resources/ | sort -u               # codebase-audit, doc, quick-audit only
```

---

### F32 — `mcp-research` skill hardcodes unqualified, partly nonexistent tool names

**Evidence.** `skills/mcp-research/SKILL.md:82` heads a section "Verified Tool Names (as of 2026-04-03)"; `:83-85` states that a name mismatch simply means the tool is unavailable. The listed names at `:88-89`, `:92-95`, `:98-101` are all unqualified, as is the selection matrix at `:16-26`. **Live check:** connected servers register `mcp__exa__web_search_exa`, `mcp__claude_ai_Exa__web_search_exa`, `mcp__perplexity__perplexity_search`, `mcp__claude_ai_Ref_MCP__ref_search_documentation` — the *same logical tool* under two different server prefixes, so hardcoding any single prefix is also wrong. **Additionally stale on content:** `get_code_context_exa`, `crawling_exa`, and `web_search_advanced_exa` do not exist on either Exa server here (it exposes `web_search_exa` and `web_fetch_exa`). Same defect in the sibling skill at `skills/documentation/SKILL.md:173`/`:176`/`:179`/`:183`/`:184`.

**Fix.** (1) Replace `:83-85` with a **suffix-matching** rule: tools register as `mcp__<server>__<tool>` and the same tool may appear under multiple prefixes; determine availability by matching the tool-name suffix, never by bare-name equality. (2) Rewrite `:87-101` as a two-column "Suffix to match / Example qualified name" table. Drop `crawling_exa` and `web_search_advanced_exa`, or mark them "optional, verify presence before use"; keep `get_code_context_exa` only with the same caveat. (3) Retitle `:82` to "Tool Name Matching" so a dated "verified" claim is not reshipped. (4) Leave the `:16-26` matrix human-readable but add a pointer to the matching rule. (5) Apply the same note to `skills/documentation/SKILL.md:167-186`. **The convention chosen here must match F21 exactly.**

**Verify.**
```
grep -n 'mcp__' skills/mcp-research/SKILL.md | wc -l          # >= 6
grep -n 'Verified Tool Names' skills/mcp-research/SKILL.md    # 0
grep -n 'crawling_exa\|web_search_advanced_exa' skills/mcp-research/SKILL.md   # 0 or "verify presence" only
grep -rho 'mcp__[A-Za-z_]*__[a-z_]*' skills/ agents/ commands/ | sort -u        # one convention
```

---

### F33 — Nine troubleshooting technique files are duplicated and divergent

**Evidence.** All four sub-claims verified by diff. All nine files pair 1:1 between `docs/troubleshooting-techniques/` and `../troubleshooting-skill/resources/techniques/`, and **all nine differ** (changed lines: 01=22, 02=30, 03=22, 04=25, 05=46, 06=34, 07=35, 08=73, 09=27). (1) Phase renumbering: plugin `02:35`/`:86` say "Phase 2 / Root Cause Investigation"; skill copy says "Phase 1 of core methodology / Locate". (2) KB shape: plugin `08:82-102` embeds an inline KB block including `**Plan:**` at `:100`; the skill copy points to `../kb-schema.md` plus a new backward-compatible-fallback section, and `kb-schema.md` has **no Plan field** in Required (`:16-28`) or Optional (`:35-47`). (3) skill `05:44-53` adds a Token column; `:86` uses `unit-tests:not-present` vs plugin `05:84` `unit test (not present)`. (4) Plugin copies retain design-note sections (`02:99-121`, `05:100-108`, `08:112-134`) stripped from the skill. **New evidence:** `commands/troubleshoot.md:747` already uses the **skill's** token format and `:770-778` keys pattern detection on it — so the plugin's own doc copy is stale relative to the plugin itself. The genuine cross-source gap is only the `Plan` field. Also: `grep -rn 'troubleshooting-techniques'` returns **zero** references (dead payload, corroborates F16), and `../troubleshooting-skill` is **not a git repository**, so edits there are outside version control.

**Fix.** Declare the standalone skill canonical for technique **content**, the plugin canonical for the **plan-linkage field**. (A) `git rm -r docs/troubleshooting-techniques/` — nothing references it. If design history must be preserved, move to `docs/design-history/troubleshooting/` with a "DESIGN HISTORY — superseded… do not use as guidance" banner on each file. Choose one; do not leave both live. (B) Add `**Plan:** {plan name, or "standalone"}` to the skill's `kb-schema.md` Optional Fields after line 46. (C) Align `commands/troubleshoot.md:734-753` field casing to kb-schema exactly (`Service / Module`, `Guardrails Missed`, `Guardrails Added`, `Five Whys Depth`, `Recurrence Count`, `Related Incidents`) and update the correlation prose at `:207-210`. Token format already agrees — no change. **Step B writes outside the git repo into an untracked directory: copy to scratchpad first and record the edit in the plan so it is not silently lost.**

**Verify.**
```
ls docs/troubleshooting-techniques 2>&1                    # No such file or directory
grep -rn 'troubleshooting-techniques' --include=*.md --include=*.json --include=*.sh .   # 0
grep -n 'Plan:' ../troubleshooting-skill/resources/kb-schema.md   # matches in Optional block
bash tests/run-all.sh                                       # no new failures vs baseline
```
