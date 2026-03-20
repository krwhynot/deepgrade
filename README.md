# DeepGrade

DeepGrade gives your codebase a letter grade. AI-powered
codebase auditing, planning, operational readiness assessment,
and documentation generation. Stack-agnostic.
Works on any codebase.

## What It Does

DeepGrade asks three questions about your codebase:

| Pillar | Question | Time Orientation |
| ------ | -------- | ---------------- |
| 1. Documentation as the Foundation | What do we have? | Past |
| 2. Phased Delivery Over Big-Bang Releases | What shape is it in? | Present |
| 3. Operational Readiness | Can we safely change it? | Future |

## Install DeepGrade Plugin

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

**Step 1:** Open a terminal (not inside Claude Code) and run:

```bash
claude plugin marketplace add krwhynot/deepgrade
```

**Step 2:** Then run:

```bash
claude plugin install deepgrade@deepgrade-marketplace --scope user
```

**Step 3:** Start Claude Code in any project:

```bash
claude
```

**Step 4:** Verify:

```
/deepgrade:help
```

## Commands (16)

### Planning

| Command | Description |
| ------- | ----------- |
| `/deepgrade:plan` | 9-phase structured planning workflow |
| `/deepgrade:quick-plan` | Lightweight plan for small changes |
| `/deepgrade:plan-status` | Check plan progress and phase status |
| `/deepgrade:plan-export` | Export a plan as a portable package |

### Auditing

| Command | Description |
| ------- | ----------- |
| `/deepgrade:codebase-audit` | Full codebase audit across all three pillars |
| `/deepgrade:quick-audit` | Audit any technical plan or spec |
| `/deepgrade:codebase-delta` | Compare against previous audit baseline |
| `/deepgrade:codebase-characterize` | Generate codebase characterization |

### Operational Readiness

| Command | Description |
| ------- | ----------- |
| `/deepgrade:readiness-scan` | AI readiness scan (9 categories, letter grade) |
| `/deepgrade:readiness-generate` | Generate improvement recs |
| `/deepgrade:codebase-gates` | Set up quality gates and baseline tracking |
| `/deepgrade:codebase-security` | Security-focused audit |

### Documentation

| Command | Description |
| ------- | ----------- |
| `/deepgrade:doc` | Generate specs, PRDs, BRDs, ADRs, READMEs |
| `/deepgrade:quick-cleanup` | Identify and fix common codebase issues |
| `/deepgrade:troubleshoot` | 4-phase debugging framework with incident triage and containment |
| `/deepgrade:help` | Show all commands and usage |

## Safety Hooks (7)

The plugin includes 7 inline safety hooks that activate
automatically. Some hooks guard multiple behaviors.

| Hook | Event | What It Does |
| ---- | ----- | ------------ |
| Active Plan Display | SessionStart | Shows current plan name |
| Migration Guard | PreToolUse Write/Edit | Blocks edits to existing migrations |
| Git + DB Guard | PreToolUse Bash | Blocks force push, hard reset, and direct DB deploys |
| Change Tracker | PostToolUse Write/Edit | Counts file changes |
| Test/Build Tracker | PostToolUse Bash | Records test and build runs |
| Session Summary | Stop | Reports file change count |
| Plan Context | PreCompact | Preserves plan name on compact |

### Database Deploy Guard

Blocks direct database migration deploys from local machine.
Supports:

| Blocked Command | Stack | Safe Exception |
| --------------- | ----- | -------------- |
| `supabase db push` | Supabase | `--dry-run`, `--local` |
| `prisma migrate deploy` | Prisma | `--dry-run` |
| `dotnet ef database update` | .NET EF Core | - |
| `flyway migrate` | Flyway | - |
| `rails db:migrate` | Rails | `RAILS_ENV=test`, `development` |

## Dependencies

**Required:** None. All hooks use jq with grep+sed fallback.

**Recommended:**
[jq](https://jqlang.github.io/jq/) for best JSON parsing
reliability.

```bash
# Windows
winget install jqlang.jq
# Then copy to Git Bash path:
cp "$LOCALAPPDATA/Microsoft/WinGet/Links/jq.exe" ~/bin/jq.exe

# Mac
brew install jq

# Linux
sudo apt install jq
```

If jq is not installed, the plugin warns on session start and
falls back to grep+sed parsing. All guards remain functional.

## Supported Stacks

The plugin auto-detects your stack. Tested on:

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
| Plan documents | `docs/plans/{date}-{name}/` | Yes |
| Specifications | `docs/specs/` | Yes |
| ADRs | `docs/adr/` | Yes |
| Session markers | `/tmp/dg-*` | No (OS-managed) |

## Architecture

- **22 agents** - Specialized scanners and generators
- **5 skills** - Docs, governance, readiness, knowledge, self-audit
- **6 doc templates** - ADR, BRD, PRD, README, release notes, spec
- **8 reference scripts** - Hook logic reference (not runtime)

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

Current: v4.27.1

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT. See [LICENSE](LICENSE).
