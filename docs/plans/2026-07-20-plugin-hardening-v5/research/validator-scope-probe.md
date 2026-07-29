# Validator scope probe — what `claude plugin validate` actually checks

Run: 2026-07-29, Wave 2 / PHV5-020, Claude Code on Windows 11, plugin at `4f23e5a`.
Purpose: settle **U1** (does agent frontmatter accept a `skills:` key?) before choosing the F27 fix.

## Result

**U1 is unanswerable by the validator, because the validator never reads agent frontmatter.**

## Probe 1 — baseline

```
$ claude plugin validate . --strict
Validating marketplace manifest: C:\Users\NewAdmin\Projects\plugin\deepgrade-plugin\.claude-plugin\marketplace.json
✔ Validation passed

$ claude plugin validate .claude-plugin/plugin.json --strict
Validating plugin manifest: C:\Users\NewAdmin\Projects\plugin\deepgrade-plugin\.claude-plugin\plugin.json
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

## Decision (F27)

Ship the documented fallback: append `Skill` to `tools:` on the seven agents that reference a
knowledge skill. The `skills:` preload key is *not* ruled out — it may well work — but it cannot
be verified here, and an unrecognized frontmatter key would silently no-op. That silent no-op is
exactly the F27 defect, so adopting an unverifiable mechanism to fix it would risk reshipping it.
`Skill` is spec-confirmed and works regardless.

The Layer-1 guard accepts **either** mechanism, so if `skills:` is confirmed later, switching is a
one-line change per agent with the test already in place.

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
