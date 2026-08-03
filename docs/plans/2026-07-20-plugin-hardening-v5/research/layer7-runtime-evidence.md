# Layer 7 — runtime evidence (PHV5-044)

`tests/layer7-runtime-proof.sh` states the rule this file exists to satisfy: **an unrecorded pass is
not a pass.** Until 2026-08-02 this file had never existed in any commit — `git log --all --
'*layer7-runtime-evidence*'` was empty — while a commit message asserted a 5-passed/0-failed result.
That made the plan's only runtime evidence unauditable testimony, the same class Codex declined to
credit for the mutation harness in the Wave 5 reaudit.

Part 1 is now recorded below, verbatim. **Part 2 is COMPLETE (2026-08-03): the prerequisite and
all nine checks A–I hold observations.** D's dialog was confirmed on a primed redrive, G was
observed on both Stop branches, H was owner-confirmed clean, and I captured the vendor's notice
verbatim on a node-less host. U4 and U5 settle POSITIVE; CR-1's condition is re-confirmed on an
installed copy. F06 and F26 close; F24's Part 2 clauses are met, with full closure still gated on
the U7 floor (PHV5-003, never run) — see the disposition table.

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

**STATUS: RECORDED IN FULL (2026-08-03).** All nine checks A–I below hold observations.

Recording context (applies to every slot dated 2026-08-03): interactive Claude Code session in this
repo — claude CLI 2.1.220, node v24.12.0, Windows 11 Pro 10.0.26200. Checks B–E were driven by the
assistant through its Bash tool at the owner's direction ("execute"); hook responses are quoted
verbatim from the tool results the hooks produced, which is the same interception surface a
user-typed command hits. A and F are surfaces this same session emitted on its own (session start;
an owner-run `/compact`). Copy under test: the plugins INSTALLED from deepgrade-marketplace —
`installed_plugins.json` records gitCommitSha `55dbdeb2fd18e4a50b3ac93e7a66e1f6893c2390` (the
v7.0.0 pin) for both — while the working tree stood at `e6a4e01` with
`git diff v7.0.0 HEAD -- plugins/deepgrade/hooks plugins/deepgrade/scripts
plugins/deepgrade-guard/hooks plugins/deepgrade-guard/scripts` empty, so the pinned copy under test
and HEAD agree byte-for-byte on everything exercised (the caveat below, satisfied).

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

> **Prerequisite RECORDED (2026-08-03).** `deepgrade-guard` was NOT installed when Part 2 began —
> `claude plugin list` showed only `deepgrade@7.0.0` enabled. The catalog was refreshed
> (`claude plugin marketplace update deepgrade-marketplace`) and the guard installed
> (`claude plugin install deepgrade-guard@deepgrade-marketplace` — user scope, 7.0.0,
> gitCommitSha `55dbdeb…`). Handler counts read from the installed manifests rather than the
> `/plugin details` UI: deepgrade 3 (SessionStart, SubagentStop, PreCompact), deepgrade-guard 5
> (PreToolUse `Write|Edit` + `Bash`, PostToolUse `Write|Edit` + `Bash`, Stop `*`) — the
> Hooks (3) / Hooks (5) expectation holds. Notable observed behavior: the guard's hooks went LIVE
> mid-session immediately after the CLI install — check B was intercepted with no
> `/reload-plugins` and no session restart.

### A. SessionStart (F26; settles part of U4)

Start a fresh session in this repo. Expect a line naming the active plan, its phase and status.
Pre-5.0.0 this reported `phase: unknown, status: unknown` against a pretty-printed `status.json`, so a
real phase name is the proof.

```
OBSERVED (verbatim):
Active DeepGrade plan: 2026-07-20-plugin-hardening-v5, phase build (in_progress).
```

Recorded 2026-08-03 — the SessionStart hook's additional-context line exactly as this session
received it at start. Real plan name, real phase, real status: the pre-5.0.0
`phase: unknown, status: unknown` defect is absent. **Settles U4's SessionStart half POSITIVE.**

### B. PreToolUse:Bash — deny (F25)

Run: `git push --force origin main` — expect blocked, with a message naming `--force-with-lease`.
**This also settles part 1's PENDING item.**

```
OBSERVED (verbatim):
PreToolUse:Bash hook error: [node ${CLAUDE_PLUGIN_ROOT}/scripts/dg-git-guard.js]: [DeepGrade] BLOCKED: Force push is not allowed. Use --force-with-lease if you must overwrite a remote branch.
```

Recorded 2026-08-03 — BLOCKED; the command never ran (local and origin `main` were verified
identical beforehand, so even a miss would have been a no-op push). The refusal names
`--force-with-lease`. **Part 1's PENDING item is settled:** the refusal text print mode suppressed
is fully captured interactively. Note: the `hook error:` prefix is the harness's rendering of a
PreToolUse deny to the model — it is not a hook failure and does not count against check H.

### C. PreToolUse:Bash — the SAFE form must be ALLOWED (F25, the inverted defect)

Run: `git push --force-with-lease --dry-run origin main` — expect NOT blocked. Before 5.0.0 this was
denied while bare `-f` was allowed.

