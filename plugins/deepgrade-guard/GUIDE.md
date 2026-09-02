<div align="center">

# DeepGrade Guard Guide v8.0.0

**0 Commands** &nbsp;&bull;&nbsp; **0 Skills** &nbsp;&bull;&nbsp; **5 Safety Hooks** &nbsp;&bull;&nbsp; **Requires Node.js 18+**

[![Plugin](https://img.shields.io/badge/Claude_Code-Plugin-5A45FF?style=for-the-badge)](https://github.com/krwhynot/deepgrade)
[![Version](https://img.shields.io/badge/v8.0.0-stable-2ECC71?style=for-the-badge)](#)
[![Stack](https://img.shields.io/badge/Stack-Agnostic-F39C12?style=for-the-badge)](#)

</div>

> A reference for the deepgrade-guard plugin: always-on safety rails with zero context cost.

DeepGrade Guard is the toolkit's immune system, shipped on its own so every
setup can have it — with or without the planning, readiness, or audit plugins.
Its hooks fire automatically at specific points in the Claude Code lifecycle to
prevent common mistakes: they intercept actions and either block them, ask for
confirmation, or silently record data. There are no commands to learn and no
agents or skills loading into context; the plugin declares 5 handlers in
`hooks/hooks.json`, one Node script each under `scripts/`, and **requires
Node.js 18 or later** — the same runtime Claude Code itself needs. Without
Node the hooks cannot start and Claude Code reports a hook error on each
guarded event: absent and loud beats present and wrong.

The trackers and the session summary communicate through session markers in
`$TMPDIR/dg-*` (`%TEMP%` on Windows) — the complete marker bus ships in this
one plugin, so the Stop-time summary always sees what the trackers wrote.

## The 5 Hooks

### ![guard](https://img.shields.io/badge/-GUARD-E74C3C) Migration Guard
**Fires when:** You try to edit a file inside `migrations/` or `Migrations/` that already exists and ends in `.sql`.
**What it does:** Blocks the edit with exit code 2.
**Why:** Existing migrations are immutable history. If your database has already applied migration `003_add_users.sql`, editing it won't re-apply the changes -- it will just make your migration history inconsistent. The next time someone runs migrations from scratch, they get a different database than production. Create a new migration instead.

> [!CAUTION]
> `[DeepGrade] MIGRATION GUARD: Editing existing migration migrations/003_add_users.sql. Create a NEW migration instead.`

### ![guard](https://img.shields.io/badge/-GUARD-E74C3C) Force Push Guard
**Fires when:** You run any command matching `git push --force`.
**What it does:** Blocks the command.
**Why:** Force pushing rewrites remote history. If a teammate has already pulled commits you force-push over, their local branch diverges from remote in ways that are painful to recover from. Use `--force-with-lease` if you truly need to overwrite (it checks that the remote hasn't changed since you last fetched).

> [!CAUTION]
> `[DeepGrade] BLOCKED: Force push not allowed.`

### ![guard](https://img.shields.io/badge/-GUARD-E74C3C) Hard Reset Guard
**Fires when:** You run `git reset --hard`.
**What it does:** Asks for confirmation before the command runs.
**Why:** `git reset --hard` permanently discards all uncommitted changes in your working tree. There is no undo. If Claude has been editing files for 30 minutes and you hard-reset, all that work vanishes. The guard forces you to think twice.

> [!WARNING]
> `[DeepGrade] WARNING: git reset --hard discards changes.`

### ![guard](https://img.shields.io/badge/-GUARD-E74C3C) Database Deploy Guard
**Fires when:** You run a database migration deploy command (`supabase db push`, `prisma migrate deploy`, `dotnet ef database update`, `flyway migrate`, or `rails db:migrate`) without a safe flag.
**What it does:** Blocks the command unless it includes `--dry-run`, `--local`, `RAILS_ENV=test`, or `RAILS_ENV=development`.
**Why:** Deploying migrations directly from your local machine to a production or shared database bypasses CI/CD safety nets. One wrong migration can corrupt data for every user. Deploy via your CI/CD pipeline instead. Use `--dry-run` to validate locally.

> [!CAUTION]
> `[DeepGrade] BLOCKED: Direct database deploy to remote. Use --dry-run to validate, or deploy via CI/CD.`

### ![tracker](https://img.shields.io/badge/-TRACK-4A90D9) Change Tracker
**Fires when:** Any file is written or edited (PostToolUse).
**What it does:** Silently increments a counter in `/tmp/dg-baseline-{session}`. If the count exceeds 15 (configurable via `DG_CHANGE_THRESHOLD`), it suggests running `/deepgrade-audit:codebase-delta`.
**Why:** Tracks how much the codebase has changed since the last audit baseline. When you've changed enough files, the audit data starts going stale and a delta check is worthwhile.

> [!NOTE]
> Nothing visible until threshold, then: `[DeepGrade] 15 files changed since last audit. Consider /deepgrade-audit:codebase-delta.`

### ![tracker](https://img.shields.io/badge/-TRACK-4A90D9) Test/Build Tracker
**Fires when:** Any bash command runs that looks like a test or build command (PostToolUse).
**What it does:** Silently writes timestamps to `/tmp/dg-test-{session}` and `/tmp/dg-build-{session}`. Recognizes test/build commands for Node (jest, vitest, npm test), Python (pytest), .NET (dotnet test), Rust (cargo test/build), and Go (go test/vet).
**Why:** The Stop hook and Git Guard use these timestamps to know whether tests and builds ran during the session. If you edited files but never ran tests, you get a warning.

> [!NOTE]
> Completely silent. No output.

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Session Summary (Stop Hook)
**Fires when:** The Claude Code session ends.
**What it does:** Reports the total number of files changed. If tests exist in the project but none ran during the session, it warns you.
**Why:** A simple accountability checkpoint. "You changed 12 files but didn't run tests" is a useful nudge before you walk away.

> [!TIP]
> `[DeepGrade] Session: 12 files changed.` or `[DeepGrade] 12 files changed but no tests ran. Run tests before finishing.`

### ![info](https://img.shields.io/badge/-INFO-2ECC71) Plan Context (PreCompact Hook)
**Fires when:** Claude Code's context window is getting full and it needs to compress earlier messages.
**What it does:** Injects the active plan name and current phase into the compressed context so Claude doesn't lose track of what you're working on.
**Why:** Without this, Claude might forget which plan you were on after a compaction. The hook ensures continuity.

> [!TIP]
> `[DeepGrade] Compacting. Plan: worldpay-canada. Resume with /deepgrade:plan worldpay-canada`


---

## How to Install

```bash
claude plugin marketplace add krwhynot/deepgrade
claude plugin install deepgrade-guard@deepgrade-marketplace --scope user
```

User scope (recommended) makes the plugin available in every project; use
`--scope project` to limit it to one. Verify with:

```
/plugin details deepgrade-guard   (must report Hooks (5))
```

## How to Update

An installed plugin lives in a **versioned cache directory**, and third-party marketplace auto-update
is **off by default**. Pulling the repository does not update an installed copy — you must refresh the
marketplace and update the plugin explicitly:

```
/plugin marketplace update deepgrade-marketplace
/plugin update deepgrade-guard
/reload-plugins
/plugin list
```

`/plugin list` is the verification step: confirm the version shown is the one you expect. **Without a
version bump in `plugin.json`, nothing propagates** — the version is the cache key.

> [!IMPORTANT]
> **Editing plugin files does not affect an installed copy.** The live-edit workflow — where changes
> take effect on the next session with no reinstall — applies **only** when you run Claude Code with
> `--plugin-dir`, pointing directly at your working tree:
> ```bash
> claude --plugin-dir /path/to/deepgrade/plugins/deepgrade-guard
> ```
> Use this for plugin development. For an installed plugin, use the four-command sequence above.
