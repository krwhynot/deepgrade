# Toque

[![suite](https://github.com/krwhynot/toque/actions/workflows/suite.yml/badge.svg)](https://github.com/krwhynot/toque/actions/workflows/suite.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![release](https://img.shields.io/github/v/tag/krwhynot/toque?label=release&color=2ECC71)](./CHANGELOG.md)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A63D2)](https://claude.ai)

Toque takes a change from idea to release with a gate at every step. A
six-stage planning workflow for Claude Code, built around an adversarial design
gate that has to be passed rather than scored. Stack-agnostic. Works on any
codebase.

| Plugin | What it does | Who installs it |
| ------ | ------------ | --------------- |
| [`toque`](plugins/toque/) | Six-stage AI-Native SDLC planning (intent, spec, plan, test, release, maintain) with an adversarial verifier-first design gate, plan-linked troubleshooting, documentation generation | Developers living in `docs/plans/` daily |

**Upgrading from 10.x?** The codebase-audit and AI-readiness commands are no
longer part of Toque. Nothing replaces them here. Toque still reads analysis
files left in `docs/audit/` by whatever produced them, and works fine when there
are none — see [Optional inputs](interop.md).

## What It Does

Toque asks three questions about your codebase:

| Pillar | Question | Time Orientation |
| ------ | -------- | ---------------- |
| 1. Documentation as the Foundation | What do we have? | Past |
| 2. Phased Delivery Over Big-Bang Releases | What shape is it in? | Present |
| 3. Operational Readiness | Can we safely change it? | Future |

The methodology behind the plugin lives in [METHODOLOGY.md](METHODOLOGY.md).

## The plan workflow

The largest feature, and the reason most people install the toolkit.
`/toque:plan` runs six stages from idea to release. **Each stage reads the
previous artifact and commits its own** — the chain of artifacts is the audit
trail: who asked, what was produced, who approved.

| # | Stage | Commits | Gate |
| - | ----- | ------- | ---- |
| 1 | Plan | `intent.md` | A named product owner accepts |
| 2 | Design | `spec.md`, `audit.md`, `evidence/` | Scope lock, then the design gate |
| 3 | Build | `plan.md`, code, `impact-review.md` | `plan.md` approved *before* code |
| 4 | Test | `test-plan.md`, results | Automated tier passes, manual tier human-confirmed |
| 5 | Deploy | `review.md` | A named human authorizes. The agent never deploys |
| 6 | Maintain | A new `intent.md` from incidents | None — this stage never completes |

Four rules hold in every stage: human gates are real gates, nothing is
implemented without an approved `plan.md`, the agent verifies its own work
before asking for review, and **the agent never crosses the production gate**.

Stage 2 ends in a gate that can refuse. A fresh isolated auditor reviews the
spec; a canary plants a known defect to prove the audit actually looked, and
every citation is re-read from disk and compared byte-for-byte.

```
PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

No weighted sum, no partial credit.

→ **[The plan workflow](documentation/the-plan-workflow.md)** — all six stages in depth
→ **[The design gate](documentation/the-design-gate.md)** — including its known limitation
→ **[The plan workspace](documentation/plan-workspace.md)** — the folder, resume, staleness

## Install

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

**Step 1:** Open a terminal (not inside Claude Code) and add the marketplace:

```bash
claude plugin marketplace add krwhynot/toque
```

**Step 2:** Install it:

```bash
claude plugin install toque@toque-marketplace --scope user
```

**Step 3:** Start Claude Code in any project and verify:

```
/toque:help
```

`/toque:help` maps every command.

Upgrading from a pre-10.0.0 install, or want every install path? →
[Install](documentation/install.md)

## A Suggested Path

1. `/toque:quick-plan` on something small, to see the shape of the output
2. `/toque:plan` when the work is big enough to want the gate
3. `/toque:plan-status` to pick up where you left off

If some other tool has left a risk assessment, dependency map, feature
inventory or integration scan in `docs/audit/`, Toque reads them, and a plan
grounded in those beats one written from the code alone. It never requires
them.

New to it? [Quickstart](documentation/quickstart.md) walks the first plan
end to end, and suggests two lighter commands to try first.

## Documentation

| Page | What's in it |
| ---- | ------------ |
| [Quickstart](documentation/quickstart.md) | Your first plan, end to end, with what appears on disk |
| [Install](documentation/install.md) | Every install path, scopes, upgrading, what breaks without Node |
| [When to use Toque](documentation/when-to-use.md) | Use / don't use per plugin — including where it is overkill |
| [The plan workflow](documentation/the-plan-workflow.md) | All six stages in depth, approval tiers, parallelism |
| [The plan workspace](documentation/plan-workspace.md) | Plan folder anatomy, `status.json`, resume, staleness cascade |
| [The design gate](documentation/the-design-gate.md) | Canary, evidence validation, the pass expression, the limitation |

Deeper references: [GUIDE.md](plugins/toque/GUIDE.md) ·
[METHODOLOGY.md](METHODOLOGY.md) (the theory) ·
[interop.md](interop.md) (optional inputs Toque reads but does not write) ·
[CHANGELOG.md](CHANGELOG.md)

## Repository Layout

```
.claude-plugin/marketplace.json   # the catalog entry and its ref+SHA pin
plugins/toque/                    # planning core (commands, agents, skills, hooks)
documentation/                    # task-shaped user documentation
tests/                            # the suite (run-all.sh, seven layers)
docs/                             # dev-time records: plans, specs, release notes
METHODOLOGY.md                    # the methodology reference (not shipped by the plugin)
interop.md                        # optional docs/audit/ inputs Toque reads
```

Every plugin manifest carries the same version, bumped together by
`.github/release.sh` — the catalog entry always pins one ref and one SHA.

## Dependencies

Toque runs its hooks and design-gate tools as Node scripts and requires
[Node.js](https://nodejs.org/) 18 or later — the same runtime Claude Code itself
needs, so if Claude Code runs, it does too.

The always-on safety hooks that used to ship as `toque-guard` (force-push
and DB-deploy blocking, migration protection, change/test tracking) were retired
in 9.0.0. Claude Code's own permission rules cover the same commands with no
runtime dependency; see [METHODOLOGY.md §6](METHODOLOGY.md#6-defense-in-depth-safety)
for the recommended `settings.json` rules.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

Current: v11.0.1

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT. See [LICENSE](LICENSE).
