# Make /toque:plan the centerpiece the rest of the toolkit agrees with

- Author: Kyle
- Source: conversation, 2026-09-03 (findings in research/intake/session-findings.md)
- Status: Accepted
- Date: 2026-09-03
- Accepted by: Kyle, 2026-09-03

## Problem

The toolkit contradicts itself about how a plan gets judged.

The centerpiece deliberately stopped grading plans with a number. Version 8.0.0
replaced scoring with four checkable booleans, and a guard exists to keep scores
from creeping back in. But two neighbouring commands still grade plans out of 40
with colour bands, and both cite a scoring rubric that was deleted in that same
release. Run them on one plan and you get two verdicts in two different
currencies, with nothing saying which is authoritative.

Separately, the lightweight planning command writes its output outside the plan
workspace and refuses to create one. Anyone who starts small and then discovers
the work matters has to start over rather than promote what they have.

The cost is that the product reads as several tools that grew next to each other
rather than one tool with a clear centre.

## Proposed outcome

A reader of any command in the plugin can tell how it relates to `/toque:plan`,
and no two commands answer the same question in incompatible terms.

Observable when all of the following hold:

1. **One verdict currency.** Every tool that judges a plan either uses the
   gate's boolean vocabulary, or states in its own description that its output
   is advisory and gates nothing. No tool leaves this ambiguous.
2. **No stale citations.** No file claims a scoring rubric, threshold, or band
   that the auditor no longer has. Verifiable by grep.
3. **The guard covers what it claims.** Whatever scoring rule is chosen is
   enforced by an automated check over *every* file that can violate it, not
   only the three the current guard names.
4. **A small plan can grow up.** Output from the lightweight planning command
   can be promoted into a full plan workspace without redoing the work.
5. **Every command states its relationship to the centerpiece** in one line, in
   `/toque:help` and its own front matter.
6. The full suite stays green, and the release preflight stays clean.

## Affected users and systems

**Users.** Anyone running the planning plugin. Existing plan folders under
`docs/plans/` are read but not rewritten. No user data migrates.

**Systems, all inside `plugins/toque/`:**

- `commands/quick-audit.md`, `commands/quick-plan.md`, `commands/help.md`
- `skills/codex-challenge/SKILL.md`
- `agents/plan-auditor.md` (reference point; expected to change little)
- `tests/layer1-repo.sh` — the PH5-051 guard and its file list
- `documentation/` and `plugins/toque/GUIDE.md` where either describes scoring

**Decision owner.** Kyle, sole maintainer. Named at the acceptance gate below.

## Constraints

- **Auth:** none. No change touches credentials, permissions, or tokens.
- **Data scope:** documentation and test files only. No user data, no network
  calls, no new persisted state.
- **External dependencies:** none added. The Codex CLI dependency of
  `/toque:codex-challenge` is in scope for *labelling*, not for removal.
- **Backwards compatibility:** existing plan folders must keep resuming. Nothing
  here may change `status.json` schema 2 or the plan folder layout.
- **Release discipline:** the version bump, tag, and catalog pin happen only
  through `.github/release.sh`. Breaking user-facing changes require a major
  version and a migration note in `CHANGELOG.md`.
- **The gate itself is not up for redesign.** `PASS = CANARY_OK AND EVIDENCE_OK
  AND VERIFIED AND INFRA_OK` stands. This work aligns the surroundings to it.
- **No unpublished work is disturbed.** The `ai-scan` split is paused mid-flight
  in a sibling folder; nothing here may depend on it or move it.
- **(from research)** Four stale rubric citations and one false field claim are
  in scope regardless of how the scoring question resolves — they are wrong
  under either answer. Enumerated in `research/findings.md` R2 and R3.
- **(from research)** The affected surface is exactly 10 files / 31 lines, listed
  in `research/findings.md` R4. Over half of it — 18 lines — is inside
  `codex-challenge`, whose stop condition and model-escalation rule are driven
  by the score. Any option that removes the score must replace both.

## Out of scope

- **The `ai-scan` split.** Paused, separate problem, gets its own plan.
- **Redesigning the design gate**, the canary classes, or the evidence validator.
- **Removing any command.** This is about coherence, not deletion. If a command
  turns out to be genuinely redundant, that is a finding for a later intent.
- **The readiness and audit plugins.** Untouched here.
- **Publishing anything.** No release is part of this intent.

## Open questions

1. ~~**Scoring: strip or relabel?**~~ **DECIDED 2026-09-03 by Kyle: STRIP.**
   The /40 scores and colour bands come out of `quick-audit` and
   `codex-challenge`; both become findings-with-evidence, matching the gate. The
   toolkit ends with one verdict currency, not two.

   Accepted consequence: this is the larger of the two options. 18 of the 31
   affected lines are `codex-challenge`'s convergence machinery, so its loop is
   redesigned rather than reworded — see question 3, which this decision
   promotes from conditional to blocking.

   Rejected alternative, recorded so Stage 2 does not relitigate it: *relabel*
   (keep the scores, mark them advisory) was smaller, lower-risk, and had
   precedent at `commands/quick-plan.md:72`. Not chosen — two currencies for one
   judgment is the problem this intent exists to remove, and labelling one of
   them "advisory" leaves both in the product.

2. ~~**Does anything consume `quick-audit`'s score programmatically?**~~
   **ANSWERED (research, R1): no.** All 23 references outside the command's own
   file are prose — a suggestion to run it, a help-table row, or a mode label.
   Nothing parses, stores, compares, or branches on a score. Stripping is safe
   from a data-flow standpoint; its whole cost sits in `codex-challenge`.

3. **What replaces `codex-challenge`'s stop condition and model escalation if
   the score goes?** Sharpened by research (R4): the loop stops at `>= 36/40`
   (`phases/round-loop.md:113`) and escalates models below `24/40`
   (`phases/round-loop.md:126`). Both are score expressions. A boolean gate has
   no natural "keep optimising until better" signal, so this needs a real
   answer, not a substitution. Only applies if question 1 resolves to *strip*.
   **Owner: Kyle. Deferred to design, blocking only under *strip*.**

4. **Should `/toque:documentation` be counted as part of the centerpiece or as a
   standalone generator?** It serves Stage 2 and Stage 5 but is also used alone.
   Affects only what its one-line relationship statement says. *Deferred to
   design; non-blocking.*

---

> Format note: keep this file human-readable (the product owner reviews and
> accepts it) and machine-actionable (the agent reads it and produces spec.md
> from it). Fields are structured on purpose; keep each section short and
> concrete.
