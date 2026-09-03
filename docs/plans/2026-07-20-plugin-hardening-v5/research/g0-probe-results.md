# G0 Launcher Probe — Results

**Ticket:** PHV5-004 · **Gates:** G0 (candidate matrix **SETTLED**), U6 (**NOT SETTLED** — see below), G1
**Date:** 2026-07-29 · **Repo HEAD:** `a7e212c` · **Claude Code:** 2.1.216 · **Node:** v24.12.0
**Host:** Windows 11 Pro 26200, Git for Windows installed, `core.autocrlf=true`
**Probe plugins:** scratchpad only, never committed (per matrix G0 row)

## Launch-context validity

Every run launched from **PowerShell** (parent process `powershell.exe`), never Git Bash. The runner
asserts this and aborts if `bash` resolves, because resolvability is a property of the *inherited
environment*, not the machine — the round-6 reviewer's contrary reading came from a Git Bash-derived
process. Recorded at each run:

- `bash on PATH: False` ← premise holds, re-confirmed 2026-07-29
- `node on PATH: True`

The probe scripts were also executed standalone first, so a script defect could not be mistaken for a
launcher defect.

## Candidate matrix — SETTLED

| # | Candidate | Form | Marker | Interpreter actually used |
|---|-----------|------|:------:|---------------------------|
| n | node exec | `"command":"node","args":["${CLAUDE_PLUGIN_ROOT}/scripts/probe.js"]` | **FIRED** | `C:\Program Files\nodejs\node.exe` |
| n′ | node exec, **node hidden from PATH** | same | **did not fire** | — (spawn failed) |
| s | shell form | `"command":"bash \"${CLAUDE_PLUGIN_ROOT}/scripts/probe.sh\" s"` | **FIRED** | `/usr/bin/bash` 5.2.37 (Git Bash) |
| b | bash exec | `"command":"bash","args":[...]` | **did not fire** | — (spawn failed) |
| d | absolute path *(diagnostic)* | `"command":"C:/Program Files/Git/bin/bash.exe"` | FIRED | `/usr/bin/bash` 5.2.37 |

### Findings

1. **Lane N's launcher works.** Candidate (n) fired, and `${CLAUDE_PLUGIN_ROOT}` substituted correctly
   in `args` — incidentally confirming two U7 relied-upon behaviors (exec-form args, path substitution).

2. **§3.1.1's inverted-reasoning correction is empirically confirmed.** The plan states shell form rides
   Claude Code's own Git Bash detection while *exec-form bash bypasses it and resolves from the PATH that
   lacks `bash`* — making exec-form-bash the **more** fragile choice, correcting v1's opposite claim.
   Observed exactly: **(s) fired while (b) did not**, from an identical PowerShell context.

3. **The diagnostic did its job.** (d) fired while (b) failed, isolating the cause: the exec-form
   *mechanism* is sound; (b)'s failure is purely `bash` PATH resolution. **(d) is recorded NOT-PASS by
   rule** — it hardcodes `C:/Program Files/Git/bin/bash.exe`, failing distributability clause 2 by
   construction. This is the matrix's explicit negative case.

### Distributability clause (§3.1.1) — candidate (n)

| Clause | Status |
|--------|--------|
| 1. Marker fired from a PowerShell launch | **MET** |
| 2. Committed hook config contains no host-specific path | **MET** — `node` + `${CLAUDE_PLUGIN_ROOT}` only |
| 3. Every required runtime vendor-guaranteed **or** declared prerequisite with first-use check | **MET as designed** — node declared a prerequisite (§3.6), first-use check per §3.1.6 |

## U6 — SETTLED 2026-07-29. Notice is user-visible. CR-1 condition MET.

**Owner-run interactive session, node hidden from PATH.** Verbatim on-screen output:

```
 ‼ 1 MCP server needs authentication · run /mcp
SessionStart:startup hook error
Failed with non-blocking status code: Error occurred while executing hook command: Executable not found in $PATH: "node"
```

*(Line 1 is unrelated pre-existing session noise, retained verbatim per the provenance convention.)*

**Assessment against the CR-1 condition** — *would a user with no node notice the guards are not
running?* **YES.** The notice is unambiguous on all three counts that matter:

