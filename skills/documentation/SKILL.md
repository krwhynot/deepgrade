---
name: documentation
description: (deepgrade) Generate project documentation (ADR, BRD, PRD, README, release notes, changelog, technical spec). Dispatches to the appropriate template based on document type. Also suggests which document to create based on context. Triggers on - create adr, create brd, create prd, create readme, generate documentation, architecture decision, business requirements, product requirements, release notes, changelog, version notes, release summary, prepare release, generate changelog, version history, release documentation, deployment notes, create spec, technical specification, write spec, engineering plan, design doc, RFC, migration plan.
---

# Documentation Generator

Unified entry point for all document generation workflows. Part of the DeepGrade
Developer Toolkit. Works standalone or powered by Phase 2 audit data when available.

## Usage

Parse `$ARGUMENTS` to determine the document type and topic:

- **First word = subcommand:** `adr`, `brd`, `prd`, `readme`, `release-notes`, `spec`
- **Rest = topic/argument** passed to the template

### Routing

| Subcommand | Template | Description |
|------------|----------|-------------|
| `adr` | [resources/adr-template.md](resources/adr-template.md) | Architecture Decision Record |
| `brd` | [resources/brd-template.md](resources/brd-template.md) | Business Requirements Document |
| `prd` | [resources/prd-template.md](resources/prd-template.md) | Product Requirements Document |
| `readme` | [resources/readme-template.md](resources/readme-template.md) | Project README |
| `release-notes` | [resources/release-notes-template.md](resources/release-notes-template.md) | Release Notes / Changelog |
| `spec` | [resources/spec-template.md](resources/spec-template.md) | Technical Specification (extraction, migration, feature, infrastructure) |

### Dispatch Logic

1. If `$ARGUMENTS` starts with a known subcommand, read the corresponding template and execute with the remaining text as the topic (`$1`).

2. If `$ARGUMENTS` is empty, show this menu:
   ```
   Available document types:
     [1] adr <topic>        - Architecture Decision Record
     [2] brd <domain>       - Business Requirements Document
     [3] prd <feature>      - Product Requirements Document
     [4] readme <project>   - Project README
     [5] release-notes <version> - Release Notes / Changelog
     [6] spec <topic>       - Technical Specification / Engineering Plan
   
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
Based on the DeepGrade audit, here are recommended documents to create:

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
  - Recording what changed in a release -> Release Notes

Describe what you need and I'll pick the right format.
```

### DeepGrade Integration

When audit data is available, documentation templates pull from it automatically:

| Template | Uses From Audit |
|----------|----------------|
| ADR | risk-assessment.md findings, integration-scan.md security items |
| BRD | feature-inventory.md domains and feature lists |
| PRD | feature-inventory.md confidence scores, entry points, DB tables |
| README | dependency-map.md project dependencies, risk ratings |
| Spec | risk-assessment.md risk levels, dependency-map.md coupling data |
| Release Notes | git log (no audit dependency) |

This means documents generated AFTER a Phase 2 audit are richer and more accurate
than documents generated from scratch.

### Document Chain Enforcement

After generating any document, check the document chain:

- **PRD created** -> Check if BRD exists for that domain. If not, suggest creating one.
- **BRD created** -> Check if PRDs exist for features in that domain. If not, suggest creating them.
- **ADR created** -> Check if related PRDs reference this decision. If not, suggest linking.
- **Spec created** -> Suggest running `/deepgrade:quick-audit` on it. Check for related ADRs.

This ensures documents don't exist in isolation. Every doc links to related docs.

### Execution

Read the selected `resources/*.md` template file and follow its instructions exactly,
treating the remaining arguments as `$1` (the topic/feature/domain/project name).

### Command Reference Rule

When suggesting next steps or follow-up commands, ONLY suggest commands that exist
as files in the plugin's commands/ directory. The valid commands are:

| Command | Valid Syntax |
|---------|-------------|
| Cleanup docs | `/deepgrade:quick-cleanup [folder]` |
| Create plan | `/deepgrade:quick-plan [objective]` |
| Audit plan | `/deepgrade:quick-audit [file]` |
| Create document | `/deepgrade:doc [adr\|brd\|prd\|readme\|release-notes\|spec] [topic]` |
| Readiness scan | `/deepgrade:readiness-scan` |
| DeepGrade audit | `/deepgrade:codebase-audit` |
| Delta scan | `/deepgrade:codebase-delta` |
| Security scan | `/deepgrade:codebase-security` |
| Characterize | `/deepgrade:codebase-characterize [module]` |
| Setup gates | `/deepgrade:codebase-gates` |
| Generate artifacts | `/deepgrade:readiness-generate` |

NEVER suggest a command that is not in this list. If you are unsure whether a
command exists, use `/deepgrade:help` to check.

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
