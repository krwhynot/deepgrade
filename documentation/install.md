# Install

Every install path for the three Toque plugins, what each one needs, and how to
tell whether it worked.

## Prerequisites

| Requirement | Needed by | Check |
| --- | --- | --- |
| Claude Code | all three plugins | `claude --version` |
| Node.js 18+ | `toque` only (hooks and the design-gate tools) | `node --version` |

`toque-readiness` and `toque-audit` need nothing beyond Claude Code — they have
no hooks and no scripts, and act only when you invoke a command.

Node is the same runtime Claude Code itself requires, so in practice if Claude
Code runs, `toque` runs. See [What happens without
Node](#what-happens-without-node) if you are not sure.

## Add the marketplace

Run this in a terminal, **not** inside a Claude Code session:

```bash
claude plugin marketplace add krwhynot/toque
```

This registers the catalog. It installs nothing on its own.

## Install the plugins

Install any subset — the three are independent at install time even though they
share a version.

```bash
claude plugin install toque@toque-marketplace --scope user
claude plugin install toque-readiness@toque-marketplace --scope user
claude plugin install toque-audit@toque-marketplace --scope user
```

Not sure which you want? [Choosing a plugin](./choosing-a-plugin.md) is a
one-page decision table.

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

`/toque:help` ships with the `toque` planning plugin and prints the full toolkit
map, including commands belonging to the sibling plugins — so it doubles as a
check that the other two registered.

If you installed only `toque-readiness` or only `toque-audit`, there is no
`help` command. Verify those by running their scan directly:

```
/toque-readiness:readiness-scan
/toque-audit:codebase-audit
```

## Updating

The three plugins share one version and one release. Update them together:

```bash
claude plugin update toque@toque-marketplace
claude plugin update toque-readiness@toque-marketplace
claude plugin update toque-audit@toque-marketplace
```

The catalog pins all three entries to a single tag and commit SHA, so a
partially updated install is a supported state but not an intended one — the
plugins are documented and tested as a set.

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

`toque-readiness` and `toque-audit` are unaffected.

## Optional integrations

| Integration | Enables | Without it |
| --- | --- | --- |
| MCP search tools (Ref, Exa, Perplexity) | Richer research during planning stages | Stages and templates all work, with less external context |

## Related

- [Quickstart](./quickstart.md) — your first scan, end to end
- [Choosing a plugin](./choosing-a-plugin.md) — which of the three you need
