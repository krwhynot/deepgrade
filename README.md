# DeepGrade

DeepGrade gives your codebase a letter grade. AI-powered codebase auditing,
planning, operational readiness assessment, and documentation generation for
Claude Code. Stack-agnostic. Works on any codebase.

This repository is a monorepo of **three plugins with lockstep versions** — one
marketplace, one release, install any subset:

| Plugin | What it does | Who installs it |
| ------ | ------------ | --------------- |
| [`deepgrade`](plugins/deepgrade/) | Six-stage AI-Native SDLC planning (intent, spec, plan, test, release, maintain) with an adversarial verifier-first design gate, plan-linked troubleshooting, documentation generation | Developers living in `docs/plans/` daily |
| [`deepgrade-readiness`](plugins/deepgrade-readiness/) | AI-readiness scan: 52 checks, 9 categories, composite letter grade A+ to F, generated scaffolding | Consultants and leads grading many repos |
| [`deepgrade-audit`](plugins/deepgrade-audit/) | Severity-graded codebase audits, security scans, delta/KPI tracking, characterization tests, generated CI gates | Engineering managers doing due diligence |

## What It Does

DeepGrade asks three questions about your codebase:

| Pillar | Question | Time Orientation |
| ------ | -------- | ---------------- |
| 1. Documentation as the Foundation | What do we have? | Past |
| 2. Phased Delivery Over Big-Bang Releases | What shape is it in? | Present |
| 3. Operational Readiness | Can we safely change it? | Future |

The methodology behind all three plugins lives in [METHODOLOGY.md](METHODOLOGY.md).

## Install

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

**Step 1:** Open a terminal (not inside Claude Code) and add the marketplace:

```bash
claude plugin marketplace add krwhynot/deepgrade
```

**Step 2:** Install the plugins you want (any subset works):

```bash
claude plugin install deepgrade@deepgrade-marketplace --scope user
claude plugin install deepgrade-readiness@deepgrade-marketplace --scope user
claude plugin install deepgrade-audit@deepgrade-marketplace --scope user
```

**Step 3:** Start Claude Code in any project and verify:

```
/deepgrade:help
```

`/deepgrade:help` (from the `deepgrade` plugin) shows the full toolkit map,
including the commands that belong to the sibling plugins.

## A Suggested Path Through the Toolkit

1. `/deepgrade-readiness:readiness-scan` for a baseline navigability grade
2. `/deepgrade-readiness:readiness-generate` to fix the low-hanging issues
3. `/deepgrade-audit:codebase-audit` once the readiness score is healthy
4. `/deepgrade:plan` to plan the remediation work the audit surfaced
5. `/deepgrade-audit:codebase-delta` after changes, to verify improvement

## Repository Layout

```
.claude-plugin/marketplace.json   # the three catalog entries, one shared ref+SHA pin
plugins/deepgrade/                # planning core (commands, agents, skills, hooks)
plugins/deepgrade-readiness/      # readiness scanners
plugins/deepgrade-audit/          # audit agents
tests/                            # one suite for the whole monorepo (run-all.sh)
docs/                             # dev-time records: plans, specs, release notes
METHODOLOGY.md                    # the methodology reference (not shipped by any plugin)
```

Every plugin manifest carries the same version, bumped together by
`.github/release.sh` — the three catalog entries always pin one ref and one SHA.

## Dependencies

The `deepgrade` plugin runs its hooks and design-gate tools as Node scripts
and requires [Node.js](https://nodejs.org/) 18 or later — the same runtime
Claude Code itself needs, so if Claude Code runs, it does too.
`deepgrade-readiness` and `deepgrade-audit` need nothing beyond Claude Code.

The always-on safety hooks that used to ship as `deepgrade-guard` (force-push
and DB-deploy blocking, migration protection, change/test tracking) were retired
in 9.0.0. Claude Code's own permission rules cover the same commands with no
runtime dependency; see [METHODOLOGY.md §6](METHODOLOGY.md#6-defense-in-depth-safety)
for the recommended `settings.json` rules.

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

Current: v9.0.0

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT. See [LICENSE](LICENSE).
