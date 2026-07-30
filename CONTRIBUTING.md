# Contributing to DeepGrade

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/deepgrade.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make changes
5. Test with Claude Code: `claude --plugin-dir /path/to/deepgrade` (live-edit: your working tree is read
   directly, so changes take effect on the next session). To test the *installed* path instead:
   `/plugin install deepgrade@deepgrade-marketplace --scope user`
6. Submit a pull request

## Plugin Structure

```
.claude-plugin/plugin.json    # Plugin manifest (name, version, hooks)
commands/                     # Slash commands (auto-discovered .md files)
agents/                       # Agent definitions (auto-discovered .md files)
skills/                       # Skills with SKILL.md files
scripts/                      # Reference scripts (not used by hooks at runtime)
```

## Adding a Command

1. Create `commands/your-command.md`
2. Add YAML frontmatter with `description`, `argument-hint`, `allowed-tools`
3. Write the command workflow in markdown
4. Test: `/deepgrade:your-command`

## Adding an Agent

1. Create `agents/your-agent.md`
2. Follow the existing agent pattern (role, context, instructions)
3. Set `name:` to match the filename, and update every caller in the same commit
4. `tools:` is a closed allowlist — anything absent is unavailable to the
   subagent. If the body tells the agent to write a file, `Write` must be listed;
   if it runs shell pipelines, `Bash`; if it spawns subagents, `Agent`; if it
   references a knowledge skill, `Skill`.
5. Reference from a command using `Task` tool

## MCP Tool Names

<!-- CANONICAL-MCP-CONVENTION -->
MCP tools register under server-qualified names — `mcp__<server>__<tool>`, or
`mcp__plugin_<plugin>_<server>__<tool>` for plugin-bundled servers. The
`<server>` segment is chosen by the installing user, so this plugin never
hardcodes an MCP identifier in `tools:` or `allowed-tools:`. Determine
availability by matching the **tool-name suffix** against the connected tool
list, never by bare-name equality.
<!-- /CANONICAL-MCP-CONVENTION -->

Bare names such as `ref_search_documentation` or `web_search_exa` in a `tools:`
or `allowed-tools:` list resolve to nothing. In `allowed-tools:` they are inert
no-ops; in an agent's `tools:` they silently withhold access the agent was meant
to have. `claude plugin validate --strict` does not catch either case — it reads
`plugin.json`, `marketplace.json` and `hooks/hooks.json`, but never agent, command
or skill frontmatter — so `tests/layer1-config-wiring.sh` guards this instead.
The boundary is declared JSON config versus markdown frontmatter, not "manifests
versus components": a broken `hooks/hooks.json` fails validation, while an agent
file missing its `name:` passes clean.

The same rule applies to **skill** names, which are not MCP tools but fail the
same way: plugin skills address as `plugin:skill`, so an agent that says
"reference the `self-audit-knowledge` skill" is naming something unresolvable.
Write `deepgrade:self-audit-knowledge`. Nothing in the toolchain catches an
unqualified skill reference either.

The block above is byte-identical to the one in `skills/mcp-research/SKILL.md`
and a test asserts they stay that way. Edit both or neither.

## Modifying Hooks

Hooks are declared in `hooks/hooks.json` and implemented as one Node script per
handler under `scripts/`. Requires Node.js 18+.

**Never add a `hooks` key back to `.claude-plugin/plugin.json`.** With both a
`hooks/` folder and a manifest `hooks` key present, Claude Code silently ignores
the **folder** — so an inline key does not merely duplicate config, it disables
every shipped handler while looking correct. `layer1` asserts the key's absence.

Each handler:
- parses stdin with `JSON.parse` and reads the **named** field it needs
- splits commands into shell words before matching, so quoted text is data
  (`git commit -m "no git push --force"` must be allowed; `git push "--force"`
  must not)
- emits JSON on exit 0 — **never stderr on exit 0**, which is not surfaced
- denies with exit 2, asks with `permissionDecision: "ask"` at exit 0

When editing hooks:
- add the case to `tests/fixtures/hook-corpus.json` first; it is the acceptance
  authority, and a change that fails a row fails regardless of how it is written
- security guards must never fail open; informational hooks must never fail closed
- Stop hooks must use exit 0 (never exit 2, causes an infinite loop)
- every file in `scripts/` must be referenced by `hooks/hooks.json`, and every
  reference must resolve — `layer1` sweeps both directions

## Versioning

Follow semantic versioning (MAJOR.MINOR.PATCH):
- PATCH: Bug fixes, hook improvements
- MINOR: New commands, agents, or hooks
- MAJOR: Breaking changes to command interfaces or output locations

## Code Style

- Commands and agents: Markdown with XML sections
- Hook commands: Inline bash with jq + grep/sed fallback
- File paths: Forward slashes only (even for Windows patterns)
- JSON: 2-space indent

## Testing

Before submitting a PR:
1. Verify all hooks work: Run the test prompt from the repo
2. Check JSON validity: `python3 -c "import json; json.load(open('.claude-plugin/plugin.json'))"`
3. Verify no `hooks/hooks.json` exists (causes duplicate loading)
4. Confirm no `CLAUDE_PLUGIN_ROOT` references in hooks (known bug #24529)
