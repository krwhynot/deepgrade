# Codex round 3 — do the structural changes hold? (`61cd56b`)

Scope: `HEAD` = `61cd56b`, and commits `49119d7` + `61cd56b`. Not the plan narrative, not
documentation prose.

---

## Context

Developer tooling: a Claude Code plugin — Markdown component definitions plus Node, Bash and
Python scripts. No credentials, no network services, no user data, no production system.
Verifying that test assertions test what they claim is ordinary QA work.

You have reviewed this twice. Round 1 (session `019fb22d`) returned 7 findings; round 2
(session `019fb351`) found only F2 and F7 fully fixed, added 8 more, and confirmed 8 guards
were also **too strict**. Every claim was verified and confirmed; none was refuted.

**This round exists to answer one question: did the fixes address the MECHANISM, or only the
instances you demonstrated?** Round 2 showed round 1 had mostly done the latter.

### What changed since `c7e8e98`

Round 2's central diagnosis — text matchers asserting semantic properties — was accepted, and
three changes of kind were made rather than another tightening pass:

| Change | Where |
|---|---|
| `fm_get` / `fm_has` — bounded YAML frontmatter parser (CRLF, folded scalars), used by every frontmatter assertion | `tests/layer1-config-wiring.sh` ~`:745` |
| Instruction checks anchored on a **sentence-initial imperative** (a prohibition cannot take that form) instead of counting affirmative-minus-negated fragments | F08 |
| **Injected canary** for reachability in B7, replacing exact whole-output matching | `tests/layer4-behavioral-smoke.sh` |

Plus: N1's plan-tree exemption reduced to an explicit two-path allowlist (91 files now
inspected); B6 names the hardening plan explicitly and fails loudly rather than falling back;
8 over-strict guards relaxed, each with a **control mutation** asserting the legitimate form
stays silent.

**Three clauses are now recorded NOT closeable by class-G means** rather than given a green
assertion — F08's agent obedience, F15's archive fallback (your
`powershell -Command "Write-Output Compress-Archive"` probe), F30's skill dispatch. See
`status.json` → `phases.build.codex_wave5_reaudit_2026_07_30.rows_still_not_closeable_by_class_G`.

### N8 is addressed — the harness is now yours to audit

`tests/mutation/wave5-guards.py` and `tests/mutation/README.md` are **tracked**. 32 mutations:
27 that must be caught, 5 controls that must stay silent. You no longer have to treat the
counts as testimony — read the code.

Committing that harness added the repository's first tracked `.py` and immediately proved a
**ratified change record wrong**: CR-3 claimed §14 "derives subjects from the tracked tree so a
new script class cannot silently fall outside the policy", while the code enumerated
`'*.sh' '*.js' 'tests/fixtures/*'`. The `.py` landed with `eol: unspecified`, suite green.
`changes/CR-5.md` records it; §14 now derives known extensions UNION any tracked file whose
**first line** is a shebang.

## Your job

Seven questions. Where you find nothing wrong, say so explicitly rather than padding.

### 1. Mechanism or instance? Re-probe every round-1 and round-2 finding.

For each of F1–F7 and N1–N8: is the underlying mechanism closed, or only the specific mutant
you demonstrated? Construct a *variant* of each — not the same input — and report which
variants still pass.

### 2. Is `fm_get` correct?

It is now load-bearing for F11, F14 and F28. Attack the parser itself: multiple `---` lines,
a `---` inside a block scalar, CRLF vs LF, a key appearing in both frontmatter and body, an
indented key, a quoted value containing `:`, an empty frontmatter, a file with no frontmatter,
a folded `>-` value, and a key that is a prefix of another (`description` vs `description-x`).

### 3. Is the imperative anchor sound, and the canary?

- F08 requires a line matching `^\s*(Always )?Emit a PowerShell variant`. Can that be satisfied
  by something that is not an instruction — a heading, a quoted example, a fenced block, a
  changelog line? Can a legitimate rewrite of the real instruction fail it?
- B7 injects `echo __B7_REACHED_DIR_CHECK__` before the directory guard via `awk`. Is the
  injection anchor robust? What if the guard is reformatted, or the anchor line appears twice?
  Can the canary be reached without the sentinel being inert, or vice versa?

### 4. Audit the mutation harness as code.

It is tracked now. Specifically:
- Are any of the 27 "catch" mutants **invalid** — net no-ops, comment-only edits, or changes to
  a line no guard reads? Four such were found during this plan; assume more.
- Are the 5 controls genuinely *legitimate* edits, or are some actually defects that ought to
  fail?
- `patch()` translates `\n` to the file's own EOL. Any case where that is wrong?
- Do the preconditions and the `O_EXCL` lock actually prevent the failure they claim?
- Does any mutant depend on another having run first?

### 5. Is the §14 shebang derivation right, and is CR-5 sound?

`awk 'FNR==1 && /^#!/ { print FILENAME } { nextfile }'` over `git ls-files -z | xargs -0`.
Consider: a file whose first line is a shebang inside a quoted string; `xargs` batching
splitting the file list; `nextfile` portability; a tracked binary; a path with spaces or
non-ASCII. And judge CR-5 itself — is extending the policy to `*.py` the right call, or should
the harness have been untracked instead?

### 6. Are the three "NOT closeable by class-G means" records honest — and complete?

Is that the right disposition for those three, or is one of them actually testable by a stub
execution I dismissed too readily? Conversely: are there OTHER clauses currently carrying a
green assertion that belong in that category?

### 7. Final reconciliation of the Wave 5 rows.

Rows: `docs/specs/plugin-hardening-v5.md` under `**Wave 5**`. Tickets `PHV5-050`–`PHV5-053`.
Per clause: the committed artifact that satisfies it, or none. **State plainly whether F30 and
F13 are now met**, since both were recorded closed while unmet in earlier commits.

## Output format

```
## Verdict
{one paragraph: did the structural changes hold, and what is the most serious remaining problem}

## Mechanism vs instance
{per prior finding: MECHANISM CLOSED | INSTANCE ONLY | STILL OPEN, with the variant you tried}

## New findings
### N1 — {title} — SEVERITY: {HIGH|MEDIUM|LOW}
File: {path:line}
Claim under review:
What is actually true:
Failure scenario:
Fix:

## Mutation harness audit
{invalid mutants, mis-classified controls, ordering dependencies — or "none found"}

## Over-strict guards
{legitimate edits that wrongly fail — or "none found"}

## Checked and found correct

## Questions 1-7, one line each
```

If a command is denied by the sandbox, say which and what you would have concluded. Do not
guess and do not simulate a result.