```
OBSERVED (verbatim):
Everything up-to-date
```

Recorded 2026-08-03 — NOT blocked; the command executed cleanly. The pre-5.0.0 inversion (safe
form denied while bare `-f` passed) is absent.

### D. PreToolUse:Bash — ask (F22)

Run: `git reset --hard` — expect a CONFIRMATION PROMPT, not a refusal. Record which it was.

```
OBSERVED (verbatim):
HEAD is now at e6a4e01 Merge pull request #8 from krwhynot/cr6-ledger
```

First run recorded 2026-08-03 — NOT a refusal: the command executed (the tree was verified clean
first, so it was harmless). Whether a dialog had surfaced went unnoticed by the owner ("Not sure /
didn't notice"), so the check was REDRIVEN the same day with the owner primed to watch and the
tree freshly committed. The owner's paste of the UI, verbatim:

```
Hook PreToolUse:Bash requires confirmation for this command:
A hard reset discards every uncommitted change in the working tree. Confirm this is intended. [plugin:deepgrade]
```

**A CONFIRMATION PROMPT, not a refusal** — the owner approved it and the command then executed
(`HEAD is now at 292d1db …`). The handler's ask JSON (`dg-git-guard.js:201`,
`permissionDecision: "ask"`) surfaces as a user-visible confirmation carrying the handler's exact
message. One oddity recorded as seen: the UI attributes the hook `[plugin:deepgrade]` although the
handler ships in `deepgrade-guard` — display attribution only (the message text is uniquely
dg-git-guard.js's, and core deepgrade has no PreToolUse handler); noted as a possible
vendor-display or naming follow-up, not a guard defect.

### E. PreToolUse:Bash — quoted mention must be allowed (F24)

Run: `git commit --allow-empty -m "never git push --force"` — expect NOT blocked. This is the defect
that blocked this plan's own commits.

```
OBSERVED (verbatim):
[main d456358] never git push --force
```

Recorded 2026-08-03 — NOT blocked: the commit whose message quotes the guarded string was created.
This is F24's direct check, observed green on the installed copy. (The empty probe commit was
removed afterwards with a mixed reset; `main` returned to `e6a4e01`, clean and in sync.)

### F. PreCompact (settles U5)

Fill the context until compaction triggers, or run `/compact`. Does a DeepGrade line naming the active
plan appear? YES → U5 positive. NO → U5 negative, and the locked §3.1.6 fallback applies: the
compact-resume message moves to the SessionStart `compact` source path, already implemented in
`dg-session-start.js`. Verify by resuming after compaction. If that also fails, F26's PreCompact half
is recorded PARTIAL — never silently dropped.

```
OBSERVED (verbatim):
PreCompact [node ${CLAUDE_PLUGIN_ROOT}/scripts/dg-pre-compact.js] completed successfully: {"systemMessage":"[DeepGrade] Compacting. Active plan: 2026-07-20-plugin-hardening-v5 at phase: build. Resume with /deepgrade:plan 2026-07-20-plugin-hardening-v5"}
```

Recorded 2026-08-03 — the owner ran `/compact` in this session and the line above appeared in
their terminal's command output: a DeepGrade line naming the active plan and its phase.
**U5 settles POSITIVE.** The locked §3.1.6 fallback (compact-resume via the SessionStart `compact`
source) is implemented but NOT needed.

### G. Stop (F26)

Edit a file, then end the turn without running tests. Expect a summary naming the change count and a
nudge that no tests ran. Both messages existed pre-5.0.0 but went to stderr at exit 0 and were never
surfaced to anyone.

```
OBSERVED (verbatim):
[DeepGrade] Session summary: 115 files changed.
```

Recorded 2026-08-03 — the owner saw the line above surface at the end of the recording turn.
**The Stop handler's output IS user-visible** — the exact thing F26 said never happened (pre-5.0.0
both messages went to stderr at exit 0 and were seen by no one).

Two things this observation taught, recorded so the checklist's expectation reads correctly:

- **This check's "a summary AND a nudge" expectation is unsatisfiable as written.**
  `dg-session-stop.js` emits exactly ONE message per stop — `notify()` exits — so a session shows
  the no-tests nudge OR the summary, never both. The expectation predates reading the one-message
  design.
- **The summary branch (not the nudge) was the CORRECT branch here:** the recording turn ran
  `bash tests/layer7-runtime-proof.sh --manual`, which matches the test tracker's
  `/\bbash\s+tests\/layer\d/` pattern, so a `dg-test-<session>` marker existed and the session
  genuinely counted as having run a suite script. The count (115) is the session-cumulative
  change tracker across the whole day's session, not the single turn.

Nudge branch: the session's `dg-test-*` marker was then deliberately removed and the file edited
again, staging the no-tests branch for the next turn boundary.

```
NUDGE BRANCH OBSERVED (verbatim):
[DeepGrade] 118 files changed this session but no test run was detected. Run the suite before finishing.
```

Recorded 2026-08-03 — after the session's `dg-test-*` marker was cleared and further recording
edits were made, the next turn boundary produced the line above in the owner's UI. **Both Stop
branches are now user-observed live.** The count moving 115 → 118 across the two observations
confirms both branches read the same session-cumulative change counter.

