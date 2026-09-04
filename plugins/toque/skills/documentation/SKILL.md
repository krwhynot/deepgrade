---
name: documentation
description: Generate project documentation (ADR, BRD, PRD, README, runbook, release notes, changelog, technical spec). Dispatches to the appropriate template based on document type. Also suggests which document to create based on context. Triggers on - create adr, create brd, create prd, create readme, generate documentation, architecture decision, business requirements, product requirements, release notes, changelog, version notes, release summary, prepare release, generate changelog, version history, release documentation, deployment notes, create spec, technical specification, write spec, engineering plan, design doc, RFC, migration plan, create runbook, deployment runbook, operational procedure, on-call procedure.
---

# Documentation Generator

## Plan awareness

Carried here from the former `doc` command, which this skill replaced in v5.0.0 (F30 —
the command was a 22-line wrapper that re-dispatched to this file, so the two surfaces
could drift and one had to go).

If the request names a plan (`--plan {name}`, or the user says "for plan X"), write
the document to its standard `docs/` location (`docs/adr/`, `docs/prd/`,
`docs/specs/`, …) **and** add a link to it in
`docs/plans/{date}-{name}/manifest.md`. The plan folder is a homebase that indexes
documents; it is not where they live.

With no plan named, use the standard locations only.

## Resolving template paths

Templates live beside this file. Read them via `${CLAUDE_SKILL_DIR}/references/<name>`
— an installed plugin does not sit at a path this file can assume, and a relative
read from the session's working directory resolves into the *user's project*, not
the plugin. The table below uses repo-relative links for human readability; at
runtime, anchor on `${CLAUDE_SKILL_DIR}`.

## Dispatch

Unified entry point for all document generation workflows. Part of the Toque
Developer Toolkit. Works standalone or powered by Phase 2 audit data when available.

## Usage

Parse `$ARGUMENTS` to determine the document type and topic:

- **First word = subcommand:** `adr`, `brd`, `prd`, `readme`, `runbook`, `release-notes`, `spec`
- **Rest = topic/argument** passed to the template

### Routing

| Subcommand | Template | Description |
|------------|----------|-------------|
| `adr` | [references/adr-template.md](references/adr-template.md) | Architecture Decision Record |
| `brd` | [references/brd-template.md](references/brd-template.md) | Business Requirements Document |
| `prd` | [references/prd-template.md](references/prd-template.md) | Product Requirements Document |
| `readme` | [references/readme-template.md](references/readme-template.md) | Project README |
| `runbook` | [references/runbook-template.md](references/runbook-template.md) | Operational runbook (deploy, rotation, backfill, recovery) |
| `release-notes` | [references/release-notes-template.md](references/release-notes-template.md) | Release Notes / Changelog |
| `spec` | [references/spec-template.md](references/spec-template.md) | Technical Specification (extraction, migration, feature, infrastructure) |

### Dispatch Logic

1. If `$ARGUMENTS` starts with a known subcommand, read the corresponding template and execute with the remaining text as the topic. Templates refer to that topic with a literal dollar-one placeholder; substitute the remaining text wherever it appears.

2. If `$ARGUMENTS` is empty, show this menu:
   ```
   Available document types:
     [1] adr <topic>        - Architecture Decision Record
     [2] brd <domain>       - Business Requirements Document
     [3] prd <feature>      - Product Requirements Document
     [4] readme <project>   - Project README
     [5] runbook <task or plan> - Operational Runbook
     [6] release-notes <version> - Release Notes / Changelog
     [7] spec <topic>       - Technical Specification / Engineering Plan
   
   Not sure which one you need? Describe what you're trying to document
   and I'll recommend the right format.
   ```

3. If `$ARGUMENTS` doesn't match a subcommand, analyze intent AND context:

   **Intent-based routing:**
   - Decision/architecture/tradeoff/why-we-chose -> suggest `adr`
   - Business/domain/requirements/stakeholder -> suggest `brd`
   - Feature/spec/user story/acceptance criteria -> suggest `prd`
   - Project/module/overview/setup/getting-started -> suggest `readme`
   - Release/changelog/version/what changed/deploy -> suggest `release-notes`
   - Extract/migrate/refactor/plan/design/RFC/shadow mode -> suggest `spec`

   **Context-based suggestions (smart mode):**
   Check for audit data and suggest documents that are MISSING:

   ```bash
   # Check what docs exist
   ls docs/adr/ docs/brd/ docs/prd/ docs/specs/ 2>/dev/null
   ls docs/audit/risk-assessment.md docs/audit/feature-inventory.md 2>/dev/null
   ```

   If Phase 2 audit data exists, check for document gaps:
   - Features without PRDs -> suggest `prd` for those features
   - Domains without BRDs -> suggest `brd` for those domains
   - Architectural decisions without ADRs -> suggest `adr`
   - Modules without READMEs -> suggest `readme`
   - No specs for high-risk modules -> suggest `spec`

