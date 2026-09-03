# Test Suite Baseline — Toque Plugin

**Date:** 2026-07-20
**Host:** Windows 11 Pro 26200, Git Bash, jq 1.8.1, node v24.12.0
**Repo:** `C:/Users/NewAdmin/Projects/plugin/toque-plugin`
**Commit:** `4fb4b644b4f690500e937c91b547d1fd336a6c71`
**Shipped version:** plugin.json `4.31.0`

---

## 1. Safety review (performed before running anything)

All six files were read end to end before execution.

| Script | Writes? | Verdict |
|---|---|---|
| `tests/run-all.sh` | none | Safe — `cd` + dispatch only |
| `tests/layer1-config-wiring.sh` | none | Safe — pure `grep`/`sed`/`jq` reads |
| `tests/layer2-hook-simulation.sh` | `/tmp/tq-*`, `mktemp -d`, `mktemp` | Safe — temp only, `trap cleanup EXIT` |
| `tests/layer3-fixture-lint.sh` | none | Safe — reads fixtures |
| `tests/layer4-behavioral-smoke.sh` | none | Safe — `find`/`grep` only |
| `tests/codex-challenge-test.js` | none | Safe — `readFileSync` only |

**The one item needing real scrutiny was Layer 2**, which does `eval "$hook_cmd"` on strings pulled live out of `plugin.json`. I inspected all four evaluated hooks:

- `PreToolUse[0]` (Write|Edit migration guard) — reads stdin, echoes stderr, `exit 2`. No writes.
- `PreToolUse[1]` (Bash git/db guard) — greps, echoes stderr. No writes.
- `PostToolUse[0]` (change tracker) — writes `/tmp/tq-baseline-$SESSION` only.
- `PostToolUse[1]` (test/build tracker) — writes `/tmp/tq-test-$S`, `/tmp/tq-build-$S` only.

No hook touches a repo path. `rm -rf` in Layer 2 is scoped to a `mktemp -d` result; `rm -f` is scoped to `/tmp/tq-*-test-session-*`. **Cleared to run.**

**Verified post-run:** `git status --porcelain` and `git diff --stat` are identical before and after. The only entry is the untracked `docs/plans/2026-07-20-plugin-hardening-v5/` directory, which pre-existed. **Zero repo files modified.**

---

## 2. Results

```
bash tests/run-all.sh      → exit 1   (Layers run: 4, Layers failed: 1)
node tests/codex-challenge-test.js → exit 0
```

| Layer | Result | Passed | Failed |
|---|---|---|---|
| 1 — Config/Wiring | **FAIL** | 84 | 4 |
| 2 — Hook Simulation | PASS | 15 | 0 |
| 3 — Fixture Lint | PASS | 9 | 0 |
| 4 — Behavioral Smoke | PASS | 7 | 0 |
| codex-challenge-test.js (not wired) | PASS | 41 | 0 |
| **Total** | **1 of 4 layers failing** | **156** | **4** |

### The 4 failing assertions (all Layer 1, all real)

```
[FAIL] Version mismatch: plugin.json=4.31.0 README=4.27.1
[FAIL] Version mismatch: plugin.json=4.31.0 CHANGELOG=4.29.0
[FAIL] Version mismatch: README=4.27.1 CHANGELOG=4.29.0
[FAIL] Command count mismatch: commands/ has 17 files, README says 16
```

**Classification: all four are (a) real defects. None are stale tests. None are Windows artifacts.**

Verified the assertions are reading the right values, not misfiring regexes:

- `README.md:169` → `Current: v4.27.1`
- `CHANGELOG.md:3` → `## 4.29.0 (2026-03-22)` (top entry; no 4.30.0 or 4.31.0 section exists)
- `README.md:46` → `## Commands (16)`; the section contains exactly 16 table rows while `commands/` holds 17 `.md` files.
- The missing command is **`codex-challenge`** — it exists as `commands/codex-challenge.md`, is listed in `help.md`, but has no row in the README Commands table.

These map cleanly onto reference-data **F18** (stale CHANGELOG) and **F19** (stale README).

---

## 3. Windows portability assessment

**No observed failure is a platform artifact.** Layers 2–4 pass cleanly under Git Bash. Two latent portability risks are nevertheless present and worth fixing during hardening:

