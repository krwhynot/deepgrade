# Toque

[![suite](https://github.com/krwhynot/toque/actions/workflows/suite.yml/badge.svg)](https://github.com/krwhynot/toque/actions/workflows/suite.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![release](https://img.shields.io/github/v/tag/krwhynot/toque?label=release&color=2ECC71)](./CHANGELOG.md)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-plugin-8A63D2)](https://claude.ai)

Toque gives your codebase a letter grade. AI-powered codebase auditing,
planning, operational readiness assessment, and documentation generation for
Claude Code. Stack-agnostic. Works on any codebase.

This repository is a monorepo of **three plugins with lockstep versions** — one
marketplace, one release, install any subset:

| Plugin | What it does | Who installs it |
| ------ | ------------ | --------------- |
| [`toque`](plugins/toque/) | Six-stage AI-Native SDLC planning (intent, spec, plan, test, release, maintain) with an adversarial verifier-first design gate, plan-linked troubleshooting, documentation generation | Developers living in `docs/plans/` daily |
| [`toque-readiness`](plugins/toque-readiness/) | AI-readiness scan: 52 checks, 9 categories, composite letter grade A+ to F, generated scaffolding | Consultants and leads grading many repos |
| [`toque-audit`](plugins/toque-audit/) | Severity-graded codebase audits, security scans, delta/KPI tracking, characterization tests, generated CI gates | Engineering managers doing due diligence |

Not sure which? → [Choosing a plugin](documentation/choosing-a-plugin.md)

## What It Does

Toque asks three questions about your codebase:

| Pillar | Question | Time Orientation |
| ------ | -------- | ---------------- |
| 1. Documentation as the Foundation | What do we have? | Past |
| 2. Phased Delivery Over Big-Bang Releases | What shape is it in? | Present |
| 3. Operational Readiness | Can we safely change it? | Future |

The methodology behind all three plugins lives in [METHODOLOGY.md](METHODOLOGY.md).

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

**Step 2:** Install the plugins you want (any subset works):

```bash
claude plugin install toque@toque-marketplace --scope user
claude plugin install toque-readiness@toque-marketplace --scope user
claude plugin install toque-audit@toque-marketplace --scope user
```

**Step 3:** Start Claude Code in any project and verify:

```
/toque:help
```

`/toque:help` (from the `toque` plugin) shows the full toolkit map,
including the commands that belong to the sibling plugins.

Upgrading from a pre-10.0.0 install, or want every install path? →
[Install](documentation/install.md)

## A Suggested Path Through the Toolkit

1. `/toque-readiness:readiness-scan` for a baseline navigability grade
2. `/toque-readiness:readiness-generate` to fix the low-hanging issues
3. `/toque-audit:codebase-audit` once the readiness score is healthy
4. `/toque:plan` to plan the remediation work the audit surfaced
5. `/toque-audit:codebase-delta` after changes, to verify improvement

New to it? [Quickstart](documentation/quickstart.md) walks the first plan
end to end, and suggests two lighter commands to try first.

## Documentation

| Page | What's in it |
| ---- | ------------ |
| [Quickstart](documentation/quickstart.md) | Your first plan, end to end, with what appears on disk |
| [Install](documentation/install.md) | Every install path, scopes, upgrading, what breaks without Node |
| [Choosing a plugin](documentation/choosing-a-plugin.md) | Which of the three you need, and whether they compose |
| [When to use Toque](documentation/when-to-use.md) | Use / don't use per plugin — including where it is overkill |
| [The plan workflow](documentation/the-plan-workflow.md) | All six stages in depth, approval tiers, parallelism |
| [The plan workspace](documentation/plan-workspace.md) | Plan folder anatomy, `status.json`, resume, staleness cascade |
| [The design gate](documentation/the-design-gate.md) | Canary, evidence validation, the pass expression, the limitation |

Deeper references: per-plugin `GUIDE.md` files
([toque](plugins/toque/GUIDE.md) ·
[readiness](plugins/toque-readiness/GUIDE.md) ·
[audit](plugins/toque-audit/GUIDE.md)) ·
[METHODOLOGY.md](METHODOLOGY.md) (the theory) ·
[interop.md](interop.md) · [CHANGELOG.md](CHANGELOG.md)

## Repository Layout

```
.claude-plugin/marketplace.json   # the three catalog entries, one shared ref+SHA pin
plugins/toque/                    # planning core (commands, agents, skills, hooks)
plugins/toque-readiness/          # readiness scanners
plugins/toque-audit/              # audit agents
documentation/                    # task-shaped user documentation
tests/                            # one suite for the whole monorepo (run-all.sh)
docs/                             # dev-time records: plans, specs, release notes
METHODOLOGY.md                    # the methodology reference (not shipped by any plugin)
```

Every plugin manifest carries the same version, bumped together by
`.github/release.sh` — the three catalog entries always pin one ref and one SHA.

## Dependencies

The `toque` plugin runs its hooks and design-gate tools as Node scripts
and requires [Node.js](https://nodejs.org/) 18 or later — the same runtime
Claude Code itself needs, so if Claude Code runs, it does too.
`toque-readiness` and `toque-audit` need nothing beyond Claude Code.

The always-on safety hooks that used to ship as `toque-guard` (force-push
and DB-deploy blocking, migration protection, change/test tracking) were retired
in 9.0.0. Claude Code's own permission rules cover the same commands with no
runtime dependency; see [METHODOLOGY.md §6](METHODOLOGY.md#6-defense-in-depth-safety)
for the recommended `settings.json` rules.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

Current: v10.0.0

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT. See [LICENSE](LICENSE).