### Smart Suggestions (When User Doesn't Know What to Create)

If the user says something like "I need to document X" or "what document should I
create for Y" or "help me with documentation", analyze their situation:

**After running Phase 2 audit:**
```
Based on the Toque audit, here are recommended documents to create:

HIGH PRIORITY:
  - SPEC for monolith extraction (legacy modules need a refactoring plan)
  - ADR for credential rotation (5 hardcoded credentials found)
  - PRD for [feature with no PRD] (HIGH risk, no documentation)

MEDIUM PRIORITY:
  - BRD for [domain] (12 features, no business requirements doc)
  - README for [project] (HIGH risk module, no README)

LOW PRIORITY:
  - Release notes for latest changes
  - ADR for [technology choice]

Which would you like to create? Or type the number.
```

**Without audit data:**
```
I can help you create documentation. What are you working on?

If you're...
  - Making a big technical decision -> ADR (Architecture Decision Record)
  - Documenting business requirements -> BRD
  - Specifying a feature -> PRD (Product Requirements Document)
  - Planning a migration or extraction -> SPEC (Technical Specification)
  - Documenting a project/module -> README
  - Writing the exact steps for a deploy, rotation, backfill, or recovery -> Runbook
  - Recording what changed in a release -> Release Notes

Describe what you need and I'll pick the right format.
```

### Toque Integration

When audit data is available, documentation templates pull from it automatically:

| Template | Uses From Audit |
|----------|----------------|
| ADR | risk-assessment.md findings, integration-scan.md security items |
| BRD | feature-inventory.md domains and feature lists |
| PRD | feature-inventory.md confidence scores, entry points, DB tables |
| README | dependency-map.md project dependencies, risk ratings |
| Runbook | plan.md ## Verification, deploy scripts and CI config (no audit dependency) |
| Spec | risk-assessment.md risk levels, dependency-map.md coupling data |
| Release Notes | git log (no audit dependency) |

This means documents generated AFTER a Phase 2 audit are richer and more accurate
than documents generated from scratch.

### Document Chain Enforcement

After generating any document, check the document chain:

- **PRD created** -> Check if BRD exists for that domain. If not, suggest creating one.
- **BRD created** -> Check if PRDs exist for features in that domain. If not, suggest creating them.
- **ADR created** -> Check if related PRDs reference this decision. If not, suggest linking.
- **Spec created** -> Suggest running `/toque:quick-audit` on it. Check for related ADRs.
- **Runbook created** -> If plan-linked, check review.md ## Release checklist references it and manifest.md has a row.

This ensures documents don't exist in isolation. Every doc links to related docs.

### Execution

Read the selected `references/*.md` template file and follow its instructions exactly,
treating the remaining arguments as the topic (feature, domain, or project name) wherever the template shows its dollar-one placeholder.

### Command Reference Rule

When suggesting next steps or follow-up commands, ONLY suggest commands that exist
as files in the plugin's commands/ directory. The valid commands are:

| Command | Valid Syntax |
|---------|-------------|
| Cleanup docs | `/toque:quick-cleanup [folder]` |
| Create plan | `/toque:quick-plan [objective]` |
| Audit plan | `/toque:quick-audit [file]` |
| Create document | `/toque:documentation [adr\|brd\|prd\|readme\|runbook\|release-notes\|spec] [topic]` |

NEVER suggest a command that is not in this list. If you are unsure whether a
command exists, use `/toque:help` to check.

Codebase auditing and readiness scanning left Toque in 11.0.0 and are not in
this list on purpose. Never suggest a command to produce that data — whatever
tool a project uses is not this plugin's concern, and a command that does not
resolve is worse than no suggestion. If `docs/audit/` already holds analysis,
use it; if it does not, say so and carry on without it.

## External Enrichment (when MCP search tools available)

When generating documentation, agents can enhance quality by looking up
external sources. This is OPTIONAL — all templates work without MCP tools.

### When to Search
- **Specs/ADRs:** Search ref_search_documentation for framework-specific
  configuration examples and recommended patterns before writing Technical
  Approach sections.
- **ADRs:** Search web_search_exa for real-world architecture examples
  matching the decision context (e.g., "companies using event sourcing
  for order processing") to strengthen Decision Drivers sections.
- **READMEs:** Search ref_search_documentation for the project's primary
  framework documentation to verify setup instructions are current.

### How to Search
- Use ref_search_documentation for official framework/library docs
- Use web_search_exa for real-world examples and patterns
- Always attribute external sources: "[Source: {title}]({url})"
- Tag unverifiable claims: "[UNVERIFIED — based on training data]"

### When NOT to Search
- **Release notes** — content comes from git log, not external sources
- **BRDs** — business requirements come from stakeholders, not web search
- **Changelogs** — content comes from commit history and version tags
