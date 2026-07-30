# Mutation harness

Every "N mutations caught" claim in this repository's plan records was, until now,
**unauditable testimony**: the harnesses lived in scratch directories, nothing was
tracked, and `git ls-files | grep -i mutat` returned nothing. Independent review
(Codex `gpt-5.6-sol` @ `xhigh`, finding N8) declined to credit the numbers, correctly —
the repository could not establish which bytes were changed, nor whether the mutants
were valid.

This directory is that evidence.

## Why mutation testing is load-bearing here

A guard that has never been made to fail is worth no more than the manual grep it
replaced. Every substantive defect found in Wave 5 was found by mutation or by external
review — none by a passing suite.

## The three failure modes, all observed in this repo

Running mutants is easy; running *valid* mutants is not. Four invalid mutants occurred
during Wave 5, each by a different mechanism, and each initially looked like a surviving
defect:

| Mechanism | Example |
|---|---|
| Anchor matched prose, not code | `Compress-Archive` replaced in the **comment** one line above the invocation, leaving the file correct |
| Replacement cancelled itself | `argument-hint:` → `argument-hint:XX` → `argument-hint:`, a net no-op |
| Statement placed where semantics ignore it | `false` at the **top** of a block with no `set -e`, so it only sets `$?` |
| Non-load-bearing target | a "fourth command" probe that changed a line the guard never reads |

**An escaped mutation is not evidence of a weak guard until the mutant is proven valid.**
The tempting move — weaken the guard until the mutant is "caught" — converts a working
guard into a broken one. Every escape in this harness must be diagnosed before any guard
is touched.

## Contract every harness here follows

1. **Exclusive lock** (`O_EXCL`). Two concurrent instances raced once: instance B read a
   "baseline" while instance A had a mutation applied, and reported a defect that was not
   in the tree.
2. **Per-file preconditions** before anything is written. Instance B once snapshotted an
   *already-mutated* file as its pristine backup — so `restore()`, the function whose only
   job is undoing damage, would have written the defect back permanently. Backup-and-restore
   launders corruption into the baseline unless taking the backup validates the source.
3. **Refuse a red baseline.** A mutation run against an already-failing suite proves
   nothing.
4. **Restore in a `finally`**, and never run in a foreground tool call that can hit a
   timeout mid-mutation. Two mutations were stranded in the working tree that way.
5. **Declare `NO-OP <-- anchor drifted`** when a replacement changes nothing. Without this,
   an invalid mutant is indistinguishable from a caught one.
6. **Controls.** At least one mutation per suite must be a *legitimate* edit that the guard
   must NOT flag. Sensitivity without specificity is satisfied by a guard that fails on
   anything — and an over-strict guard gets weakened by whoever hits it, so the weakened
   version is what survives.

## Running

```bash
python tests/mutation/wave5-guards.py      # §17/§18 + B6/B7
```

Exit 0 means every mutation was caught and every control stayed silent. Exit non-zero
prints which escaped. The run mutates tracked files in place and restores them; it
refuses to start if the tree is not pristine.
