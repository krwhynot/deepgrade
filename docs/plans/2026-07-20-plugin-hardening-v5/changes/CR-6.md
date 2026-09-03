# CR-6 — replace F30's "survives anywhere" row with semantic absence + an occurrence-addressed provenance ledger

**Raised:** 2026-07-30, after Codex round 4 (`gpt-5.6-sol` @ `xhigh`, session `019fb495`)
**Raised by:** Claude (optimizer), on the reviewer's adjudication of a conflict I had escalated
rather than resolved
**State: RATIFIED** — owner ratification 2026-08-03; implemented the same day. The F30 guard
in `tests/layer1-repo.sh` now enforces both halves: semantic absence (the sweep covers every
tracked `.md` with NO allowlist, and SPLIT-3's resolver independently fails any shipping
reference that cannot resolve) and the occurrence-addressed ledger
(`tests/fixtures/f30-provenance-ledger.tsv`, 39 entries across 10 files at ratification).
One implementation decision within the proposal's frame: occurrence address = file +
sha256 of the exact line, NOT a file hash — a file-level hash would freeze every record
containing one mention, punishing the truthful-rewording practice CR-4 established.
All six acceptance probes executed and caught/passed as specified, including the one the
allowlist could never catch (a stale instruction added inside this plan's own directory)
and both controls. F30 accordingly moves into `findings_closed` and PHV5-053 into
`tickets_complete`.
**Replaces:** Wave 5 acceptance row 3, verbatim:

> - [ ] F30 stale-reference sweep — no `/toque:doc` or `commands/doc.md` string survives anywhere [G]

## The conflict

The row is absolute. The guard allowlists this plan's own directory and spec, because those
records must quote the strings in order to document the deletion. **Both cannot be true**, and
the gap between them is where two false closures already happened:

- Recorded closed on an unratified narrowing (CR-4, withdrawn).
- Recorded closed again while three stale references lived in an unrelated plan, because I had
  replaced two narrow disclosed exemptions with one broad undisclosed one and wrote "enforced
  literally, no exemptions" in the guard, the pass message and the commit.

I escalated rather than resolving it, because resolving it silently is what produced both.

## Why my framing was wrong — for the second time

I presented this as a binary: reword the row, or rewrite the records so they stop naming the
strings. Codex rejected both and named a third construction I had not considered. **This is the
second time a dilemma I posed to this reviewer had an unconsidered option** — CR-4 was the first,
where "reword the history truthfully" retired an entire HIGH finding I had built exemption
machinery to work around.

The lesson is now load-bearing enough to state as a rule: *presenting a decision as a dilemma is
itself a claim, and it has been wrong every time I have made it here.*

## Requested change

Replace the single absolute row with two enforceable requirements.

### 1. Semantic absence

No **registered command, live product surface, template, agent, or skill reference** resolves to
the deleted command. This tests the shipping defect — a user or agent being pointed at something
that no longer exists — rather than the presence of a byte sequence.

Enforced by resolution, not by string search: every `/toque:*` reference in shipping surfaces
must resolve to a `commands/*.md` or `skills/*/SKILL.md` that exists.

### 2. Occurrence-addressed historical provenance

Every intentional historical mention is **enumerated by exact file and content hash** in a ledger.
The guard fails on:

- an occurrence **not** in the ledger (a new stale reference cannot hide in an allowlisted
  directory), **and**
- a ledger entry whose hash no longer matches, or whose file no longer contains the occurrence
  (the ledger cannot go stale and keep passing).

This is the mechanism that makes the difference from the current guard: a directory-wide exemption
is a hiding place, an occurrence ledger is an inventory.

## Alternatives considered

- **Literal byte-erasure everywhere.** Rejected on the reviewer's reasoning: *"all records —
  including the row defining it — must stop spelling the tokens. That is internally awkward and
  tests archival wording rather than the shipping defect."* The row would have to stop quoting the
  strings it exists to prohibit.
- **Keep the directory allowlist, disclosed honestly.** Rejected — disclosure does not fix it. Any
  new stale instruction added under the allowlisted path passes, which is exactly the N1 failure.
- **Narrow the row to "live product surface" only.** Rejected as insufficient: it drops the
  provenance half, so historical mentions become unaudited and can drift into instructions.
- **Leave F30 open indefinitely.** This is the current state and is honest, but it blocks Wave 5
  and PHV5-053 without a path.

## Acceptance if ratified

Falsifying in both directions, with the control being the half that matters:

| Probe | Required |
|---|---|
| Add `/toque:doc` to a shipping surface (README, a template, a skill) | **FAIL** — semantic absence |
| Add a stale instruction under this plan's own directory | **FAIL** — unregistered occurrence |
| Edit a ledgered file so the recorded hash no longer matches | **FAIL** — stale ledger |
| Remove a ledgered occurrence but leave the ledger entry | **FAIL** — stale ledger |
| The existing historical mentions, unchanged | **PASS** — control |
| A new plan folder that references the deleted command in a *historical* record, registered | **PASS** — control |

Plus a floor on the resolver's subject count, per this plan's recurring vacuous-pass lesson.

## If the owner rejects this

F30 remains **NOT MET** and stays out of `findings_closed`, and PHV5-053 stays out of
`tickets_complete`, until either this or an alternative is ratified. That is the current state, so
rejection costs nothing beyond leaving the row unsatisfiable as written.
