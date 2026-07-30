# CR-3 — extend the line-ending policy to lane N's `.js` hook scripts

**Raised:** 2026-07-29, during Wave 4a (PHV5-040/041), commit `cf46aab`
**Raised by:** Claude (optimizer), self-reported on introducing the first `.js` hook
**State: ACCEPTED** — owner ratified 2026-07-29 ("ratify CR-3"). Applied in the same commit as this record.
**Supersedes:** nothing yet. Would extend acceptance-matrix row **A1**, as CR-2 did.

## What changed underneath the locked row

Row A1 and the `.gitattributes` it produced were written when every hook handler was a shell
script. The file says so in its own rationale, verbatim:

> WHY: the reference development host runs core.autocrlf=true. Without these rules a fresh
> clone materializes shell scripts with CRLF, and a CRLF shebang line makes the interpreter
> unresolvable ("/bin/bash^M: bad interpreter"). **The hook guards and the test suite are shell
> scripts**, so this is a silent, host-dependent breakage of the plugin's safety layer.

G0 selected **lane N**, so the surviving hook implementation is `scripts/dg-*.js`. The bolded
sentence is now false, and the policy no longer covers the files it exists to protect:

```
$ git check-attr text eol -- scripts/dg-git-guard.js scripts/dg-git-guard.sh
scripts/dg-git-guard.js: text: unspecified
scripts/dg-git-guard.js: eol: unspecified
scripts/dg-git-guard.sh: text: set
scripts/dg-git-guard.sh: eol: lf
```

`tests/run-hook-corpus.js` is in the same position.

## Requested change

Add to `.gitattributes`:

```
# Lane N ships the hook guards as node scripts (G0, 2026-07-29). The rationale at the top of
# this file was written when they were shell scripts; it applies to these identically.
*.js text eol=lf
```

…and correct the header sentence to say "the hook guards and the test suite are executable
scripts (`.sh` and `.js`)".

## Severity — revised UPWARD after measurement

The PROPOSED text called this "no known runtime failure" and rated it below CR-2. **The
falsifying control run at ratification time contradicts that in one respect and must be recorded
rather than left as originally written.**

Control: clone `HEAD` (before this CR) with `core.autocrlf=true`, the reference host's setting:

```
$ git -c core.autocrlf=true clone -q . /c/t/a
$ file /c/t/a/scripts/dg-git-guard.js /c/t/a/tests/codex-challenge-test.js /c/t/a/scripts/dg-git-guard.sh
scripts/dg-git-guard.js:       Node.js script executable, Unicode text, UTF-8 text, with CRLF line terminators
tests/codex-challenge-test.js: Node.js script executable, Unicode text, UTF-8 text, with CRLF line terminators
scripts/dg-git-guard.sh:       Bourne-Again shell script, ASCII text executable
```

Two things the proposal understated:

1. `file` reports both as **"script executable"** — they carry a shebang and the exec bit, so
   they are not merely data that node happens to read. Direct execution on POSIX is a supported
   shape for them, and it fails with `env: 'node\r': No such file or directory`.
2. **`tests/codex-challenge-test.js` was uncovered too**, and it runs Layer 5's 41 assertions —
   a third of the suite. The proposal framed the exposure as being about hook guards only. A
   CRLF-broken test runner on a fresh POSIX clone takes out Layer 5, which is precisely the
   "silent, host-dependent breakage" the A1 rationale describes.

The `.sh` beside them is clean, which is the whole point: the policy protected the old file class
and silently stopped at the new one.

Severity is therefore **comparable to CR-2's**, not below it. What remains true from the proposal
is that the *shipped hook invocation path* (`node scripts/dg-*.js`, per lane N) is unaffected,
because node tolerates CRLF. The exposure is everything else:

1. Anyone who marks a guard executable and runs it directly on POSIX hits
   `/usr/bin/env: 'node\r': No such file or directory` — the exact failure A1 exists to prevent.
2. Wave 6's determinism requirement (`PHV5-062`: clean clone → regenerate → byte-identical) and
   any future hashing of `scripts/` become host-dependent.
