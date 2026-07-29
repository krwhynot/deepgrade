# CR-2: `.gitattributes` scope extended beyond `*.sh` to shell-read data files

Date: 2026-07-29
Author: Claude (Build phase, Wave 0) — raised for owner ratification
Supersedes: acceptance-matrix row **A1**'s stated content (`*.sh text eol=lf`), and the same
text in `approach.md` §1 ("`.gitattributes` (`*.sh text eol=lf`)") and §9 Wave 0 step (2)

**State: ACCEPTED**

## Decision

The owner **ratified** this CR on 2026-07-29, accepting both corrections to acceptance-matrix
row **A1**:

1. **Scope extension** — `.gitattributes` covers `*.sh` **and** `tests/fixtures/**`.
2. **Falsifying acceptance form** — A1's verification is a **fresh-clone working-tree check**,
   not `git ls-files --eol`. *(Folded in at ratification: the matrix row still carried the
   original wording. Audit v2 finding #1 proved `git ls-files --eol` reports `w/lf` for all 14
   scripts with **no `.gitattributes` present at all** — it is green before and after the fix,
   so it can never fail. The spec was corrected at the time; this CR now carries the same
   correction to the authoritative matrix row.)*

The alternative — recording the two fixture failures in `expected-failures.txt` — was
considered and **rejected** at authoring time and not revisited: it would enshrine a live
defect as accepted behavior, the exact R2 anti-pattern this plan exists to remove.

## What Changed

`.gitattributes` was specified as one rule:

```
*.sh text eol=lf
```

It now carries three concerns:

```
*.sh text eol=lf
tests/fixtures/** text eol=lf          # <- ADDED by this CR
docs/plans/2026-07-20-plugin-hardening-v5/snapshots/** -text
```

(The `snapshots/** -text` rule is not part of this CR's scope question — it is required by
PHV5-001's own acceptance, since normalization would invalidate every recorded SHA-256.)

## Why It Changed

**Discovered by A1's own falsifying test.** The audit (v2 finding #1) required A1's acceptance
to become a fresh-clone check, because `git ls-files --eol` was green with no `.gitattributes`
at all. Running that corrected test surfaced a defect the original scope did not cover.

Evidence, from a genuine fresh clone on this `core.autocrlf=true` host:

| | Local working tree | Fresh clone |
|---|---|---|
| `tests/fixtures/plan-orphan-code/changed-files.txt` | ASCII text (LF) | **ASCII text, with CRLF line terminators** |
| Layer 3 result | 9 passed / 0 failed | **7 passed / 2 failed** |

Byte-level proof from the clone: `... c h e c k o u t . c s \r \n`.

The mechanism: `tests/layer3-fixture-lint.sh` reads these fixtures as tab-separated data
(`cut -f2`, `IFS=$'\t' read`) and compares strings with `grep -qxF`. A trailing `\r` makes
every comparison fail, so LINT-11 reported 5 orphan files instead of 2 and LINT-12 reported
3 orphan tickets instead of 0.

**This is the same defect class A1 exists to close** — `core.autocrlf=true` silently corrupting
files that shell scripts parse — differing only in file extension. The original scope assumed
the risk lived in *executable* scripts (CRLF shebang → bad interpreter). It also lives in the
*data* those scripts read, where it is quieter: no error, just wrong answers.

**Why this was invisible before today:** the suite had never been run from a clean checkout.
Locally the fixtures are LF because that is how they were authored; git only applies `autocrlf`
conversion at checkout. This is precisely the class of defect approach.md §10.3 assigns to
verification class **C** ("fresh checkout catches untracked-state dependencies") — the control
worked, on its first real use.

## Impact on Other Phases

- **Wave 0 (A1):** scope extended as above. No other A1 acceptance text changes; the fresh-clone
  test now passes for both scripts and fixtures.
- **Wave 0 CI matrix (PHV5-005):** *raises the stakes for the expected-red comparator.* Had CI
  been enabled before this fix, `ubuntu-latest` would have been green while `windows-latest`
  reported two failures absent from `expected-failures.txt` — correctly failing the job, but
  for a reason easily misread as a Windows-specific test defect rather than a repo defect.
  Wave 0's mandated internal ordering (conformance fixes **before** CI enable) is what kept
  this cheap.
- **`tests/expected-failures.txt`:** unchanged — still exactly the four F18/F19 entries. The two
  fixture failures are now fixed, not tolerated. Recording them as "expected" would have been
  the wrong response: they were a real defect, not a known-and-accepted red.
- **Waves 1–8:** none. No locked decision, lane, gate, or sequencing constraint is affected.
- **F23/F24/hook architecture:** untouched.

## Verification

Fresh clone at `c6d3047` + this fix, `core.autocrlf=true`:

- 13/13 shell scripts check out LF; shebang bytes end `\n`, not `\r\n`
- 6/6 fixture `.txt` files check out LF
- Layer 3: 9 passed / 0 failed (was 7/2)
- Full suite: 156 passed / 4 failed — identical to the local baseline, and the failure set
  matches `expected-failures.txt` exactly under the comparator contract

## Owner Decision Requested

Ratify the extension of A1's scope from `*.sh` to `*.sh` + `tests/fixtures/**`.

The alternative considered and rejected: leave A1 as literally specified and record the two
fixture failures in `expected-failures.txt`. Rejected because it would enshrine a live defect
as an accepted red — the exact anti-pattern R2 documents in the existing suite (which asserts
two defects as correct behavior), and the thing this plan exists to stop doing.
