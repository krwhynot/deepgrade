# Contributing to DeepGrade

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/deepgrade.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make changes
5. Test with Claude Code: `claude --plugin-dir /path/to/deepgrade/plugins/<plugin>` (live-edit: your
   working tree is read directly, so changes take effect on the next session). To test the *installed*
   path instead: `/plugin install <plugin>@deepgrade-marketplace --scope user`
6. Run the suite: `bash tests/run-all.sh` (all layers must pass)
7. Submit a pull request

## Repository Structure

This is a monorepo of four plugins with **lockstep versions** — every manifest
carries the same version and `.github/release.sh` bumps them together.

```
.claude-plugin/marketplace.json    # Four catalog entries, one shared ref+SHA pin
plugins/deepgrade/                 # Planning core (9 commands, 2 agents, 3 skills, 3 hooks)
plugins/deepgrade-readiness/       # Readiness scanners (2 commands, 10 agents, 1 skill)
plugins/deepgrade-audit/           # Audit team (5 commands, 10 agents, 3 skills)
plugins/deepgrade-guard/           # Safety hooks only (5 handlers, nothing else)
tests/                             # One suite for the whole monorepo
```

Each plugin directory holds its own `.claude-plugin/plugin.json`, `README.md`,
`GUIDE.md`, and its `commands/`, `agents/`, `skills/`, `hooks/`, `scripts/` as
applicable. `deepgrade-readiness` and `deepgrade-audit` ship ZERO hooks and
ZERO scripts by design — layer 1 enforces that partition.

## Adding a Command

1. Pick the plugin it belongs to and create `plugins/<plugin>/commands/your-command.md`
2. Add YAML frontmatter with `description`, `argument-hint`, `allowed-tools`
3. Write the command workflow in markdown
4. Test: `/<plugin>:your-command` — the namespace is the plugin name

## Adding an Agent

1. Create `plugins/<plugin>/agents/your-agent.md`
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
Qualify with the agent's OWN plugin namespace — `deepgrade:self-audit-knowledge`
in the planning plugin, `deepgrade-audit:self-audit-knowledge` in the audit
plugin (which ships a byte-identical mirror; layer 1 keeps the two copies
identical — edit both or neither). Nothing in the toolchain catches an
unqualified skill reference either.

The block above is byte-identical to the one in `skills/mcp-research/SKILL.md`
and a test asserts they stay that way. Edit both or neither.

## Modifying Hooks

Hooks are declared per plugin — `plugins/deepgrade-guard/hooks/hooks.json` for
the safety rails (PreToolUse, PostToolUse, Stop) and
`plugins/deepgrade/hooks/hooks.json` for the plan-context handlers
(SessionStart, SubagentStop, PreCompact) — and implemented as one Node script
per handler under that plugin's `scripts/`. Requires Node.js 18+. The complete
TMPDIR marker bus (writers and readers) ships inside deepgrade-guard; do not
split it.

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
- every file in a plugin's `scripts/` must be referenced by that plugin's
  `hooks/hooks.json` (or invoked as `node .../scripts/NAME` from its commands),
  and every reference must resolve — `layer1` sweeps both directions

## Versioning

Versions are **lockstep across all four plugins**: one release bumps every
manifest, the four catalog entries stay on a single tag+SHA, and
`.github/release.sh` is the only supported way to cut a release. Follow
semantic versioning (MAJOR.MINOR.PATCH):
- PATCH: Bug fixes, hook improvements
- MINOR: New commands, agents, or hooks
- MAJOR: Breaking changes to command interfaces or output locations

## Code Style

- Commands and agents: Markdown with XML sections
- Hook handlers: one Node script per handler, JSON.parse on stdin
- File paths: Forward slashes only (even for Windows patterns)
- JSON: 2-space indent

## Testing

Before submitting a PR:
1. `bash tests/run-all.sh` — all layers must pass; layer 1 covers every plugin
   directory plus the repo-wide sweeps
2. `claude plugin validate . --strict` and `claude plugin validate plugins/<plugin> --strict`
   (schema only — it never reads agent, command, or skill frontmatter)
3. For hook changes, add the case to `tests/fixtures/hook-corpus.json` FIRST
