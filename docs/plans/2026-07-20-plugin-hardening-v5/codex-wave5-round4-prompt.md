# Codex round 4 — did the mechanisms close this time? (`b5ce204`)

Scope: `HEAD` = `b5ce204`, and the commit `b5ce204` itself.

---

## Context

Developer tooling: a Claude Code plugin — Markdown component definitions plus Node, Bash and
Python scripts. No credentials, no network services, no user data, no production system.
Verifying that test assertions test what they claim is ordinary QA work.

You have reviewed this three times (`019fb22d`, `019fb351`, `019fb402`). Across those rounds
you produced 23 findings. **Every claim was verified and confirmed; none was refuted.**

Round 3's finding was that round 2 had fixed *instances*, not *mechanisms* — only F2, F7 and
N8 were mechanism-closed, and nine prior findings still fell to a variant. This round asks
whether round 3's fixes did better.

### What changed in `b5ce204`

| Round-3 finding | What was done |
|---|---|
| N5 — live defect: `commands/codebase-gates.md` named the inert plugin-side hooks path | Path corrected; the F08 sweep now **derives** every component referencing `gate-generator` or `codebase-gates` instead of naming one file |
| N2 — canary printed *after* the `if`, so it only fired when the condition was true | Printed **before** the matched line; every occurrence instrumented; exactly one marker required or the test fails |
| N6/N7 — block selection defeated by a decoy | Unique `# dg-test-marker: plan-status-overview` in the product; **exactly one** must match |
| N8 — F15 wrongly routed to PHV5-044 | New **B8** executes the archive branch with `zip` absent and `powershell.exe` stubbed, asserting an archive file exists |
| N3 — loose harness oracle | Crash detection (`Results:` must appear); controls require **zero** failures, not merely none bearing their tag; a red **final** baseline now fails the run; all mutators refuse a target absent from `FILES` |
| Over-strict F08 imperative | Now per-line and negation-aware; accepts "For every generated hook, also emit a PowerShell variant" (control Z6) |

**Ledger reopened.** `PHV5-050`, `PHV5-052`, `PHV5-053` removed from `tickets_complete`;
`F08` and `F30` removed from `findings_closed`. 18/26 → 15/24.

## Your job

Seven questions. Where you find nothing wrong, say so explicitly rather than padding.

### 1. Mechanism or instance — again.

Round 3 listed nine findings as STILL OPEN under a variant, specifically:
`FOLDER="${@:1:1}"` (F09), `echo '${CLAUDE_PROJECT_DIR}'` (F10), `nice tree .` /
`builtin tree .` (F15), `Write-Output Compress-Archive` (F15), postposed negation in F28
("The `deepgrade:mcp-research` skill must never be invoked"), F08 accepting fenced examples,
`fm_get` on no-frontmatter files with body horizontal rules, `argument-hint: # TODO` and
`argument-hint: ""`.

**Which of those are now closed, and which still pass?** Re-run each. Then construct a *new*
variant for anything you judge closed.

### 2. Is the F08 component sweep actually complete?

It derives subjects by grepping for `gate-generator|codebase-gates`. Can a component
participate in gate generation without matching either token — a skill, a nested reference, a
file that the agent writes? Does the derivation have a floor that could pass vacuously?

### 3. Is B8 sound, or is its stub still a decoy-acceptor?

The stub was rewritten to require `Compress-Archive` as the **first token of the `-Command`
string**. Attack it: `& Compress-Archive`, `powershell -c`, a here-string, `-Command` appearing
twice, semicolon-chained commands, `Compress-Archive` invoked via an alias or variable. Also:
does B8 pass on a *legitimate* rewrite of the fallback that a maintainer might plausibly write?

### 4. Is the canary now correct?

Printed before every matching `if [ ! -d "$FOLDER" ]`, with exactly-one-marker enforced.
Consider: `[[ ! -d "$FOLDER" ]]`, `test ! -d`, the guard reformatted across lines, the guard
inside a function, and a `$FOLDER` check spelled differently. Does the exactly-one rule reject
a legitimate refactor?

### 5. Audit the hardened harness.

Re-read `tests/mutation/wave5-guards.py`. The oracle now checks completion, requires zero
failures for controls, fails a red final baseline, and refuses un-backed-up targets.
- Are any of the 31 `catch` mutants still **invalid** (net no-op, comment-only, or changing a
  line no guard reads)?
- Are all 7 controls genuinely legitimate maintainer edits?
- Does `crashed` misfire — e.g. a suite that legitimately exits non-zero with real failures?
- Any remaining path where a mutation escapes the backup set or the restore is incomplete?

### 6. Is the reopened ledger correct — in BOTH directions?

I removed `F08`, `F30`, `PHV5-050`, `PHV5-052`, `PHV5-053`.
- Was each of those genuinely not met?
- **More important: is anything STILL marked closed that is not met?** Check every remaining
  entry in `tickets_complete` and `findings_closed` against its acceptance row, not against my
  description of it. This is the question that has found something every round.

### 7. The F30 row conflict — adjudicate it.

The row (`docs/specs/plugin-hardening-v5.md:392`) says no `/deepgrade:doc` or
`commands/doc.md` string survives **anywhere**. The guard allowlists this plan's own directory
and spec, because those records quote the strings in order to document the deletion. Both
cannot be true.

I have deliberately not resolved this, because resolving it silently is what produced the
first false closure. **Which is correct**: reword the row via a change record, rewrite the
plan's records so they stop naming the strings, or something I have not considered? Note that
CR-4 was withdrawn after you named an option I had not enumerated, so assume my option set is
again too small.

## Also, a strategic question

Three rounds, 23 findings, and the pattern has been consistent. **Is this converging?** If you
judge that the remaining Wave 5 clauses cannot be closed by static assertions at any reasonable
cost, say so plainly and say what the alternative is — I would rather record rows as NOT MET by
class-G means than keep producing green assertions that mean less than they appear to.

## Output format

```
## Verdict
## Round-3 variants — closed or still open
{per item from Q1}
## New findings
### N1 — {title} — SEVERITY: {HIGH|MEDIUM|LOW}
File: / Claim under review: / What is actually true: / Failure scenario: / Fix:
## Harness audit
## Ledger audit — wrongly closed, or wrongly reopened
## F30 adjudication
## Convergence assessment
## Checked and found correct
## Questions 1-7, one line each
```

If a command is denied by the sandbox, say which and what you would have concluded. Do not
guess and do not simulate a result.
