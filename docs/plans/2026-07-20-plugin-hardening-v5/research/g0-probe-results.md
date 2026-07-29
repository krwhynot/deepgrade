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

## U6 — NOT SETTLED. The probe could not answer it.

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

**Status: U6 remains OPEN. The CR-1 condition is therefore neither met nor refuted.**

### What settles it — one interactive session, owner-run

```powershell
cd "<scratchpad>\g0-probe"
$saved = $env:PATH
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'nodejs' }) -join ';'
claude --plugin-dir ".\candidate-n"        # INTERACTIVE — no -p
# observe the session start, then /exit
$env:PATH = $saved
```

Record verbatim: any notice text, where it appeared (inline / status line / nowhere), and the owner's
judgment on the CR-1 question — *would a user with no node notice that the safety guards are not
running?*

- **Visible** → CR-1 holds → **lane N selected**, all other clauses already MET.
- **Invisible** → CR-1 **VOID** → G0 records **BLOCKED**: Wave 0 pauses before PHV5-005, Wave 4 does not
  start, new owner CR required per CR-1 §Return path.

## Provisional lane standing

Applying the §3.1.1 outcome table to what **is** settled:

- Row 1 (lane N) requires `(n) fires` **AND** the U6 visibility condition → **first half MET, second half
  UNKNOWN.**
- Row 2 (BLOCKED) requires `(n) fires` but notice invisible → **UNKNOWN.**
- Rows 3–4 are **excluded**: they require (n) to fail, and it did not.

**Therefore the outcome is one of exactly two states — lane N or BLOCKED — and U6 alone decides which.**
Lane B and lane I are empirically eliminated. Recorded as provisional; no lane is selected until U6
closes.

## G1 — POSIX runtime

Unchanged from the Phase-3 record: `WslService` Stopped / StartType Disabled, Docker not installed, no
authenticated POSIX host available. Terminal state **CI_ONLY** (the default). Release notes use the
narrow phrasing: runtime dispatch verified on Windows; suite and schema verified on Windows + Ubuntu via
CI. Wave 8 does not block on this.

## Reproduction

Probe sources: `<scratchpad>/g0-probe/` — four candidate plugins, `run-candidate.ps1`, and the results
form. Not committed, per the matrix G0 row ("probe plugin (scratchpad, not committed)"). The runner
clears any prior marker before each launch so a stale file cannot fake a PASS.
