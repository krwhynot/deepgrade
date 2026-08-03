# Layer 7 — runtime evidence (PHV5-044)

`tests/layer7-runtime-proof.sh` states the rule this file exists to satisfy: **an unrecorded pass is
not a pass.** Until 2026-08-02 this file had never existed in any commit — `git log --all --
'*layer7-runtime-evidence*'` was empty — while a commit message asserted a 5-passed/0-failed result.
That made the plan's only runtime evidence unauditable testimony, the same class Codex declined to
credit for the mutation harness in the Wave 5 reaudit.

Part 1 is now recorded below, verbatim. **Part 2 is still NOT RECORDED.** Creating this file does not
close it; each check A–I carries an explicit empty slot, and F06, F24 and F26 stay PARTIAL until those
slots hold observations.

---

## Part 1 — automated (nested session via `--plugin-dir`)

| | |
|---|---|
| **Run date** | 2026-08-02 |
| **Commit** | `df8ac58` (hook code identical to the pinned `9f16277` — `git diff 9f16277 df8ac58 -- hooks/ scripts/` is empty) |
| **Host** | node v24.12.0 · claude CLI 2.1.220 (Claude Code) · Windows 11 Pro 10.0.26200 |
| **Exit status** | 0 |

Verbatim output:

```
=== Layer 7: Runtime Proof (PHV5-044) ===

[PASS] prerequisite: node v24.12.0 on PATH
[PASS] prerequisite: claude CLI 2.1.220 (Claude Code)

--- Part 1: automated (nested session via --plugin-dir) ---
  driving PostToolUse:Write|Edit ...
[PASS] PostToolUse:Write|Edit fired — tracker written to $TMPDIR
  driving PostToolUse:Bash ...
[PASS] PostToolUse:Bash fired — test marker written for 'python -m unittest --help'
  driving PreToolUse:Bash (deny path) ...
[PENDING-OWNER] PreToolUse:Bash: the command did not run (good) but no refusal text was captured — print mode may have suppressed it. Confirm interactively via --manual.
  driving SubagentStop ...
[PASS] SubagentStop fired — entry appended to the plan's troubleshooting log
```

**Summary line reported: `5 passed, 0 failed, 2 pending owner observation`.**

### What the five passes actually are

Stated precisely, because "5 passed" reads as more coverage than it is:

- **2 are prerequisites** (node on PATH, claude CLI on PATH). They prove the harness can run, not that
  anything fired.
- **3 are hook-firing proofs**, and these are the substance: `PostToolUse:Write|Edit`,
  `PostToolUse:Bash`, and `SubagentStop` were each observed firing **by execution** — a side effect
  written to disk — rather than by reading configuration. Every other layer in the suite proves only
  that the configuration is right; a plugin can pass all of them with its safety layer dead.

### What part 1 does NOT establish

- **`PreToolUse:Bash` is PENDING, not passed.** The guarded command did not run, which is the correct
  outcome, but no refusal text was captured — print mode appears to suppress it. Prevention is
  evidenced; the *user-visible refusal* is not. Check B settles it.
- **`SessionStart` and `PreCompact` are unobserved.** Their evidence is a surfaced notice, and U6
  established that `claude -p` suppresses those. They cannot be automated here by construction.
- Nothing here settles **U4** or **U5**.

### Fixed during this ticket — the probe's defect was its own

`PostToolUse:Bash` was originally driven with `pytest --version`. There is no pytest on this host, so
the nested session never ran the command and the probe reported the hook dead. Fed a pytest payload
directly, `dg-track-test.js` wrote the marker correctly — the handler had been right the whole time.
The probe was testing *"will Claude run an absent tool"*, not *"does the hook fire"*. It is now
preconditioned on a runner that exists (`python -m unittest`, `pytest` as fallback) and **fails rather
than skips** when none does, per the Wave 0 rule that a missing prerequisite never silently no-ops.

A false red costs what a false green costs, and from the same root: a test whose subject is not what
its message claims.

---

## Part 2 — owner-observed (interactive session required)

**STATUS: NOT RECORDED.** Every slot below is empty. Do not infer any of them from part 1.

### Prerequisite before running A–I

