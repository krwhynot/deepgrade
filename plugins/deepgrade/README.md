# DeepGrade (planning core)

DeepGrade's planning plugin: a 9-phase idea-to-handoff planning workflow with an
adversarial, verifier-first audit gate, plan-linked troubleshooting, and
documentation generation. Stack-agnostic. Works on any codebase.

This is one of four DeepGrade plugins in the
[deepgrade monorepo](https://github.com/krwhynot/deepgrade). It pairs with
`deepgrade-readiness` (AI-readiness grading), `deepgrade-audit` (codebase
audits), and `deepgrade-guard` (always-on safety hooks) — install any subset.

## Install

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

```bash
claude plugin marketplace add krwhynot/deepgrade
claude plugin install deepgrade@deepgrade-marketplace --scope user
```

Verify inside a Claude Code session:

```
/deepgrade:help
```

## Commands (9)

### Planning

| Command | Description |
| ------- | ----------- |
| `/deepgrade:plan` | 9-phase structured planning workflow |
| `/deepgrade:quick-plan` | Lightweight plan for small changes |
| `/deepgrade:plan-status` | Check plan progress and phase status |
| `/deepgrade:plan-export` | Export a plan as a portable package |

### Auditing and Review

| Command | Description |
| ------- | ----------- |
| `/deepgrade:quick-audit` | Audit any technical plan or spec |
| `/deepgrade:codex-challenge` | Adversarial review loop against OpenAI Codex |

### Documentation and Support

| Command | Description |
| ------- | ----------- |
| `/deepgrade:documentation` | Generate specs, PRDs, BRDs, ADRs, READMEs |
| `/deepgrade:quick-cleanup` | Clean a folder of messy documents into reference material |
| `/deepgrade:troubleshoot` | 4-phase debugging framework with incident triage and containment |
| `/deepgrade:help` | Show all commands and usage |

`/deepgrade:documentation` is a skill surface; the other entries are command files.

## Safety Hooks (3)

The plugin includes 3 plan-context hooks that activate automatically. They are
declared in `hooks/hooks.json` and run as Node scripts from `scripts/`, one file
per handler. **Requires Node.js 18 or later** — the same runtime Claude Code
itself needs. The git/migration/tracking rails live in the `deepgrade-guard`
plugin, recommended as a co-install.

| Hook | Event | What It Does |
| ---- | ----- | ------------ |
| Active Plan Display | SessionStart | Reports the active plan, its phase, and audit staleness |
| Subagent Log | SubagentStop | Logs subagent completions to the active plan |
| Plan Context | PreCompact | Preserves plan name and phase on compact |

## Dependencies

**Required:** [Node.js](https://nodejs.org/) 18 or later — the same runtime Claude
Code itself needs, so if Claude Code runs, this does too.

```bash
node --version   # must print v18.0.0 or higher
```

**What happens without Node.** The hooks cannot start, and Claude Code reports a
hook error on each guarded event. That is deliberate: absent and loud beats
present and wrong.

## File Output Locations

| Output | Location | Committed? |
| ------ | -------- | ---------- |
| Plan documents | `docs/plans/{date}-{name}/` | Yes |
| Audit evidence | `docs/plans/{date}-{name}/evidence/` | Yes |
| Specifications | `docs/specs/` | Yes |
| ADRs | `docs/adr/` | Yes |

## Architecture

- **2 agents** - plan-auditor (the isolated judge) and plan-scaffolder
- **3 skills** - documentation, MCP research, self-audit knowledge
- **6 doc templates** - ADR, BRD, PRD, README, release notes, spec
- **3 hook handlers** - `scripts/dg-*.js` plan-context layer, plus the
  `dg-canary.js` / `dg-evidence-validate.js` audit tooling invoked by `/deepgrade:plan`

## Version History

See the monorepo [CHANGELOG](https://github.com/krwhynot/deepgrade/blob/main/CHANGELOG.md).

Current: v7.0.0

## License

MIT.
