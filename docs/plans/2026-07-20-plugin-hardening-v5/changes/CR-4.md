# CR-4 — F30's "survives anywhere" row spans two waves, and part of it belongs to Wave 8

**Raised:** 2026-07-30, during the Wave 5 close-out audit, commit `b55ebc0`
**Raised by:** Claude (optimizer), self-reported on discovering the row had no guard at all
**State: PROPOSED** — needs owner ratification. The guard described below is IMPLEMENTED, so the
tree and this record agree; what is NOT settled is whether the owner accepts the reading.
**Affects:** Wave 5 acceptance row 3, verbatim:

> - [ ] F30 stale-reference sweep — no `/deepgrade:doc` or `commands/doc.md` string survives anywhere [G]

## What I found

The row is class **G** — a grep guard — and **no guard existed**. I had marked F30 closed on the
strength of having deleted `commands/doc.md`. Two references survived the deletion:

```
CHANGELOG.md:14:- `/deepgrade:doc` and the documentation skill: external enrichment for specs, ADRs, and READMEs
docs/specs/mcp-research-integration.md:165:**Testing:** Manual — run `/deepgrade:doc adr test-topic` with Ref connected
```

A **third** reference was on genuine product surface, and the guard found it on its first run —
`skills/documentation/SKILL.md:10`, provenance text I wrote during the F30 work itself:
*"Carried here from `commands/doc.md`, which this skill replaced in v5.0.0."* Accurate, useful, and
naming a deleted path in a shipped file. It needed **no exemption**: rewording to "the former `doc`
command" keeps every bit of the provenance and drops the literal string. That matters for the
proposal below — it means the row stays **literal for all product surface**, and only history is
exempted.

Neither remaining reference is stale in the sense the finding cared about — neither would cause a user to
hit a broken command *today*, because both sit in documents describing work that already shipped.
Both are **history**:

- `CHANGELOG.md:14` is under `## 4.31.0 (2026-04-03)`. Version 4.31.0 genuinely did add
  `/deepgrade:doc`. Deleting that line would make the changelog false.
- `docs/specs/mcp-research-integration.md` is the spec for a shipped feature (MCP-005). Its
  `commands/doc.md` half, its `allowed-tools` acceptance criterion, and its
  `/deepgrade:doc adr test-topic` testing step describe something that no longer exists.

## Why this is not simply "narrow the row"

The literal row cannot be satisfied by Wave 5 **at all**, in either direction:

1. Rewriting the changelog entry falsifies a release record.
2. Leaving it means the string survives, so the row fails.
3. The correct third option — a 5.0.0 entry recording the removal, so a reader of the 4.31.0 entry
   is not misled — **is explicitly Wave 8's ticket**: `PHV5-080 — Version + CHANGELOG + migration
   note`. Wave 5 cannot write it without doing Wave 8's work at Wave 5's version number.

So this is a **cross-wave dependency the spec did not capture**, not a scope reduction. The row was
written as if F30 were self-contained within Wave 5; the changelog half of it is sequenced behind
PHV5-080.

## Requested change

Read the row as scoped to **live product surface**, with two structural exemptions, and add a
successor obligation so the exemption cannot become permanent:

1. **Subject set** = every tracked `*.md` outside `docs/plans/**` and outside this plan's own spec.
   A plan document that says "delete `/deepgrade:doc`" must be able to name it. This is scope, not
   narrowing — plan artifacts were never product surface.
2. **`CHANGELOG.md`** — a hit is exempt only when it sits under a `## X.Y.Z (date)` heading. A hit
   in an `Unreleased` section, or in prose outside any release, still fails.
3. **`docs/specs/mcp-research-integration.md`** — exempt only while it carries a
   `SUPERSEDED IN PART … F30` banner. The banner was added in this change; removing it re-arms the
   check rather than silently keeping the pass.
4. **Expiry (the load-bearing clause).** Once `plugin.json` reports `5.x` or later, the guard
   requires `CHANGELOG.md` to record the `/deepgrade:doc` removal. If Wave 8 bumps the version and
   omits the note, the suite goes red. The exemption cannot outlive its justification.

## Alternatives considered

- **Delete the changelog line** — rejected. It is true history; a changelog that omits what a
  release added is a worse artifact than one naming a since-removed command.
- **Write the 5.0.0 CHANGELOG entry now** — rejected. That is PHV5-080, gated on Waves 1–7, and
  the version bump is the release cache key. Doing it early would either bump the version outside
  Wave 8 or write a release note for a version that is not shipping.
- **Register a tolerated failure in `tests/expected-failures.txt`** — rejected, and the file itself
  forbids it: enforced empty since Wave 3, and the comparator added in Wave 3 fails the build on any
  entry. Its header is explicit that recording a defect there "enshrines it as correct behaviour,
  which is the R2 anti-pattern this plan exists to remove."
- **Exempt both files by exact line** — rejected as weaker than the structural form. An exact-line
  exemption keeps passing when the surrounding justification disappears; conditions 2–4 above each
  fail when their premise does.
- **Leave the row unguarded and keep F30 marked closed** — this is the status quo I am correcting,
  and it is how two references survived a finding I had recorded as done.

## Acceptance

Falsifying in both directions, mutation-executed rather than asserted:

| Mutation | Required result |
|---|---|
| Add `/deepgrade:doc` to `README.md` (product surface) | guard FAILS |
| Strip the `SUPERSEDED IN PART … F30` banner | guard FAILS |
| Add `/deepgrade:doc` under an `Unreleased` heading | guard FAILS |
| Set `plugin.json` to `5.0.0` with no recorded removal | guard FAILS |
| The existing `4.31.0` historical line, untouched | guard PASSES (baseline) |

The subject-set derivation also asserts a floor of 10 files, per this plan's recurring
vacuous-pass lesson: a derivation that collapses to nothing would otherwise pass cleanly.

## If the owner rejects this reading

The fallback is to hold **F30 open** until Wave 8, and record row 3 as NOT MET with the reason —
the same form used for G1 WINDOWS_ONLY and F23 under lane I. The guard as written would then be
kept for parts 1–3 and part 4 promoted from an expiry check to F30's actual acceptance.
