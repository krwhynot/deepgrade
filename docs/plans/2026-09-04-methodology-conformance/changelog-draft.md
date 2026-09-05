# CHANGELOG draft for the next release

This repository writes the CHANGELOG entry at release time, as its own commit (`.github/release.sh` refuses to release without a `## {version}` heading, and the mutation harness treats a `## Unreleased` heading as a non-pristine tree). This file holds the draft until then. The version should be a minor bump: D1 and D4 change command and stage behavior.

Six shipped instructions contradicted each other. The methodology conformance audit (`docs/plans/2026-09-04-methodology-conformance/findings.md`) recorded them as owner decisions D1–D6; the decisions and their rationale are in `decisions.md` beside it. Each item names its decision.

## Changed

- **One design gate (D1).** `/toque:quick-plan` claimed "the same gate as Stage 2" while spawning the auditor on its own terms, with no canary and no evidence validation; `/toque:quick-audit` had no gate at all. Stage 2's Part C is now a delimited `<design_gate>` block with three bindings (`{doc}`, `{gate_dir}`, `{generator}`), and both shortcuts execute that block by reference. A standalone document gets a gate folder beside it (`docs/specs/{name}/` for a quick-plan spec) holding `audit.md`, `evidence/` and `gate.json`; the `.canary/` scratch is deleted once used. The auditor no longer has a conversation-only mode. `quick-audit` has no generator, so it reports `NOT PASS` with the unmet criteria and stops. A document written outside the spec template can be audited but cannot PASS: the canary has nothing to attach to, and the gate says so instead of skipping the check. Evidence records are re-anchored to the committed document before validation, so committed evidence never cites the mutated copy. Guarded by PH5-042 in `tests/layer1-repo.sh`.

- **Authorization and release are two events (D4).** Stage 5 marked Deploy `complete` and printed `Released` the moment a human authorized. It now records `authorized_by`/`authorized_at` and leaves the stage `authorized`; a later human confirmation writes `released_by`/`released_at`, marks the stage `complete`, moves `current_phase` to `maintain`, and starts Maintain. `/toque:plan {name}` on resume asks whether an authorized release happened; `/toque:plan-status` reports plan-to-authorization always and plan-to-release only when known, and labels a pre-existing `complete` without `released_at` as recorded at authorization. Existing status files need no migration: the new fields are optional. Guarded by REL-1.

- **The immutable set is enumerated (D5).** "Accepted plan documents are immutable" contradicted every stage that writes `plan.md`, `status.json` and `manifest.md`. Stage 3 now names the set: `changes/CR-*.md` and `snapshots/**` are never edited once written (what CI refuses in this repository); accepted documents are superseded through a Change Record and one SUPERSEDED banner line; everything else is living state updated in the way its stage describes.

- **A separate agent writes the tests (D2).** The TDD entry in the testing-methodology guide let the implementation agent write its own tests first, against LINT-18 and both stage files. It now assigns test generation to a separate agent or a human, keeping the red-green ordering.

- **Baselines stay read-only (D3).** The BRD template's deep scan said to update confidence in the audit baseline, two lines above the rule that baselines are never written back. Verified confidence is now recorded in the BRD's own coverage table.

- **A knowledge-base match is a lead, not a fix (D6).** The troubleshoot skill offered "Apply the same fix?" on a HIGH match before root-cause investigation, against its own Iron Law. A match now names the earlier cause as the first hypothesis for Phase 1; the earlier fix is not re-applied until Phase 1 confirms the cause, and only a confirmed match increments the recurrence count. Guarded by KB-1.

## Fixed

- The suite's B4 cross-reference check could not fail when a shortcut command stopped referencing its agent; it now does.
