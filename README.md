# DeepGrade

DeepGrade gives your codebase a letter grade. AI-powered codebase auditing, planning, operational readiness assessment, and documentation generation. Stack-agnostic. Works on any codebase.

## What It Does

DeepGrade asks three questions about your codebase:

| Pillar | Question | Time Orientation |
|--------|----------|-----------------|
| 1. Documentation as the Foundation | What do we have? | Past |
| 2. Phased Delivery Over Big-Bang Releases | What shape is it in? | Present |
| 3. Operational Readiness | Can we safely change it? | Future |

## Quick Start

### Install from GitHub

```bash
# Clone the repo
git clone https://github.com/krwhynot/deepgrade.git

# In Claude Code, add as a local marketplace
/plugin marketplace add /path/to/deepgrade

# Install to user scope (available in all projects)
/plugin install deepgrade --scope user

# Verify
/deepgrade:help
```

### Install from Local Directory

```bash
# Add the directory as a marketplace
/plugin marketplace add C:\Users\YourName\claude-plugins

# Install
/plugin install deepgrade --scope user
```

## Commands (16)

### Planning
| Command | Description |
|---------|-------------|
| `/deepgrade:plan` | 8-phase structured planning workflow |
| `/deepgrade:quick-plan` | Lightweight plan for small changes |
| `/deepgrade:plan-status` | Check plan progress and phase status |
| `/deepgrade:plan-export` | Export a plan as a self-contained portable package |

### Auditing
| Command | Description |
|---------|-------------|
| `/deepgrade:codebase-audit` | Full codebase audit across all three pillars |
| `/deepgrade:quick-audit` | Audit any technical plan or spec (8-dimension scoring) |
| `/deepgrade:codebase-delta` | Compare current codebase against previous audit baseline |
| `/deepgrade:codebase-characterize` | Generate a characterization of the codebase |

### Operational Readiness
| Command | Description |
|---------|-------------|
| `/deepgrade:readiness-scan` | AI readiness scan (9 categories, letter grade) |
| `/deepgrade:readiness-generate` | Generate improvement recommendations from scan results |
| `/deepgrade:codebase-gates` | Set up quality gates and baseline tracking |
| `/deepgrade:codebase-security` | Security-focused audit |

### Documentation
| Command | Description |
|---------|-------------|
| `/deepgrade:doc` | Generate specs, PRDs, BRDs, ADRs, READMEs, release notes |
| `/deepgrade:quick-cleanup` | Identify and fix common codebase issues |
| `/deepgrade:troubleshoot` | 4-phase debugging framework |
| `/deepgrade:help` | Show all commands and usage |

## Safety Hooks (7)

The plugin includes inline safety hooks that activate automatically:

| Hook | Event | What It Does |
|------|-------|-------------|
| Active Plan Display | SessionStart | Shows current plan name on session start |
| Migration Guard | PreToolUse Write/Edit | Blocks edits to existing migration files |
| Force Push Guard | PreToolUse Bash | Blocks `git push --force` |
| Hard Reset Guard | PreToolUse Bash | Blocks `git reset --hard` |
| DB Deploy Guard | PreToolUse Bash | Blocks direct database deploys to remote (5 stacks) |
| Change Tracker | PostToolUse Write/Edit | Counts file changes per session |
| Test/Build Tracker | PostToolUse Bash | Records when tests and builds run |
| Session Summary | Stop | Reports file change count (informational, non-blocking) |
| Plan Context | PreCompact | Preserves active plan name during context compaction |

### Database Deploy Guard

Blocks direct database migration deploys from local machine. Supports:

| Blocked Command | Stack | Safe Exception |
|----------------|-------|----------------|
| `supabase db push` | Supabase | `--dry-run`, `--local` |
| `prisma migrate deploy` | Prisma | `--dry-run` |
| `dotnet ef database update` | .NET EF Core | - |
| `flyway migrate` | Flyway | - |
| `rails db:migrate` | Rails | `RAILS_ENV=test`, `RAILS_ENV=development` |

## Dependencies

**Required:** None. All hooks use jq with grep+sed fallback.

**Recommended:** [jq](https://jqlang.github.io/jq/) for best JSON parsing reliability.

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

If jq is not installed, the plugin warns on session start and falls back to grep+sed parsing. All guards remain functional.

## Supported Stacks

The plugin auto-detects your stack. Tested on:

| Stack | Detection |
|-------|-----------|
| Node/React/TypeScript | package.json, tsconfig.json |
| .NET (C#/VB.NET) | *.sln, *.csproj, *.vbproj |
| Python | pyproject.toml, setup.py, requirements.txt |
| Rust | Cargo.toml |
| Go | go.mod |

## File Output Locations

| Output | Location | Committed? |
|--------|----------|-----------|
| Audit reports | `docs/audit/` | Yes |
| Plan documents | `docs/plans/{date}-{name}/` | Yes |
| Specifications | `docs/specs/` | Yes |
| ADRs | `docs/adr/` | Yes |
| Session markers | `/tmp/tp-*` | No (OS-managed) |

## Architecture

- **22 agents** - Specialized scanners and generators
- **4 skills** - Documentation, governance, readiness scoring, deepgrade knowledge
- **6 doc templates** - ADR, BRD, PRD, README, release notes, spec
- **8 reference scripts** - Hook logic reference (not used at runtime, hooks are inline)

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

Current: v4.27.1

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT. See [LICENSE](LICENSE).
