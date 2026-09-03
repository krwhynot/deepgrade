# U7 — empirical Claude Code compatibility floor (PHV5-003)

§3.6's execution model, followed as pinned: one-time local discovery, candidate interval
bounded below by the oldest hooks-folder-capable version (~2.1.140 per vendor docs) and above
by the local current CLI, ≤8 probes by bisection, each candidate installed **isolated**
(`npm i --prefix <sandbox>` — the 2.1.14x-era npm package downloads its native binary into its
own package `bin/`, so nothing touches the live CLI), probed with `CLAUDE_CONFIG_DIR` pointing
at a per-version scratch config.

**STATUS: PARTIAL (2026-08-03).** The two authentication-free behaviors are fully bisected; the
six dispatch behaviors (authenticated session required) have not yet run. Per §3.6 the dispatch
evidence is local, mandatory, and lands in this file before a floor is declared. **Candidate
floor from the auth-free half: 2.1.145.** The declared floor is the lowest version passing ALL
eight behaviors, so it can only be ≥ 2.1.145.

## Scope refresh (2026-08-03, post-split)

Behavior 8 was pinned in v9 as "pinned **GitHub source object** resolution". The catalog moved
to **`git-subdir` sources with explicit https URLs** after the 7.0.0 install verification
(PR #3), so behavior 8 is probed as what users actually install today: `plugin marketplace add
krwhynot/toque` followed by `plugin install toque@toque-marketplace`, verified by
the scratch registry recording the current pin's `gitCommitSha`
(`18490fbb3351ea87927d157893db872b0b1b414b`, the v7.1.0 release commit). The v9 rule carries
over unchanged: a floor that validates hooks but cannot install the pinned source is not a floor.

## Candidate interval

`npm view @anthropic-ai/claude-code versions` on 2026-08-03: **71 installable versions** in
[2.1.140 … 2.1.220], list captured at probe time. Local current: 2.1.220.

## Probe ladder — auth-free behaviors (2026-08-03)

B5 = `claude plugin validate --strict` (root marketplace + all four plugin dirs, replicating
the CI invocation). B8 = pinned git-subdir catalog install into an isolated config.

| Probe | Version | B5 validate --strict | B8 pinned install | Verdict |
|---|---|---|---|---|
| 1 | 2.1.140 | **FAIL** — `error: unknown option '--strict'` | not reached | below floor |
| 5 | 2.1.144 | **FAIL** — `error: unknown option '--strict'` | PASS (sha `18490fb` recorded) | below floor |
| 7 | 2.1.145 | PASS | PASS | **lowest auth-free pass** |
| 6 | 2.1.146 | PASS | PASS | pass |
| 4 | 2.1.148 | PASS | PASS | pass |
| 3 | 2.1.159 | PASS | PASS | pass |
| 2 | 2.1.179 | PASS | PASS | pass |
| — | 2.1.220 | PASS (CI, every run) | PASS (live install verification, 2026-08-03) | current |

Seven probes; §3.6's bound was ≤8. The capability split is clean and monotonic in the probed
set: `--strict` appears exactly at 2.1.145; git-subdir pinned installation already works at
2.1.144 (its introduction is below the probed interval's failing edge and was not chased —
2.1.144 is already below floor on B5, so its B8 pass cannot move the answer).

Representative verbatim outputs (2.1.145):

```
version: 2.1.145 (Claude Code)
validate root: ✔ Validation passed
mkt add: ✔ Successfully added marketplace: toque-marketplace (declared in user settings)
install: Installing plugin "toque@toque-marketplace"...✔ Successfully installed plugin: toque@toque-marketplace (scope: user)
VERDICT 2.1.145 B5:PASS B8:PASS
```

And the failing edge (2.1.144):

```
validate root: error: unknown option '--strict'
```

## Dispatch behaviors — NOT YET RUN

The remaining six behaviors need an authenticated session on the candidate floor version:

1. hooks-folder precedence (hooks/hooks.json wins over a manifest hooks entry)
2. exec-form `args`
3. `${CLAUDE_PLUGIN_ROOT}` substitution
4. structured hook output (`systemMessage`)
6. explicit `shell: powershell` selection
7. parallel matching-hook execution

Behaviors 2, 3 and 4 are exercised by the shipped hooks themselves and can be driven
layer-7-style (nested `-p` session, `--plugin-dir`, marker side effects — print mode suppresses
notices but not dispatch, which is what these measure). Behaviors 1, 6 and 7 need a small
purpose-built probe plugin carrying deliberately conflicting/parallel/powershell hook
definitions. Blocked on the owner's authentication decision for sandboxed old-CLI sessions;
credential copying into scratch configs remains refused by default.

## Disposition — DESCOPED by CR-7 (owner-ratified 2026-08-03)

| Item | State |
|---|---|
| Auth-free floor (B5+B8) | **2.1.145** — bisected, 7 probes, edges verbatim above; kept as permanent factual record |
| Dispatch behaviors 1–4, 6–7 | **DELIBERATELY NOT RUN** — descoped by CR-7 (users live on auto-updated current; the probed edge measures dev tooling) |
| Declared floor | **NONE, by decision** — CR-7 replaces the floor clause with current-version verification (CI matrix + release-time local runtime evidence) |
| F24's U7-floor clause | **CLOSED via CR-7** — replacing clause satisfied by check H (`layer7-runtime-evidence.md`) and the green hosted CI matrix |
| CI floor job (§10.3) | **not built, by the same CR** — the existing current-version ubuntu+windows matrix is the verification that matches reality |
