# CR-1 — Owner acceptance: lane-N node-less signal is the vendor hook-error notice

Date: 2026-07-21 · Phase 3 (pre-lock) · Raised by: Codex round 8, GAP-5 ("obtain explicit owner acceptance of the
vendor error as the lane-N node-less signal")

## Decision

**State: ACCEPTED** — owner, 2026-07-21; conditional on U6 notice visibility (the failure branch is defined in
§Return path). *(Anchored state line added v11; hardened v12 — the sweep asserts this line; conflicting decision
language in this section, or a bold conflicting state marker anywhere in the file, fails the gate. Rounds 10 and
11 each defeated the prior weaker form.)*

**Accepted by the owner.** On a lane-N host without node, neither the guards nor the SessionStart check can spawn;
the signal for that state is **Claude Code's own visible hook-error notice**, not the friendly
`[DeepGrade] guards inactive` warning required by the round-4 owner decision. This is explicitly a **weaker signal
than the round-4 requirement**, accepted as such — not claimed as continuity.

## Scope of the acceptance

- Applies only to the node-less lane-N state. The friendly warning remains required everywhere it can run: every
  lane B/I degraded state, and every lane-N host with node present.
- Conditional on **U6 proving the notice's exact visible form** in the Wave 0 probe.

## Return path if the condition fails *(added v10 — round 9: "returns to the owner" was not a defined branch)*

If U6 shows the node-absent spawn failure is **not** user-visible, this acceptance is **void**, G0 records the
**BLOCKED** terminal state (approach.md §3.1.1 outcome table), **Wave 0 pauses before its CI-enablement step**
(§9 Wave 0 step 4 — no lane-dependent CI job is created; steps 1–2 stand) *(pause made explicit in v11 — round 10:
Wave 0 proceeded to CI enablement unconditionally)*, and Wave 4 does not start until the owner issues a
new CR choosing one of:

1. **Accept invisible absence** — lane N proceeds; a node-less install has *no* in-product signal (migration note
   carries the entire burden).
2. **Supplementary warning** — add a bash-form warning entry alongside lane N's handler, knowingly re-accepting the
   healthy-host noise trade-off round 7 rejected.
3. **Select lane B** — bash-script-canonical, where the warning is always deliverable on supported hosts.
- The migration note must document the node prerequisite and describe what a node-less user will see.
- Alternatives considered and declined by the owner: a supplementary bash-form warning (reintroduces the
  healthy-host noise round 7 rejected); demoting lane N (gives up native parsing and reopens the jq question).

## References

`approach.md` §3.1.6 (lane-N decision tree), R10; `codex-review.md` Round 8 record; round-4 owner decision
(status.json `owner_decisions_round4`).