3. The policy file states a rationale that is no longer true of the tree, which is the kind of
   drift the consistency sweep exists to catch and currently cannot see.

None of these is a live defect today. This is raised now because the cost of fixing it is one
line while only two `.js` files exist, and because 4b is about to make these files the plugin's
entire safety layer.

## Alternatives considered

- **`scripts/** text eol=lf` instead of `*.js`** — narrower, but leaves `tests/run-hook-corpus.js`
  and any future tooling uncovered. `*.js` matches the existing `*.sh` line's shape.
- **Do nothing until a failure is observed** — rejected on the same reasoning the owner accepted
  for CR-2: the failure mode is silent and host-dependent, so "wait for it to break" means
  waiting for it to break on someone else's machine.
- **Fix it silently as part of 4a** — rejected. CR-2 established that changing A1's scope is a
  change record, and the protocol is not conditional on the change being small.

## Acceptance if ratified

Same falsifying form CR-2 established — `git ls-files --eol` is **not** sufficient, since it
reports `w/lf` even with no `.gitattributes` present at all:

```
git clone <repo> /tmp/eol-check-js && file /tmp/eol-check-js/scripts/*.js
  -> must NOT report "with CRLF line terminators"
```

Plus a guard asserting the header rationale names both extensions, so the sentence cannot go
stale again the way it just did.

### Acceptance — EXECUTED, both directions

Control at `HEAD` before the fix is quoted under "Severity" above: both `.js` files came out
**with CRLF line terminators**. After the fix, at `ff3edbb`:

```
$ git -c core.autocrlf=true clone -q . /c/t/b
$ file /c/t/b/scripts/*.js /c/t/b/tests/*.js /c/t/b/scripts/dg-git-guard.sh
scripts/dg-git-guard.js:       Node.js script executable, Unicode text, UTF-8 text
tests/codex-challenge-test.js: Node.js script executable, Unicode text, UTF-8 text
tests/run-hook-corpus.js:      Node.js script executable, Unicode text, UTF-8 text
scripts/dg-git-guard.sh:       Bourne-Again shell script, ASCII text executable
```

No CRLF on any of them. The check is falsifying in both directions: it failed before the change
and passes after, on the same command.

The clone was then exercised rather than merely inspected, since "the bytes look right" is a
weaker claim than "it runs":

```
$ cd /c/t/b && bash tests/run-all.sh      -> Layers failed: 0 / Status: ALL PASSED
$ cd /c/t/b && node tests/run-hook-corpus.js scripts/dg-git-guard.js
                                          -> 18/18 corpus rows pass
```

Note the second command runs through `tests/run-hook-corpus.js`, one of the files that was
CRLF-materialized by the control.

## Decision

**ACCEPTED** by the owner on 2026-07-29. Applied as proposed:

- `.gitattributes` gains `*.js text eol=lf`, with a comment recording why lane N makes it
  necessary and that the shipped exec form is not itself the failure path.
- The header rationale now reads "executable scripts — `.sh` AND `.js`" and carries a note that
  it named only shell scripts until this CR.
- `git add --renormalize .` run; all three tracked `.js` files now report `attr/text eol=lf`.

Guarded two ways in `tests/layer1-config-wiring.sh` §14:

1. Every tracked `*.sh`, `*.js` and `tests/fixtures/*` must carry `eol=lf` **as an attribute**,
   read via `git check-attr` — not via `git ls-files --eol`, which reports `w/lf` with no
   `.gitattributes` present at all and so can never fail (the CR-2 lesson). Subjects are derived
   from the tracked tree with a floor of 15, so a new script class cannot silently fall outside
   the policy the way `.js` just did.
2. The header rationale must name both extensions, so it cannot drift from the tree again.

**Scope note — what was NOT extended.** Only `*.js` was added. `*.py`, `*.ps1` and other
interpreters remain uncovered because no tracked file uses them today; guard §14's derived-subject
floor is what surfaces the next such class, and adding one is another CR. The
`snapshots/** -text` freeze is untouched: those bytes back recorded SHA-256 hashes and normalizing
them would invalidate the Wave 6 reconciliation inputs.