**(1) CRLF landmine in Layer 3 — currently masked.**
`git config --global core.autocrlf` is `true`, there is **no `.gitattributes`**, and the fixture blobs are stored LF in the object database with `text: unspecified`. A fresh clone on a machine with this config would check out `changed-files.txt` / `ticket-file-map.txt` with CRLF. Layer 3's LINT-11/LINT-12 rely on `cut -f2` tab splitting and `grep -qxF` **exact whole-line** matching — a trailing `\r` breaks both, silently flipping orphan counts and producing bogus pass/fail. It passes today only because this working tree happens to hold LF. Recommend adding `.gitattributes` pinning `tests/fixtures/** text eol=lf`.

**(2) GNU-only coreutils.** `layer1-config-wiring.sh:145` uses `head -n -1`, which is GNU-specific. Fine under Git Bash, would break on macOS/BSD.

---

## 4. Coverage against the 33 in-scope findings

Source: `research/reference-data.json` — 33 in-scope (1 critical, 5 high, 26 medium/low), 65 unique confirmed, audited at commit `4fb4b64`.

### CAUGHT — 2 of 33 (~6%)

| ID | Sev | How |
|---|---|---|
| **F18** | medium | Layer 1 version-consistency → `plugin.json=4.31.0 CHANGELOG=4.29.0` |
| **F19** | medium | Layer 1 → version mismatch + command count 17 vs 16 |

**F19 is only partially caught.** The finding also cites a stale skills count: `README.md:161` claims **5 skills** while `skills/` contains **6** directories. **No test asserts skill count** — Layer 1 only checks that each skill dir has an entry file. That half of F19 passes silently.

### ENSHRINED — tests that assert the defect as correct behavior

These will **break when the defect is fixed**, and must be updated as part of hardening:

- **F22** (`git reset --hard` "WARNING" actually hard-blocks). Layer 2 Test 5 explicitly asserts `HOOK_EXIT -eq 2` *and* stderr containing `"WARNING"` — it locks in the exact exit-2-while-saying-WARNING contradiction the finding reports. Fixing F22 turns Layer 2 red.
- **F23** (hooks should move to `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` scripts). Layer 2 extracts hooks by **positional index** (`.hooks.PreToolUse[0]`, `[1]`, …) directly from inline `plugin.json` one-liners. Any migration away from inline one-liners makes Layer 2 exit `FATAL: Failed to extract hook command`. The test harness is structurally welded to the architecture F23 wants to remove.

### BLIND — 31 of 33

Including **the sole critical (F01) and all five highs (F02–F06)**.

#### Blind class 1 — Name collisions (F01, F17, F30)

Layer 1 and Layer 4 verify a `name:` key *exists*; neither checks uniqueness nor filename↔name agreement. Confirmed by direct inspection:

```
duplicate frontmatter name:  report-generator
  agents/toque-report-generator.md  → name: report-generator
  agents/readiness-report-generator.md  → name: report-generator
```

That is F01 (critical — one agent silently never loads), and **both files currently emit `[PASS]`**.

Seven filename↔frontmatter mismatches (F17), all passing today:

```
budget-scanner            → context-budget-scanner
context-scanner           → context-file-scanner
toque-report-generator→ report-generator
doc-auditor               → documentation-auditor
entry-scanner             → entry-point-scanner
feedback-scanner          → feedback-loop-scanner
readiness-report-generator→ report-generator
```

Layer 1's cross-reference block (7a) is hardcoded to **2 of 22 agents** (`plan-scaffolder`, `plan-auditor`) and matches on *filename*, so it cannot see this.

#### Blind class 2 — Phantom command/agent references (F11, F29, F31)

Coverage is **one-directional**: `help.md` → `commands/*.md`. There is no reverse check, and `templates/`, `resources/`, and `skills/` are **never scanned by any test** (0 references across all test files). Live grep across those trees:

```
86 × /audit          3 × /ai-readiness-scan     3 × /ai-readiness-generate
 1 × /create-prd     1 × /create-brd            1 × /create-adr
```

None of these commands exist under the plugin namespace. All invisible to the suite.

Layer 4's B4 "Command-Agent Cross References" is **vestigial**: its `while` loop computes `AGENT_REFS` and `AGENT_NAMES` and then discards both — the loop body contains no assertion. Real coverage is two hardcoded pairs. This is precisely the check that would catch F29 (resource templates deploying four non-existent agents).

#### Blind class 3 — Tool-allowlist vs instruction mismatches (F02, F03, F07, F21, F27)

**No test parses `tools:` or `allowed-tools:` at all** — zero references in any test file. Confirmed live: 15 agents have no `Write` in their allowlist, including `doc-auditor` (`Read, Grep, Glob`) and `integration-scanner` (`Read, Grep, Glob, ref_search_documentation, ref_read_url`) — both of which F02 reports as unable to execute their own documented workflow.

