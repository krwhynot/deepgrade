# Install

Every install path for Toque, what it needs, and how to tell whether it worked.

## Prerequisites

| Requirement | Check |
| --- | --- |
| Claude Code | `claude --version` |
| Node.js 18+ (hooks and the design-gate tools) | `node --version` |

Node is the same runtime Claude Code itself requires, so in practice if Claude
Code runs, Toque runs. See [What happens without
Node](#what-happens-without-node) if you are not sure.

## Add the marketplace

Run this in a terminal, **not** inside a Claude Code session:

```bash
claude plugin marketplace add krwhynot/toque
```

This registers the catalog. It installs nothing on its own.

## Install the plugin

```bash
claude plugin install toque@toque-marketplace --scope user
```

### Scope

`--scope user` installs for your account, so the plugin is available in every
project you open. Drop the flag to install into the current project only, which
is the right choice when you want the plugin pinned alongside a repo for
everyone working in it.

## Verify

Start Claude Code in any project and run:

```
/toque:help
```

`/toque:help` prints every command, so it doubles as a check that the plugin
registered.

## Updating

```bash
claude plugin update toque@toque-marketplace
```

## Upgrading from a pre-10.0.0 install

Version 10.0.0 renamed the project. The old plugin names are gone from the
catalog, so an existing install does not upgrade in place — it has to be
replaced:

```bash
claude plugin uninstall <old-plugin-name>          # for each one you had
claude plugin marketplace remove <old-marketplace>
claude plugin marketplace add krwhynot/toque
claude plugin install toque@toque-marketplace --scope user
```

Two things do not migrate automatically:

- **Environment variables.** Anything you set in a shell profile or CI config
  must be respelled to the `TQ_` prefix. The former spellings are not read and
  fail silently.
- **Slash commands written into files.** Commands baked into scripts, prompts,
  or `CLAUDE.md` files must be respelled to the `/toque:` prefix.

Plan folders under `docs/plans/` are untouched and need no migration.

## What happens without Node

The `toque` plugin's three hooks cannot start, and Claude Code reports a hook
error on each guarded event. That is deliberate — absent and loud beats present
and wrong.

The two design-gate tools fail the same way, and **Stage 2 of `/toque:plan`
cannot pass without them**. There is no degraded mode that skips the gate.

## Optional integrations

| Integration | Enables | Without it |
| --- | --- | --- |
| MCP search tools (Ref, Exa, Perplexity) | Richer research during planning stages | Stages and templates all work, with less external context |

## Related

- [Quickstart](./quickstart.md) — your first plan, end to end
- [When to use Toque](./when-to-use.md) — including where it is overkill