### H. Zero hook errors on a healthy host

Through all of the above, no "hook error" notice should appear. **This is the acceptance criterion for
the whole wave.**

```
OBSERVED (verbatim):
1 did not notice any errors
```

Recorded 2026-08-03 — the owner's answer ("1" indexes the H item in the closing question list),
given AFTER the full run: prerequisite, A–G including the D redrive and both Stop branches, plus
the supplementary surfaces (ask-on-unparseable, change-tracker notice). No hook-failure notice
was observed in the owner's UI. The assistant side corroborates: across SessionStart, PreCompact,
every PreToolUse:Bash evaluation (denies, asks and allows) and the Write|Edit trackers, no hook
FAILURE appeared in any tool result (check B's `hook error:` prefix is the deny rendering, not a
failure). **The wave's acceptance criterion holds on this host.**

### I. Node-less installed copy (CR-1's condition, lane N's honest limit)

In a shell with node removed from PATH, start an interactive session:

```
PATH=$(echo "$PATH" | tr ':' '\n' | grep -v node | paste -sd:) claude
```

Expect the vendor's own hook-error notice — the guards cannot spawn, and that notice is the only
in-product signal. Record it VERBATIM; CR-1's acceptance is that it is user-visible and names the cause.

```
OBSERVED (verbatim):
SessionStart:startup hook error
Failed with non-blocking status code: Error occurred while executing hook command: Executable not found in $PATH: "node"
```

Recorded 2026-08-03 — owner ran the node-less shell (PowerShell equivalent:
`$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'node' }) -join ';'`, with
`node --version` confirmed failing) and launched the installed copy interactively in this repo.
The notice appeared immediately at session start: **user-visible, names the failing event
(SessionStart:startup), the severity (non-blocking — the session continues with the guards dead,
lane N's honest limit), and the exact cause (node not on PATH). CR-1's acceptance condition is
RE-CONFIRMED on an installed copy.**

One discrepancy recorded, not settled: an earlier node-less launch from the PARENT directory
(`~\Projects\plugin`, not this repo) started with NO notice visible in the owner's paste. Most
plausible explanation is folder-trust gating (hooks not executed in a directory the owner had not
previously trusted), which would mean no hook fired and there was nothing to fail; paste truncation
is not excluded. In the deployment-relevant context — this repo — the notice fires and is correct.

---

## Supplementary runtime observations (2026-08-03, same session)

Not on the checklist, but observed surfacing while recording it — each a runtime surface no
automated layer proves:

- **The git guard's ask-on-unparseable branch** (§3.1.6: never DENY on something unparsed — ask)
  surfaced on a heredoc commit (`git commit -m "$(cat <<'EOF' …)"`, whose `$( )` the guard cannot
  evaluate). Owner's paste, verbatim:

  ```
  Hook PreToolUse:Bash requires confirmation for this command:
  This command contains a shell construct the guard cannot evaluate (a variable, a substitution, or a nested shell), so its real effect is unknown. Confirm it does not force-push or deploy to a remote database. [plugin:deepgrade]
  ```

  The owner approved and the commit ran — ask, not deny, exactly as locked. (Practical corollary:
  every heredoc-style commit in a guarded session asks for confirmation.)

- **The change tracker's threshold notice** (`dg-track-change.js:74`) surfaced after an edit:

  ```
  PostToolUse:Edit says: [DeepGrade] 118 files changed since the last audit. Consider /deepgrade:codebase-delta.
  ```

- The `[plugin:deepgrade]` attribution label appears on every guard dialog although these handlers
  ship in `deepgrade-guard` (see check D's note) — display attribution, tracked as a possible
  follow-up, not a defect in the handlers.

---

## Disposition

| Finding | State | Moves when |
|---|---|---|
| F06 | **MET — evidence recorded 2026-08-03; CLOSED in status.json** | — all of A–I hold observations; the installed-copy clause (the I in its U,R,I class) is exactly what Part 2 ran |
| F24 | **Part 2 clauses MET (2026-08-03); stays PARTIAL in status.json** | — E observed allowed, B observed blocked naming `--force-with-lease` (settling part 1's pending item), H settles "runtime-verified locally", the hosted ubuntu+windows CI matrix exists (suite.yml, PHV5-005), and the corpus carries the `--force-with-lease` allowed case. The single remaining unmet clause is "runtime-verified at the U7 floor": the floor does not exist because PHV5-003 never ran |
| F26 | **MET — evidence recorded 2026-08-03; CLOSED in status.json** | — A (SessionStart), F (PreCompact) and G (both Stop branches) all user-observed surfacing |
| U4 | **settled POSITIVE** (2026-08-03, check A) | — real plan, phase and status at session start |
| U5 | **settled POSITIVE** (2026-08-03, check F) | — PreCompact line surfaced on `/compact`; §3.1.6 fallback not needed |
| CR-1 condition | **RE-CONFIRMED on an installed copy** (2026-08-03, check I) | — vendor notice user-visible, names event, severity and cause |
