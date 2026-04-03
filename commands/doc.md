---
description: (deepgrade) Generate any project document (ADR, BRD, PRD, README, release notes, spec). Routes to the appropriate template based on document type. If unsure which format, describe what you need and it will recommend. Pass subcommand and topic.
argument-hint: "[adr|brd|prd|readme|release-notes|spec] [topic] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task, ref_search_documentation, ref_read_url, web_search_exa
---

<plan_awareness>
If $ARGUMENTS contains --plan {name}, write output to standard docs/ locations
(docs/adr/, docs/prd/, docs/specs/) AND update docs/plans/{date}-{name}/manifest.md
with a link to the created document.

If no --plan flag, use default locations (docs/adr/, docs/prd/, etc.).
</plan_awareness>

Route to the documentation skill. Read the SKILL.md at
${CLAUDE_PLUGIN_ROOT}/skills/documentation/SKILL.md
and follow its dispatch logic with $ARGUMENTS as the input.

If $ARGUMENTS is empty, show the document type menu from the skill.
If $ARGUMENTS starts with a known subcommand (adr, brd, prd, readme,
release-notes, spec), dispatch to the matching template.
If $ARGUMENTS doesn't match, analyze intent and suggest the right format.