Also surfaced while checking, and **not in the 33**: `agents/security-scanner.md` has a malformed nested-array allowlist —

```yaml
tools: [["Read", "Grep", "Glob", "Bash"]]
```

No test validates allowlist *shape*, so this passes.

#### Blind class 4 — Degraded/fallback paths (F24)

Layer 2 **hard-requires jq** (`FATAL: jq is required ... exit 1`). Every guard's `jq`-less branch — roughly half the guard logic, and the branch that runs on any machine without jq — is therefore **never executed by any test**.

I reproduced the F24 fail-open directly. With `jq` unavailable and a quote appearing *before* the trigger token, `grep -o '"command":"[^"]*"'` truncates at the inner quote and the pattern is never seen:

```
D. jq ABSENT, quote BEFORE trigger token  → exit=0   (FAILS OPEN, guard bypassed)
E. jq PRESENT, identical payload          → exit=2   (correctly blocked)
```

A guard that silently stops guarding is exactly the failure the suite should catch, and it is 100% invisible.

#### Blind class 5 — Guard over-blocking (F25)

No negative tests for safer alternatives. Confirmed live — this session's own installed plugin hook blocked my probe:

```
git push --force-with-lease origin main
→ [Toque] BLOCKED: Force push not allowed.
```

`--force-with-lease` matches `git\s+push.*--force`. The scripted guard version explicitly *recommends* it. Layer 2 tests only that force push is blocked and normal push is allowed; nothing asserts that safe variants stay permitted.

#### Blind class 6 — Orphan / unwired assets (F06)

`scripts/` contains 8 shipped guard scripts (`tq-git-guard.sh`, `tq-migration-guard.sh`, `tq-session-start.sh`, …). `grep -c "scripts/" .claude-plugin/plugin.json` → **0**. Nothing is wired; no test notices. `tests/hooks/` is likewise an empty directory.

#### Blind class 7 — Remaining medium/low (F04, F05, F08–F16, F20, F26, F28, F32, F33)

No test reads `GUIDE.md` (F04, F20), executes or lints embedded command bash blocks (F09, F10, F13, F15), measures command file size (F12), checks `disable-model-invocation` (F14 — 0 references in tests), or validates hook stdout/stderr channel semantics (F26).

### Coverage summary

| Severity | In scope | Caught | Blind |
|---|---|---|---|
| critical | 1 | 0 | 1 |
| high | 5 | 0 | 5 |
| medium | 26 | 2 (1 partial) | 24 |
| low | 1 | 0 | 1 |
| **Total** | **33** | **2** | **31** |

---

## 5. Structural gaps in the harness itself

1. **`codex-challenge-test.js` is not wired into `run-all.sh`.** 41 passing assertions never execute in the suite; `run-all.sh` dispatches only layers 1–4. CI would report green without ever running them.
2. **Layer 4 B4 is dead code** (loop computes and discards; only 2 hardcoded pairs assert).
3. **Layer 1 7a is hardcoded** to 2 of 22 agents.
4. **Layer 2 is coupled to inline-hook positional indices**, blocking the F23 refactor.
5. **Layer 4 B1 regex `'/toque:[a-z-]*'`** omits `0-9`, so any command name with a digit would be silently truncated.
6. **No uniqueness, shape, or reverse-reference validation anywhere** — the three defect classes that produced the critical and all five high findings.

---

## 6. Recommended additions (highest value first)

1. Assert agent `name:` uniqueness **and** filename↔`name:` equality → catches F01 (critical) + F17.
2. Parse `tools:`/`allowed-tools:` — validate YAML shape, and cross-check against verbs in the agent body ("write", "spawn", "run") → catches F02, F03, F07, F21 + the `security-scanner` nested-array bug.
3. Reverse reference sweep over `commands/`, `skills/`, `templates/`, `resources/` for `/toque:*`, `/audit`, `/create-*`, and `@agent-name` tokens → catches F11, F29, F31.
4. Run every Layer 2 hook case **twice — with and without jq on PATH** → catches F24.
5. Add negative guard tests: `--force-with-lease` must pass, `--dry-run` variants must pass → catches F25.
6. Assert every script in `scripts/` is referenced by hook config → catches F06.
7. Extend Layer 1 version/count checks to `GUIDE.md` and add a skills-count assertion → catches F20 and the missed half of F19.
8. Wire `codex-challenge-test.js` into `run-all.sh` as Layer 5.
9. Add `.gitattributes` with `tests/fixtures/** text eol=lf` before the CRLF landmine detonates.
