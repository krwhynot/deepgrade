# CR-3 — extend the line-ending policy to lane N's `.js` hook scripts

**Raised:** 2026-07-29, during Wave 4a (PHV5-040/041), commit `cf46aab`
**Raised by:** Claude (optimizer), self-reported on introducing the first `.js` hook
**State: PROPOSED — awaiting owner ratification**
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

## Severity — deliberately not overstated

**Lower than CR-2's.** Lane N wires the **node exec form** (`node scripts/dg-git-guard.js`), so
the shebang is decorative and node itself parses CRLF without complaint. There is no known
runtime failure on the shipped invocation path. The exposure is:

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

## Decision

_Pending._ If declined, the exposure above is accepted as-is and this record stands as the
disclosure; `scripts/*.js` stays `text: unspecified` and Wave 6's determinism check must not
assume otherwise.
