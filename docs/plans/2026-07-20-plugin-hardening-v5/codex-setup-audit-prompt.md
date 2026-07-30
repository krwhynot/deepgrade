# Codex audit prompt — Claude Code plugin SETUP conformance

Scope note for this run: **Claude Code plugin setup only.** Not general code review, not
test quality, not documentation prose. One question, below.

---

## Context

You are reviewing a **Claude Code plugin** — a package of Markdown component
definitions plus a few Node scripts. There is nothing sensitive in this repository: no
credentials, no network services, no user data. It is developer tooling, and reviewing
whether its configuration files conform to the vendor's documented format is ordinary
QA work.

Repository root: the current working directory. Plugin version 4.31.0, mid-migration to
5.0.0.

## The single question

**Does this plugin's setup actually load and work as Claude Code documents it?**

Specifically, verify each of these against Claude Code's documented plugin contract, and
tell me where the repository is wrong. For every claim, cite the file and line and say
what the documented requirement is.

1. **`.claude-plugin/plugin.json`** — required and optional fields, correct types. Note
   that it deliberately has NO `hooks` key any more (the hooks moved to `hooks/hooks.json`
   this week). Confirm that is the right shape, and that nothing else was lost in the move.

2. **`.claude-plugin/marketplace.json`** — manifest shape, `source` resolution, whether
   the `plugins[]` entry is well-formed.

3. **`hooks/hooks.json`** — the newly created hook configuration. Check:
   - the top-level wrapping (it is `{"hooks": {<event>: [...]}}`; is that correct, or is
     the outer key wrong?)
   - every event name is a real Claude Code hook event
   - the handler shape: `type`, `command`, `args`, `timeout`
   - the **exec form** used is `"command": "node", "args": ["${CLAUDE_PLUGIN_ROOT}/scripts/..."]`.
     Is `${CLAUDE_PLUGIN_ROOT}` substituted inside `args` entries, or only inside
     `command`? This matters: if it is not substituted in `args`, every handler is broken.
   - `matcher` semantics, including whether `"*"` is valid for events that have no tool
     to match on (SessionStart, Stop, SubagentStop, PreCompact)
   - whether a `timeout` of 5 seconds is expressed in the unit Claude Code expects

4. **Agent frontmatter** (`agents/*.md`, 22 files) — `name`, `description`, `model`,
   `color`, `tools`. Two questions I could not resolve from the docs:
   - is `tools:` as a comma-separated **string** accepted, or must it be a YAML list?
     Both spellings exist in the wild; this repo just normalised everything to the string
     form and I want to know if that was a mistake.
   - is `skills:` a real agent frontmatter key? Seven agents now carry
     `skills: ["deepgrade:self-audit-knowledge"]`. If it is not a real key, say so —
     they also list `Skill` in `tools` as a fallback, but I would rather delete a key
     that does nothing than ship it.

5. **Command frontmatter** (`commands/*.md`, 16 files) — `description`,
   `argument-hint`, `allowed-tools`, `disable-model-invocation`. Is
   `disable-model-invocation` spelled correctly and is `true` the value that stops model
   invocation while leaving the command user-invocable?

6. **Skill frontmatter** (`skills/*/SKILL.md`, 6 files) — `name`, `description`. Is
   `${CLAUDE_SKILL_DIR}` the correct variable for a skill to reference its own bundled
   files, or is it something else?

7. **Namespacing** — the plugin is `deepgrade`. Commands are referenced as
   `/deepgrade:<command>`. One command was just deleted and replaced by a skill, and
   references were repointed to `/deepgrade:documentation`. **Is a plugin skill actually
   addressable that way by a user?** If not, those references are dead and I need to know.

8. **Anything else about the setup that is simply wrong** — a field that does not exist,
   a value in the wrong unit, a path that will not resolve from an installed copy under
   `~/.claude/plugins/`, a component that will silently never load.

## What I do NOT want in this review

- Opinions on code style, test design, documentation wording, or architecture.
- Findings about the Node scripts' internal logic. Their behaviour is separately covered.
- Speculation. If the documented answer is not something you are confident about, say
  "uncertain" and state what would settle it. An uncertain answer marked as such is more
  useful to me than a confident wrong one — I have already shipped two defects this week
  by trusting a confident guess about what a tool checks.

## Output format

A table: `file:line | what the repo does | what the contract requires | verdict`, where
verdict is CONFORMS / VIOLATES / UNCERTAIN. Then a short list of the VIOLATES entries in
priority order. If everything conforms, say so plainly and list what you checked so I can
tell coverage from silence.
