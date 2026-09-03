# Validator scope probe — what `claude plugin validate` actually checks

Run: 2026-07-29, Wave 2 / PHV5-020, Claude Code on Windows 11, plugin at `4f23e5a`.
Purpose: settle **U1** (does agent frontmatter accept a `skills:` key?) before choosing the F27 fix.

## Result

**U1 is unanswerable by the validator, because the validator never reads agent frontmatter.**

## Probe 1 — baseline

```
$ claude plugin validate . --strict
Validating marketplace manifest: C:\Users\NewAdmin\Projects\plugin\toque-plugin\.claude-plugin\marketplace.json
✔ Validation passed

$ claude plugin validate .claude-plugin/plugin.json --strict
Validating plugin manifest: C:\Users\NewAdmin\Projects\plugin\toque-plugin\.claude-plugin\plugin.json
✔ Validation passed
```

Note which file each form validates. The directory form resolves to `marketplace.json`, not the plugin.

## Probe 2 — falsifying control

A green result proves nothing unless the check can go red. `agents/risk-assessor.md` line 2 —
the `name:` field, without which the agent cannot be addressed at all — was deleted:

```
$ sed -i '2d' agents/risk-assessor.md
$ head -6 agents/risk-assessor.md
---
description: Use this agent to assess module-level risk across a codebase by measuring ...
model: sonnet
color: red
tools: Read, Grep, Glob, Bash
---
```

Both forms still passed:

```
$ claude plugin validate .claude-plugin/plugin.json --strict
✔ Validation passed
$ claude plugin validate . --strict
✔ Validation passed
```

File restored; `git status` clean.

## Probe 3 — documented scope

```
$ claude plugin validate --help
Usage: claude plugin validate [options] <path>
Validate a plugin or marketplace manifest
Options:
  --strict    Treat warnings as errors (exit 1). Use in CI to fail on
              unrecognized fields, missing metadata, and other issues that the
              runtime tolerates.
```

"Validate a plugin **or marketplace manifest**" — manifests, not components. `--strict`'s
"unrecognized fields" applies to the manifest schema, which is why it never sees a `skills:`
key in an agent file either way.

## Probe 4 — can any local mechanism verify a frontmatter key? No.

Two further probes were run and both turned out **non-falsifying**. Recorded because a
non-falsifying probe is worse than no probe: it manufactures false confidence.

**4a. `--agents` inline definition.** If the CLI validated tool names, an unknown one would
error. It does not:

| `tools` value | output | exit |
|---|---|---|
| `"Read"` | `ok` | 0 |
| `"Skill"` | `ok` | 0 |
| `"Zzzdefinitelynotatool"` | `ok` | 0 |

A definitely-invalid name behaves exactly like a valid one, so this distinguishes nothing.

**4b. `claude --plugin-dir . plugin details toque`.** This *does* read the working tree
(`Source: toque@inline`) and reports `Agents (22)`, which looked like a loader check. It
is not — the count tracks files, not parse success:

| mutation to `agents/risk-assessor.md` | reported count |
|---|---|
| baseline | `Agents (22)` |
| `name:` line deleted | `Agents (22)` |
| invalid YAML (`tools: [unclosed, "broken`) | `Agents (22)` |
| frontmatter block never closed | `Agents (22)` |
| **file removed** | `Agents (21)` |

Useful as a file-presence check and nothing more. It cannot confirm that any frontmatter key is
honored, and — importantly — its tolerance of corrupt frontmatter is *not* evidence that the
runtime tolerates it, since the inventory is derived from filenames.

## Decision (F27) — revised 2026-07-29 after audit

Both clauses of the finding's fix ship, and **both** access mechanisms:

- `Skill` in `tools:`, and `skills: ["toque:self-audit-knowledge"]` in frontmatter
- the seven agent bodies now name the skill as `toque:self-audit-knowledge`

**Neither mechanism is verifiable on this machine.** The first revision of this document claimed
`Skill` was "spec-confirmed" and rejected `skills:` as unverifiable. That was an asymmetric
standard: validator silence is evidence about the validator, not about either mechanism, and the
plan's own reference data states the field exists —

