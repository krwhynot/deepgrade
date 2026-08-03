# DeepGrade Guard

Always-on safety rails for Claude Code sessions: blocks force pushes and direct
database deploys, protects existing migrations, tracks file changes and test
runs, and summarizes every session. No commands, no agents, no skills — zero
context cost. Recommended as a universal co-install alongside any other
DeepGrade plugin, and useful entirely on its own.

This is one of four DeepGrade plugins in the
[deepgrade monorepo](https://github.com/krwhynot/deepgrade).

## Install

**Prerequisite:** Claude Code installed ([claude.ai](https://claude.ai))

```bash
claude plugin marketplace add krwhynot/deepgrade
claude plugin install deepgrade-guard@deepgrade-marketplace --scope user
```

## Safety Hooks (5)

The 5 hooks activate automatically on every session. They are declared in
`hooks/hooks.json` and run as Node scripts from `scripts/`, one file per
handler. **Requires Node.js 18 or later** — the same runtime Claude Code itself
needs.

| Hook | Event | What It Does |
| ---- | ----- | ------------ |
| Migration Guard | PreToolUse Write/Edit | Blocks edits to existing migrations |
| Git + DB Guard | PreToolUse Bash | Blocks force push and direct DB deploys; asks before a hard reset |
| Change Tracker | PostToolUse Write/Edit | Counts file changes, nudges when an audit is stale |
| Test/Build Tracker | PostToolUse Bash | Records test and build runs |
| Session Summary | Stop | Reports file change count and warns if no tests ran |

### Database Deploy Guard

Blocks direct database migration deploys from the local machine. Supports:

| Blocked Command | Stack | Safe Exception |
| --------------- | ----- | -------------- |
| `supabase db push` | Supabase | `--dry-run`, `--local` |
| `prisma migrate deploy` | Prisma | `--dry-run` |
| `dotnet ef database update` | .NET EF Core | - |
| `flyway migrate` | Flyway | - |
| `rails db:migrate` | Rails | `RAILS_ENV=test`, `development` |

## Dependencies

**Required:** [Node.js](https://nodejs.org/) 18 or later — the same runtime Claude
Code itself needs, so if Claude Code runs, this does too.

```bash
node --version   # must print v18.0.0 or higher
```

**What happens without Node.** The hooks cannot start, and Claude Code reports a
hook error on each guarded event. That is deliberate: the pre-5.0.0 design
degraded quietly to a weaker parser, so you could not tell a working safety
layer from a broken one. Absent and loud beats present and wrong.

## File Output Locations

| Output | Location | Committed? |
| ------ | -------- | ---------- |
| Session markers | `$TMPDIR/dg-*` (`%TEMP%` on Windows) | No (OS-managed) |

The trackers, the git/DB guard, and the session summary communicate through the
session markers above — the complete marker bus ships in this one plugin, so the
Stop-time summary always sees what the trackers wrote.

## Version History

See the monorepo [CHANGELOG](https://github.com/krwhynot/deepgrade/blob/main/CHANGELOG.md).

Current: v7.1.0

## License

MIT.
