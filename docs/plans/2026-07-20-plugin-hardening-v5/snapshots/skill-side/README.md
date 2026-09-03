# Troubleshooting Skill Bundle

A portable, self-contained troubleshooting skill that enforces the
**Iron Law: no permanent fixes without root-cause investigation first**.
Drop into any project's `.claude/skills/` (or your user-level `~/.claude/skills/`)
to make Claude follow a disciplined 4-phase debugging process when a user
reports a bug.

## What's In This Bundle

```
troubleshooting-skill/
├── SKILL.md            Core skill — Iron Law, 4-phase framework, log template
├── README.md           This file
└── resources/
    ├── methodology.md  Expanded Phase 1–4 detail
    ├── kb-schema.md    Knowledge base entry shape
    └── techniques/     Optional extensions (severity, containment, etc.)
        ├── 01-severity-classification-and-triage.md
        ├── 02-containment-before-root-cause.md
        ├── 03-blast-radius-assessment.md
        ├── 04-observability-first-diagnosis.md
        ├── 05-guardrail-evaluation.md
        ├── 06-structured-postmortem.md
        ├── 07-communication-protocol.md
        ├── 08-smart-correlation-engine.md
        └── 09-incident-timeline-reconstruction.md
```

## Install

Pick a scope:

| Scope | Path | When |
|-------|------|------|
| **Project** | `<project>/.claude/skills/troubleshooting/` | Skill applies only to one project |
| **User** | `~/.claude/skills/troubleshooting/` | Skill applies to every project on this machine |

Copy the **contents** of this bundle (everything inside `troubleshooting-skill/`)
into the target path. The destination should contain `SKILL.md` at its top
level — NOT another `troubleshooting-skill/` folder.

### Example (project scope, POSIX shell)

```
mkdir -p .claude/skills/troubleshooting
cp -r path/to/troubleshooting-skill/* .claude/skills/troubleshooting/
```

### Example (user scope, POSIX shell)

```
mkdir -p ~/.claude/skills/troubleshooting
cp -r path/to/troubleshooting-skill/* ~/.claude/skills/troubleshooting/
```

### Example (Windows PowerShell)

```
New-Item -ItemType Directory -Force .claude/skills/troubleshooting
Copy-Item -Recurse path/to/troubleshooting-skill/* .claude/skills/troubleshooting/
```

Claude Code auto-discovers skills at session start. No further registration
needed.

## Verify

Start Claude Code in any project where the skill is installed. In a fresh
session, say:

> "This is broken — debug it."

You should see Claude invoke the troubleshooting skill (Iron Law message,
4-phase framework reminder) before suggesting any fix.

## Customization Checklist

Most projects can use the bundle as-is. These optional adjustments tune the
skill for project-specific conventions:

### 1. Knowledge Base Location (optional)

By default, SKILL.md says: *"If a knowledge base exists at the project's
standard location, append an entry."* If your project has a fixed KB path,
edit the `## Knowledge Base (Optional)` section in SKILL.md to name it
explicitly:

```markdown
## Knowledge Base

After resolving an issue, append an entry to `docs/troubleshooting/kb.md`
using the schema in resources/kb-schema.md.
```

### 2. Test Runner Command (optional)

Phase 4 references "run the full test suite" abstractly. If your project has
a standard test command, edit the Phase 4 section in `resources/methodology.md`
to name it (e.g., `npm test`, `pytest`, `dotnet test`).

### 3. Bug Categories (optional)

The six bug categories (logic / boundary / error handling / data flow /
integration / timing) work for most projects. If your project has a
domain-specific category that recurs (e.g., "race condition", "permission",
"feature flag"), add it to the table in `resources/methodology.md` Step 1.1.

### 4. Extensions Engagement (optional)

By default, extensions in `resources/techniques/` are opt-in. If your project
is a production service with on-call rotation, you may want SEV1/SEV2 issues
to ALWAYS use techniques 01 (severity) and 02 (containment). Add this to the
top of SKILL.md:

```markdown
For this project: if the user mentions "production", "outage", "SEV1", or
"SEV2", engage techniques 01 (severity classification) and 02 (containment)
before Phase 1.
```

### 5. Remove Unused Extensions (optional)

If your project will never need certain extensions (e.g., no distributed
system, so no need for `04-observability-first-diagnosis.md`), delete those
files from `resources/techniques/` and remove the corresponding bullet from
SKILL.md's "Optional Extensions" list.

## What This Bundle Does NOT Include

These are deliberate omissions — add them yourself if needed:

- **Plan / project integration.** No auto-detection of project plans, status
  files, or active iterations.
- **Multi-agent orchestration.** No automatic spawning of specialist
  subagents. Single-agent debugging only.
- **Communication channels.** No Slack/PagerDuty/email integration. The
  communication protocol extension (technique 07) describes WHAT to send,
  not HOW.
- **Automatic KB persistence.** The skill prompts you to log; it doesn't
  silently write files.

## Differentiating From Other Debugging Skills

If you already have a generic `diagnose` or `debug` skill in your user-level
skills directory, this bundle's SKILL.md description leads on **Iron Law /
evidence-based / no-fix-without-root-cause** so the two skills do not collide
on identical triggers. Claude will pick whichever description best matches
the user's phrasing.

If you want this skill to take precedence, rename your existing skill or
narrow its trigger phrasing in its description field.

## Versioning

This bundle is a snapshot. There is no auto-update mechanism. To pull in
updates, re-copy the latest bundle over your installed location.

## Provenance

Distilled from the 4-phase debugging framework in the Toque plugin
(github.com/krwhynot/toque), with plugin-specific couplings removed
for portability.