> "plugin agent frontmatter supports a `skills` field to preload skills into subagents
> (plugins-reference, Agents section)"

So the honest position is that both are spec-attested and neither is locally testable. Shipping
both means only one has to be honored. The acceptance matrix permits either, so this satisfies it
twice over.

**Known cost of belt-and-braces:** if `skills:` *is* honored, it preloads the skill (~1.5k tokens
per the `plugin details` per-component figures) on every invocation of those seven agents, where
the `Skill` tool would have loaded it on demand. Accepted — a skill that always loads beats a
skill that may never load — but worth revisiting if agent invocation cost becomes a concern.

**The clause that was missed.** Commit `103574e` marked F27 closed having done only the first
clause. The finding's fix text reads "add `Skill` to their tools allowlists **and** reference the
namespaced name `toque:self-audit-knowledge`". All seven bodies still said
`self-audit-knowledge`, unqualified — F21's own defect (bare names do not resolve) in a different
field, shipped in the same commit that fixed F21. The Layer-1 assertion passed throughout because
it checked whether the agent *could* load a skill, never whether the name it was told to load was
addressable: a capability check standing in for a resolution check. The guard now asserts both,
plus that every referenced and preloaded skill exists on disk.

**Rule this yields:** when a finding's fix text contains a conjunction, each clause is a separate
acceptance criterion. Closing on one is closing on none.

## CORRECTION (2026-07-29, PHV5-043) — the scope is wider than this document said

The heading above and the original Probe 3 conclusion said the validator reads "manifests, not
components." **That is too strong and is corrected here rather than quietly amended.** Creating
`hooks/hooks.json` in 4b made a third surface observable, and the validator checks it:

```
$ claude plugin validate .claude-plugin/plugin.json --strict
Validating plugin manifest: ...\.claude-plugin\plugin.json
Validating hooks: ...\hooks\hooks.json
✘ Found 1 error:
  ❯ hooks: Invalid input: expected record, received undefined
```

Two falsifying controls confirm it validates structurally, not merely parses:

| Mutation to `hooks/hooks.json` | Result |
|---|---|
| rename `PreCompact` to `NotARealEvent` | `❯ hooks.NotARealEvent: Invalid key in record` |
| delete `type` from a handler | `❯ hooks.Stop.0.hooks.0.type: Invalid input` |
| (unmutated) | `✔ Validation passed` |

It caught a real error during 4b: the event map must be wrapped in a top-level `hooks` key, which
this plan had nowhere recorded. So the validator earned its place for this file class.

**Why the original conclusion was reached and why it was still wrong.** The probes were run when
the repo had no `hooks/` folder at all — every hook was inline in `plugin.json`. Absence of a
surface was read as absence of coverage for it. The correct statement is narrower:

> `claude plugin validate --strict` validates `plugin.json`, `marketplace.json`, **and
> `hooks/hooks.json`**. It does **not** read `agents/*.md`, `commands/*.md`, or `skills/*/SKILL.md`
> frontmatter.

Probe 2's control still stands unchanged — an agent file with its `name:` line deleted validates
clean — so every conclusion below about the *agent-frontmatter* defect class is unaffected. What
changes is that "components" was the wrong word for the boundary; the boundary is "declared
JSON config" versus "markdown frontmatter".

## Consequence beyond U1

The plan already recorded, for F21 alone, that "`claude plugin validate` passes despite
unresolvable bare names." Probe 2 widens that considerably: **the whole agent- and
command-frontmatter defect class is invisible to the validator** — F01 (duplicate names),
F02/F07 (missing tools), F03 (missing `Agent`), F17 (name/filename drift), F21 (bare MCP
names), F27 (unreachable skills). None of them can be caught by `validate --strict` at any
strictness level, because the files are never opened.

Two consequences for the plan:

1. **U7's behavior list.** `validate --strict` is one of the EIGHT relied-upon behaviors used to
   bisect the compatibility floor. It is relied upon for *manifest schema validation only*. The
   floor probe should not treat a passing `validate` as evidence that component wiring loads.
2. **`tests/layer1-config-wiring.sh` is the sole guard for this class**, on any Claude Code
   version. It is not a supplement to CI validation — there is nothing to supplement.
