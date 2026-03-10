# Contributing to DeepGrade

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/deepgrade.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make changes
5. Test with Claude Code: `/plugin install deepgrade --scope user`
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
3. Reference from a command using `Task` tool

## Modifying Hooks

Hooks are inline in `.claude-plugin/plugin.json`. Each hook uses:
- jq for JSON parsing (primary)
- grep+sed as fallback (when jq unavailable)
- Windows PATH preamble for jq discovery

When editing hooks:
- Test with AND without jq installed
- Security guards must never fail-open
- Stop hooks must use exit 0 (never exit 2, causes infinite loop)

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
