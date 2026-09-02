# DeepGrade Readiness

AI-readiness scanning for any codebase: 52 checks across 9 categories score how
well an AI coding agent can read, navigate, and safely modify a project. The
result is a composite letter grade (A+ to F) and a prioritized list of what to
fix first, with generated scaffolding for the gaps. Stack-agnostic.

This is one of four DeepGrade plugins in the
[deepgrade monorepo](https://github.com/krwhynot/deepgrade). It pairs with
`deepgrade-audit` for deeper code-quality audits once readiness is in shape.

## Install

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

```bash
claude plugin marketplace add krwhynot/deepgrade
claude plugin install deepgrade-readiness@deepgrade-marketplace --scope user
```

## Commands (2)

| Command | Description |
| ------- | ----------- |
| `/deepgrade-readiness:readiness-scan` | AI readiness scan (52 checks, 9 categories, letter grade) |
| `/deepgrade-readiness:readiness-generate` | Generate the missing artifacts the scan found |

Category 9 (Database) is conditional and only runs if the codebase uses a
database.

## Architecture

- **10 agents** - nine category scanners plus the readiness report generator
- **1 skill** - readiness-scoring (gate thresholds, confidence levels, grading)
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
| Readiness reports | `docs/audit/` | Yes |
| Machine-readable scores | `docs/audit/readability/readability-score.json` | Yes |

## Version History

See the monorepo [CHANGELOG](https://github.com/krwhynot/deepgrade/blob/main/CHANGELOG.md).

Current: v8.0.0

## License

MIT.