1. It appears **inline in the session**, not only in a log.
2. It **names the event** (`SessionStart:startup hook error`).
3. It **names the exact cause** (`Executable not found in $PATH: "node"`) — a user can act on it
   without diagnosis.

This is a *stronger* signal than CR-1 was willing to settle for. CR-1 accepted a weaker
vendor-generic notice; the actual notice identifies the missing executable by name.

**→ CR-1 stands. Lane N is selectable. G0 terminal state: lane N.**

### Qualification — recorded, not glossed

The notice is visible **in interactive sessions only**. `claude -p` print mode suppresses it, proven
by the control below. So the §3.1.6 honest spawn limit narrows to: **visible interactively, silent in
headless / print / CI runs.** Consequences carried forward:

- The Wave 0 CI matrix must **not** rely on this notice as a signal — CI runs headless. This is
  consistent with the already-locked §10.3 boundary (lane N's node-absent case is *local runtime
  evidence, never a CI assertion*), and is now empirically grounded rather than merely stipulated.
- 4c's node-less installed-copy proof must be run **interactively** to observe the notice.

## Superseded: why the automated probe alone could not answer this

**What was observed:** in all node-less and bash-exec runs, the hook did not fire and Claude Code
printed **nothing** — exit 0, output limited to the model's reply. stderr was captured (`2>&1`), so
this is not a capture gap.

**Why that is NOT evidence the notice is invisible:** every run used `claude -p` (print mode). A control
run proves print mode suppresses diagnostics wholesale:

| Run | node | `--debug` | Hook fired? | Diagnostic output |
|-----|:----:|:---------:|:-----------:|-------------------|
| control | present | yes | **yes** | **none — 1 line, the model reply only** |
| test | hidden | yes | no | none |

Since `--debug` emits nothing **even when everything works**, absence of a notice in `-p` mode carries
no information about what the interactive TUI shows. Concluding "invisible" from this data would be a
false negative of exactly the kind the plan's evidence conventions exist to prevent.

**This is why the headless probe was reported inconclusive rather than negative.** Had the `-p` silence
been read as "the notice is invisible," G0 would have been wrongly recorded **BLOCKED**, voiding CR-1
and halting Wave 4 on an artifact of print mode. The control run is what separated *absence of evidence*
from *evidence of absence*, and the interactive run then produced the opposite conclusion.

## G0 verdict — SETTLED

Applying the §3.1.1 outcome table in order; the first matching row wins:

| Outcome | Condition | Result |
|---------|-----------|--------|
| **lane N** | (n) fires **and** U6 notice user-visible | **✅ MATCHED — both proven** |
| BLOCKED | (n) fires but notice invisible | not matched (notice is visible) |
| lane B | (n) fails; (s) or (b) fires | not reached ((n) fired) |
| lane I | no form fires | not reached |

### SELECTED LANE: **N — node-canonical**

- Guards become `scripts/tq-*.js`, parsed with native `JSON.parse` — the entire jq debate dissolves
  rather than being mitigated (F24's fail-open hole and round 3's DoS objection both disappear).
- No executable-bit problem (`node script.js` needs no `+x`), and F23's escaping/CRLF/unlintability
  substance goes away.
- `node` is declared a prerequisite (§3.6) with the §3.1.6 first-use check; the node-less state is
  **honest degradation**, and its signal is now empirically characterized above.
- Lane B is **viable but not selected** — (s) fired, so the fallback is real if lane N is ever
  abandoned. Lane I is not needed.

**Wave 4 is unblocked.** Wave 0 proceeds to its CI-enable step (PHV5-005).

## G1 — POSIX runtime

Unchanged from the Phase-3 record: `WslService` Stopped / StartType Disabled, Docker not installed, no
authenticated POSIX host available. Terminal state **CI_ONLY** (the default). Release notes use the
narrow phrasing: runtime dispatch verified on Windows; suite and schema verified on Windows + Ubuntu via
CI. Wave 8 does not block on this.

## Reproduction

Probe sources: `<scratchpad>/g0-probe/` — four candidate plugins, `run-candidate.ps1`, and the results
form. Not committed, per the matrix G0 row ("probe plugin (scratchpad, not committed)"). The runner
clears any prior marker before each launch so a stale file cannot fake a PASS.
