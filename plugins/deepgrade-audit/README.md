# DeepGrade Audit

Codebase auditing for engineering due diligence: a team of parallel agents
produces a severity-graded audit report, a security-focused scan, delta/KPI
tracking against previous baselines, golden-master characterization tests, and
generated CI quality gates. Stack-agnostic.

This is one of four DeepGrade plugins in the
[deepgrade monorepo](https://github.com/krwhynot/deepgrade). It pairs with
`deepgrade-readiness` (run that first for a baseline grade) and
`deepgrade-guard` (always-on safety rails).

## Install

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

```bash
claude plugin marketplace add krwhynot/deepgrade
claude plugin install deepgrade-audit@deepgrade-marketplace --scope user
```

## Commands (5)

| Command | Description |
| ------- | ----------- |
| `/deepgrade-audit:codebase-audit` | Full codebase audit. 6 parallel agents: features, dependencies, docs, risk, integrations, report |
| `/deepgrade-audit:codebase-security` | Security-focused scan: dependency vulns, secrets, SSL, injection risks |
| `/deepgrade-audit:codebase-delta` | Quick re-measurement against the previous baseline. What improved, what regressed |
| `/deepgrade-audit:codebase-gates` | Generate CI quality gates and Claude Code hooks from audit findings |
| `/deepgrade-audit:codebase-characterize` | Golden master tests that capture behavior before refactoring |

## Architecture

- **10 agents** - feature/dependency/doc/integration/risk/security/delta
  scanners, the characterization and gate generators, and the report generator
- **3 skills** - deepgrade-knowledge, governance-knowledge, self-audit-knowledge
- No hooks and no scripts: the plugin only acts when you invoke a command.

## Supported Stacks

The scanners auto-detect your stack. Tested on:

| Stack | Detection |
| ----- | --------- |
| Node/React/TypeScript | package.json, tsconfig.json |
| .NET (C#/VB.NET) | \*.sln, \*.csproj, \*.vbproj |
| Python | pyproject.toml, setup.py, requirements.txt |
| Rust | Cargo.toml |
| Go | go.mod |

## File Output Locations

| Output | Location | Committed? |
| ------ | -------- | ---------- |
| Audit reports | `docs/audit/` | Yes |
| Characterization tests | the project's test tree | Yes |
| Generated gates | `.github/workflows/`, the hooks key of `.claude/settings.json` | Yes |

## Version History

See the monorepo [CHANGELOG](https://github.com/krwhynot/deepgrade/blob/main/CHANGELOG.md).

Current: v7.1.0

## License

MIT.
