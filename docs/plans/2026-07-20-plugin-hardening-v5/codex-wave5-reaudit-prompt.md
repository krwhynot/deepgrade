# Codex RE-AUDIT prompt — Wave 5 guards after remediation (`c7e8e98`)

Scope: commit `c7e8e98` and the state of `HEAD`. Not the plan, not documentation prose.

---

## Context

Developer tooling: a Claude Code plugin, Markdown component definitions plus Node and
Bash scripts. No credentials, no network services, no user data, no production system.
Verifying that test assertions test what they claim is ordinary QA work.

**You reviewed the previous commits and returned "this work is not sound" with 7 findings
(3 HIGH).** Session `019fb22d`. Every claim the author could execute was verified and
confirmed; nothing was refuted. This commit is the remediation. Read it with `git show
c7e8e98`.

### What was done with each of your findings

| Your finding | Resolution |
|---|---|
| F1 — unratified narrowing recorded as F30 closure | **Row satisfied literally instead.** Both historical documents reworded ("The documentation command and skill"), CR-4 **withdrawn unratified**. F30/PHV5-053 remain in the completed lists — now on the row as written. |
| F2 — bypass in every exemption + expiry | **All exemption machinery deleted.** Subject loop is now NUL-delimited. |
| F3 — 8 demonstrated false passes | All 8 fixed. |
| F4 — enumeration incomplete | Assertions added for the 4 unasserted conjuncts. |
| F5 — B6 ignores rc, synthetic fixture | rc gated first; copies the live plan's `status.json`. |
| F6 — B7 wording-dependent, X3 account wrong | **Your correction accepted.** B7 now exact-matches the complete output. The X3 "identical outcome" claim was retracted from the record and from the author's long-term memory. |
| F7 — predictable temp paths | `mktemp -d`. |

**Judge whether each resolution is legitimate**, particularly F1: is satisfying the row by
rewording history sound, or does it falsify a release record in a way I should have flagged?
Say so if the reworded `CHANGELOG.md:14` and `docs/specs/mcp-research-integration.md` are
now misleading.

## Your job

Six questions. Where you find nothing wrong, say so explicitly rather than padding.

### 1. Did any of your 7 findings survive the fix, in whole or in part?

Re-run your own probes. A fix that addresses the demonstrated instance while leaving the
mechanism intact has not fixed the finding.

### 2. Do the rebuilt guards have NEW false-pass paths?

`tests/layer1-config-wiring.sh` §17–§18. Several guards changed shape substantially —
command-position matching for `tree` and `powershell`, affirmative-vs-negated counting for
the PowerShell instruction, exact-set comparison for `disable-model-invocation`,
namespaced-token matching for skill references, description length and trigger phrasing.
Each is a new opportunity to be wrong. Ask of each: **could it pass while the property it
names is false?**

### 3. NEW — are any guards now TOO STRICT?

This matters as much as looseness and I have direct evidence of it: my own new
description-trigger regex rejected a skill whose description carries
`Triggers on - create adr, create brd, …`, which is *richer* trigger phrasing than the
"use when" form the regex expected. I caught that only because a real subject tripped it.

A guard that fires on a legitimate change is worse than useless — whoever hits it weakens
it, and the weakened version is what survives. For each changed assertion, construct a
**legitimate** edit a maintainer would plausibly make and check whether the guard wrongly
fails. Specifically:

- Can a valid skill description fail the length floor or the trigger-phrasing regex?
- Can a legitimate `tree`-free prose mention, or a variable named `subtree`, trip F15?
- Does the affirmative/negated counting for `PowerShell variant` misfire on a sentence
  like "emit a PowerShell variant; never omit it"?
- Does F13's loop pattern reject a valid refactor (e.g. `for dir in "$PLANS_DIR"/*/`)?
- Does F28's namespaced-token matcher reject a valid reference form?

### 4. Is the mutation harness trustworthy?

The author's evidence is "19 mutations caught, 2 controls quiet." **Three mutants this
session were INVALID**, each by a different mechanism: a text anchor that matched a comment
rather than the invocation; a replacement that undid itself (net no-op); and a `false`
placed where, with no `set -e`, it only sets `$?` and execution continues.

The harness is at `%TEMP%`-adjacent scratch, not committed — this is recorded debt. Judge
the claim from the repository alone: for the guards in §17–§18 and B6/B7, is there any
whose stated mutation could not actually exercise it? Treat "19 caught" as unverified
testimony.

### 5. Are B6 and B7 correct now?

`tests/layer4-behavioral-smoke.sh`.

- B6 copies the **first** plan folder from `docs/plans/*/` and derives the expected phase
  from it. Is that derivation safe? What if the copied `status.json` has no
  `current_phase`, or the first folder differs from the plan under active work?
- B7 exact-matches the whole output against one literal string. Is that assertion correct,
  or does it now fail on a legitimate change to the usage message — and if so, is that
  acceptable coupling or a new problem?
- Both use `mktemp -d`. Any remaining path where cleanup could remove something it should
  not?

### 6. Is anything in the Wave 5 acceptance rows still unsatisfied?

Rows are in `docs/specs/plugin-hardening-v5.md` under `**Wave 5**`; tickets `PHV5-050`–
`PHV5-053`. Your F4 table found four conjuncts with no falsifying assertion. Redo that
enumeration against `HEAD` and state, per clause, the committed artifact that satisfies it
or that none does.

## Output format

```
## Verdict
{one paragraph: is the remediation sound, and what is the most serious remaining problem}

## Survivors from the previous round
{per finding F1-F7: FIXED | PARTIALLY FIXED | NOT FIXED, one line of evidence each}

## New findings
### N1 — {title} — SEVERITY: {HIGH|MEDIUM|LOW}
File: {path:line}
Claim under review: {what the author asserts}
What is actually true: {what you verified, and how}
Failure scenario: {concrete inputs/state -> wrong result}
Fix: {smallest correct change}

## Over-strict guards
{per finding, or "none found" — with the legitimate edit that wrongly fails}

## Checked and found correct
{list, briefly}

## Questions 1-6, one line each
```

If you cannot verify something without a command the sandbox denies, say which command and
what you would have concluded. Do not guess and do not simulate a result.
