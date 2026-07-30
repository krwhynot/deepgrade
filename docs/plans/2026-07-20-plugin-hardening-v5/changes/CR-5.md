# CR-5 — extend the line-ending policy to `*.py`, and fix the §14 derivation that was supposed to make this unnecessary

**Raised:** 2026-07-30, immediately after commit `49119d7`
**Raised by:** Claude (optimizer), self-reported on committing the first tracked `.py` file
**State: PROPOSED** — needs owner ratification. Applied in the same commit as this record,
because the alternative is leaving a guard that is knowingly broken; see *Why applied before
ratification* below.
**Extends:** acceptance-matrix row **A1**, as CR-2 and CR-3 did.

## What happened

`tests/mutation/wave5-guards.py` was committed at `49119d7` to close Codex finding N8 (the
mutation harness was untracked, so every "N caught" claim was unauditable). It is the
repository's **first tracked `.py` file**, and it landed outside the line-ending policy:

```
$ git check-attr text eol -- tests/mutation/wave5-guards.py
tests/mutation/wave5-guards.py: text: unspecified
tests/mutation/wave5-guards.py: eol: unspecified

$ git check-attr text eol -- scripts/dg-git-guard.js
scripts/dg-git-guard.js: text: set
scripts/dg-git-guard.js: eol: lf
```

Layer 1 reported **139 passed / 0 failed** with that file uncovered.

## The part that matters more than the missing line

**CR-3's central claim was false, and it was ratified on that claim.** Its Decision section
says the §14 guard derives subjects from the tracked tree "so a new script class cannot
silently fall outside the policy the way `.js` just did." The comment in
`tests/layer1-config-wiring.sh` repeated it: *"Subjects are DERIVED from the tracked tree, so
a newly added script is covered the moment it is committed."*

The code did this:

```bash
for f in $(git ls-files '*.sh' '*.js' 'tests/fixtures/*' 2>/dev/null); do
```

That derives **files within known extensions**, which is not the same claim as deriving
**script classes**. A new class was exactly what it could not see — so the guard written to
prevent a repeat of the `.js` gap reproduced the `.js` gap, and I demonstrated it by accident
while fixing something else.

This is the recurring bug species this plan has now hit six times: *a check that returns the
same answer regardless of the truth*, paired with *a documented claim that is not true of the
code*. The previous five are listed in the loop-state record.

## Requested change

1. **`.gitattributes` gains `*.py text eol=lf`**, with the rationale sentence extended to name
   `.py` alongside `.sh` and `.js`.
2. **§14's derivation is fixed** to take known script extensions **UNION every tracked file
   carrying a `#!` shebang**, whatever its name. This is the property the comment always
   claimed. It is a defect fix, not a scope change — it would have failed before this CR too.
3. The rationale guard is extended to require every covered class be named, so the sentence
   cannot drift from the policy again (the CR-3 failure, repeated).

## Alternatives considered

- **Do not track the harness; keep it in scratch.** Rejected — that reinstates Codex N8, which
  is the finding this file exists to close. Unauditable mutation evidence is worse than an EOL
  gap.
- **Rewrite the harness in Bash or Node so it falls under an already-covered class.** Rejected:
  rewriting ~200 lines of working, reviewed tooling to avoid a one-line policy addition is a
  bad trade, and it would leave §14's false derivation in place — the more serious of the two
  defects here.
- **Add `*.py` and leave §14 alone.** Rejected. It fixes this instance and leaves the mechanism,
  which is how the `.js` gap became the `.py` gap. The next class — `.ps1`, `.rb`, anything —
  would fall through identically.
- **Cover everything with `* text=auto`.** Rejected: it would fight the deliberate
  `snapshots/** -text` freeze, whose bytes back recorded SHA-256 hashes that are the sole input
  to Wave 6 reconciliation.

## Why applied before ratification

CR-3 named this exact case in advance — *"`*.py`, `*.ps1` and other interpreters remain
uncovered because no tracked file uses them today; guard §14's derived-subject floor is what
surfaces the next such class, and adding one is another CR"* — so the protocol was agreed, and
only the trigger was pending. The change is the one line CR-3 anticipated verbatim.

Leaving it unapplied would mean committing a guard I know to be broken, or reverting the
harness and reopening N8. Both are worse than applying and flagging. **If the owner rejects
this, the fallback is to untrack the harness and record N8 as NOT MET** — and the §14
derivation fix stands either way, since it is a defect fix independent of the policy's scope.

## Acceptance

Falsifying in both directions, and the control is what makes it meaningful:

```
# 1. The gap is real before the fix
git check-attr eol -- tests/mutation/wave5-guards.py   -> 'unspecified'   (recorded above)

# 2. §14 with the corrected derivation FAILS on the uncovered file
bash tests/layer1-config-wiring.sh
  -> [FAIL] A1/CR-3: tests/mutation/wave5-guards.py ... eol attribute is 'unspecified'
     (observed: 138 passed / 1 failed)

# 3. After adding *.py, the same command passes and the file carries the attribute
git check-attr eol -- tests/mutation/wave5-guards.py   -> lf

# 4. CONTROL — a fresh CRLF clone must not materialize it with CRLF
git -c core.autocrlf=true clone -q . <tmp> && file <tmp>/tests/mutation/wave5-guards.py
  -> must NOT report "with CRLF line terminators"

# 5. REGRESSION — introduce a shebang-bearing file with an unknown extension and confirm
#    §14 now surfaces it, which is the claim CR-3 made and could not keep.
```