> **Procedure refreshed 2026-08-03 (post-split, catalog at v7.0.0).** The plugin split (7.0.0)
> moved the hooks under test: the five safety handlers (both PreToolUse, both PostToolUse, Stop)
> now ship in `deepgrade-guard`; `deepgrade` retains SessionStart, SubagentStop and PreCompact.
> Checks B–E and G below therefore exercise `deepgrade-guard`'s handlers; A and F exercise
> `deepgrade`'s. The slots below remain EMPTY — nothing about the observations themselves is
> carried over or inferred. `tests/layer7-runtime-proof.sh --manual` prints this same checklist
> and was retargeted with the split.

```
/plugin marketplace update deepgrade-marketplace
/plugin update deepgrade
/plugin update deepgrade-guard
/reload-plugins
/plugin details deepgrade        -> must report Hooks (3) incl. SubagentStop
/plugin details deepgrade-guard  -> must report Hooks (5)
```

> The catalog pins a GitHub source object (v7.0.0 @ `55dbdeb`), so these commands install
> **from the pinned SHA, not from this working copy**. That is harmless only while hook code is
> byte-identical between the pin and HEAD — it stops being harmless the moment you edit anything
> under `plugins/deepgrade/scripts/`, `plugins/deepgrade-guard/scripts/` or either `hooks/` and
> re-run this checklist. Release (or test via `--plugin-dir` against the working copy) first, or
> the copy under test is not the copy you changed.

### A. SessionStart (F26; settles part of U4)

Start a fresh session in this repo. Expect a line naming the active plan, its phase and status.
Pre-5.0.0 this reported `phase: unknown, status: unknown` against a pretty-printed `status.json`, so a
real phase name is the proof.

```
OBSERVED (verbatim):
```

### B. PreToolUse:Bash — deny (F25)

Run: `git push --force origin main` — expect blocked, with a message naming `--force-with-lease`.
**This also settles part 1's PENDING item.**

```
OBSERVED (verbatim):
```

### C. PreToolUse:Bash — the SAFE form must be ALLOWED (F25, the inverted defect)

Run: `git push --force-with-lease --dry-run origin main` — expect NOT blocked. Before 5.0.0 this was
denied while bare `-f` was allowed.

```
OBSERVED (verbatim):
```

### D. PreToolUse:Bash — ask (F22)

Run: `git reset --hard` — expect a CONFIRMATION PROMPT, not a refusal. Record which it was.

```
OBSERVED (verbatim):
```

### E. PreToolUse:Bash — quoted mention must be allowed (F24)

Run: `git commit --allow-empty -m "never git push --force"` — expect NOT blocked. This is the defect
that blocked this plan's own commits.

```
OBSERVED (verbatim):
```

### F. PreCompact (settles U5)

Fill the context until compaction triggers, or run `/compact`. Does a DeepGrade line naming the active
plan appear? YES → U5 positive. NO → U5 negative, and the locked §3.1.6 fallback applies: the
compact-resume message moves to the SessionStart `compact` source path, already implemented in
`dg-session-start.js`. Verify by resuming after compaction. If that also fails, F26's PreCompact half
is recorded PARTIAL — never silently dropped.

```
OBSERVED (verbatim):
```

### G. Stop (F26)

Edit a file, then end the turn without running tests. Expect a summary naming the change count and a
nudge that no tests ran. Both messages existed pre-5.0.0 but went to stderr at exit 0 and were never
surfaced to anyone.

```
OBSERVED (verbatim):
```

### H. Zero hook errors on a healthy host

Through all of the above, no "hook error" notice should appear. **This is the acceptance criterion for
the whole wave.**

```
OBSERVED (verbatim):
```

### I. Node-less installed copy (CR-1's condition, lane N's honest limit)

In a shell with node removed from PATH, start an interactive session:

```
PATH=$(echo "$PATH" | tr ':' '\n' | grep -v node | paste -sd:) claude
```

Expect the vendor's own hook-error notice — the guards cannot spawn, and that notice is the only
in-product signal. Record it VERBATIM; CR-1's acceptance is that it is user-visible and names the cause.

```
OBSERVED (verbatim):
```

---

## Disposition

| Finding | State | Moves when |
|---|---|---|
| F06 | **PARTIAL** | A–I recorded |
| F24 | **PARTIAL** | A–I recorded (E is the direct check; B settles part 1's pending item) |
| F26 | **PARTIAL** | A, F, G recorded |
| U4 | unsettled | A |
| U5 | unsettled | F |
| CR-1 condition | held on U6's earlier resolution | I re-confirms it on an installed copy |
