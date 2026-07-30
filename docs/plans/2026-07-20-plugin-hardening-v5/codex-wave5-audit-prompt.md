# Codex audit prompt — Wave 5 test-and-guard work (commits `b55ebc0`, `658612a`)

Scope for this run: **the two most recent commits only.** Not the plan, not the whole
suite, not documentation prose.

---

## Context

You are reviewing a **Claude Code plugin** — a package of Markdown component definitions
plus a few Node scripts and Bash test scripts. There is nothing sensitive in this
repository: no credentials, no network services, no user data, no production system. It
is developer tooling. Reviewing whether its test assertions actually test what they claim
is ordinary QA work.

Repository root: the current working directory. Version 4.31.0, mid-migration to 5.0.0.

The two commits under review:

```
b55ebc0  test: give wave 5 the assertions its acceptance rows required
658612a  test: close the three wave 5 acceptance rows that had no artifact
```

Read them with `git show`. The author's own account of what they do is in
`docs/plans/2026-07-20-plugin-hardening-v5/status.json` under
`phases.build.wave_5_audit_2026_07_30` and `phases.build.wave_5_closeout_2026_07_30`.
**Treat that account as a claim to be checked, not as background.** It was written by the
same author as the code.

## Your job

Find where this work is wrong. The author has a documented history in this plan of
marking things complete that were not, so bias toward disbelief. Every finding must cite
`file:line` and state the concrete failure — inputs or state, and the wrong result.

Answer these five questions. Where you find nothing wrong, say so explicitly rather than
padding.

### 1. Do the new Layer 1 guards enforce what their failure messages claim?

`tests/layer1-config-wiring.sh`, sections **17** and **18** (roughly lines 1146–1385).

For each assertion, the question is not "does it pass" but "**could it pass while the
property it names is false?**" The author found two such guards during this work — one
matched the keyword `merge`, satisfied by an unrelated line elsewhere in the file; one
matched `powershell`, satisfied by the prose explaining the rule it was guarding. Assume
more of that shape survives. Look specifically for:

- assertions satisfied by a substring of an unrelated token (`/deepgrade:documentation`
  contains `deepgrade:doc`)
- assertions whose subject set can be empty, so they pass vacuously
- assertions that check a string appears rather than that a thing is done
- `grep` patterns that behave differently on the CRLF files in this tree

### 2. Is the F30 sweep's exemption structure sound, or does it have a hole?

Section 18. It exempts two files from a rule that the acceptance row states absolutely
("no `/deepgrade:doc` or `commands/doc.md` string survives anywhere"). The reasoning is in
`docs/plans/2026-07-20-plugin-hardening-v5/changes/CR-4.md`.

- Is the `CHANGELOG.md` released-version-heading test correct? The `awk` decides whether a
  hit is under a `## X.Y.Z (date)` heading. Can a hit be smuggled past it?
- The `mcp-research-integration.md` exemption is conditional on a `SUPERSEDED IN PART`
  marker. Is that condition actually load-bearing?
- The expiry clause reads the version from `.claude-plugin/plugin.json` and requires a
  recorded removal once it reaches `5.x`. Does the version parse work? Does the removal
  regex match what Wave 8 would plausibly write, or is it so narrow that a reasonable
  changelog entry fails it — or so broad that anything passes?
- **Is CR-4's argument honest, or is it a rationalisation for narrowing a locked row?**
  The alternatives it rejects are listed; say if a better option was missed.

### 3. Are the two new behavioral tests sound?

`tests/layer4-behavioral-smoke.sh`, tests **B6** and **B7**. These extract fenced `bash`
blocks from Markdown command files and execute them.

- Is the `awk` extraction correct? B6 takes the first `bash` block; B7 selects a block by
  content. What happens if a file is reordered, or a block contains a nested fence?
- Can either test pass while the behaviour it asserts is broken?
- B7 asserts the output does **not** contain "not a directory". Is that a legitimate
  assertion about the mechanism, or is it over-fitted to the current wording such that a
  harmless rewording breaks it?
- Both write to `${TMPDIR:-${TEMP:-/tmp}}` and `rm -rf` it. Any path there that could
  delete something it should not, e.g. if a variable is empty?

### 4. Is the author's "defense in depth" claim about mutation X3 correct?

Recorded under `wave_5_closeout_2026_07_30.x3_a_third_distinct_survival_cause`. The claim
is that neutering the sentinel guard's `exit 0` left the observable outcome identical
because a following `[ ! -d "$FOLDER" ]` check caught the fall-through, so an
outcome-level assertion could not see the first guard fail.

Verify that against `commands/quick-cleanup.md`. Is the causal story right? If the real
reason X3 survived is something else, say what.

### 5. Did the close-out miss any Wave 5 acceptance row?

The rows are in `docs/specs/plugin-hardening-v5.md` under `**Wave 5**` (three bullet
lines). The tickets are `PHV5-050` … `PHV5-053` in the same file.

For **each clause of each row**, name the committed artifact that satisfies it, or state
that none does. The author claims three clauses had no artifact and are now covered. Check
whether that enumeration is complete — treat every row as a conjunction of separate
criteria, since a clause buried mid-sentence still counts.

## Output format

```
## Verdict
{one paragraph: is this work sound, and what is the most serious problem you found}

## Findings
### F1 — {title} — SEVERITY: {HIGH|MEDIUM|LOW}
File: {path:line}
Claim under review: {what the author asserts}
What is actually true: {what you verified, and how}
Failure scenario: {concrete inputs/state -> wrong result}
Fix: {smallest correct change}

## Checked and found correct
{list, briefly — this section matters as much as the findings}

## Questions 1-5, one line each
{Q1: sound / N defects found — etc.}
```

If you cannot verify something without running a command the sandbox denies, say which
command and what you would have concluded. Do not guess and do not simulate a result.
