# CR-7 — descope the U7 compatibility floor; close F24 on current-version evidence

**Raised:** 2026-08-03, by Claude (optimizer), in a proportionality assessment the owner
requested ("are we over engineering this?") after the auth-free half of the floor bisection
completed.
**State: RATIFIED** — owner directive "descope", 2026-08-03, given in direct response to the
assessment and its named alternative (finish the dispatch probes for a declared floor).

**Replaces** F24's remaining acceptance clause, verbatim:

> zero hook errors on healthy supported hosts, runtime-verified locally + at the U7 floor

with:

> zero hook errors on healthy supported hosts, runtime-verified locally on the current Claude
> Code version at each release; CI (hosted ubuntu+windows) runs the suite and
> `claude plugin validate --strict` on current; auto-updating Claude Code is assumed and **no
> compatibility floor is declared**.

## Why

The floor requirement dates from the plan's compensating-for-false-closures era ("a floor is
credible only when CI executes it", §3.6, owner-accepted then). Executing its first half
produced the evidence that undermined its second:

- **The floor's user population is approximately zero.** Claude Code auto-updates; the
  interval's old versions are not where users live.
- **The bisected edge measures dev tooling, not users.** The auth-free floor is 2.1.145
  because that is where `validate --strict` appears — a CI flag. Users on 2.1.144 install the
  pinned git-subdir catalog successfully (probed, verbatim in
  `research/u7-floor-evidence.md`).
- **The remaining cost protects no one.** The six dispatch behaviors need an authentication
  decision, a purpose-built probe plugin, and roughly half a day — to certify hook dispatch on
  versions nobody runs.

The half that was executed is kept: `research/u7-floor-evidence.md` records the seven-probe
ladder and the 2.1.145/`--strict` and ≤2.1.144/git-subdir facts permanently.

## What this closes and retires

- **F24 → CLOSED.** Its narrowed remainder was exactly the floor clause. The replacing clause
  is satisfied by existing evidence: check H (zero hook errors, owner-observed,
  `research/layer7-runtime-evidence.md`) and the green hosted CI matrix on every push.
- **PHV5-003 → RETIRED, not completed.** The floor-discovery ticket ends half-executed by
  design; its artifact stands. It is deliberately NOT added to `tickets_complete`.
- **§10.3's required floor-version CI job → not built**, by the same reasoning; the existing
  matrix (current version, both OSes) is the verification that matches reality.

## Alternatives considered

- **Finish the dispatch probes and declare the floor** (the assessment's stated alternative):
  half a day plus an auth decision for a `requires ≥2.1.145` README line whose protective
  value is nil under auto-update. Rejected by the owner in choosing this CR.
- **Leave F24 PARTIAL indefinitely:** honest but permanently dangling — the clause would sit
  unmeetable-by-decision rather than unmeetable-by-evidence, which this plan's conventions
  treat as a requirement change needing a CR, not a stall.
- **Silently drop the clause:** the N1 failure mode this plan exists to prevent.

## Acceptance

- This CR file exists with the owner's ratification recorded.
- `status.json`: F24 moved to `findings_closed`; `findings_partial` empty of findings; a dated
  record key documents the descope; PHV5-003 absent from `tickets_complete`.
- `research/u7-floor-evidence.md` disposition updated: floor deliberately not declared,
  descoped by this CR; probe evidence preserved.
- Consistency sweep and full suite green.

## If the owner un-ratifies

The floor work resumes exactly where the artifact left off: dispatch behaviors 1–4, 6–7 at
candidate 2.1.145, auth decision first. Nothing in this CR destroys evidence or capability.
