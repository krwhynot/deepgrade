# Brainstorm: MCP Research Integration
Date: 2026-04-03

## Problem Statement

The DeepGrade plugin currently relies exclusively on Claude Code's built-in tools (Read, Write, Grep, Glob, Bash, Task). The only external search integration is in `/deepgrade:plan` Phase 2 Track 3, which conditionally uses generic `WebSearch` and `WebFetch` — tools that lack specialization for documentation lookup, semantic code search, or grounded research.

Three specialized MCP search tools exist that would significantly improve evidence quality:
- **Ref** — Documentation search with smart 5K token extraction and session deduplication
- **Exa** — Neural semantic web/code search (GitHub, SO, docs) with category filtering
- **Perplexity** — Tiered research (search → ask → research → reason) with citation grounding

Without these, the plugin's evidence gathering is limited to what's in the codebase and the LLM's training data — creating confidence brief entries that may be TIER C (unverified training data recall) when TIER A/B sources are available.

## Who Is Affected

- **Plan authors** — confidence briefs lack verifiable external evidence
- **Troubleshooters** — can't search framework docs or GitHub issues for known bugs
- **Audit consumers** — integration scanner can't validate API versions against external docs
- **Doc generators** — templates lack real-world examples from framework documentation

## Why Now

- All three MCP tools now have stable, well-documented MCP server implementations
- The plugin already has the architectural pattern for conditional tool usage (Phase 2 Track 3)
- The confidence brief (Phase 3/5) explicitly requires TIER A/B sources but has no automated way to find them
- Budget scanner (Check 8.5) already measures MCP overhead, so we can verify we stay within limits

## What Does Success Look Like

1. Planning: Phase 2 Track 3 uses Ref → Exa → Perplexity (tiered, stop when sufficient)
2. Troubleshooting: Step 1b searches framework docs (Ref) and GitHub issues (Exa) for known bugs
3. Documentation: Templates enriched with framework-specific examples from Ref
4. Audit: Integration scanner validates APIs against external docs via Ref
5. All integrations degrade gracefully — plugin works identically without any MCP servers
6. Total additional persistent context < 1,000 tokens (within budget scanner safe zone)

## Non-Goals

- Making any MCP server a hard requirement for the plugin
- Creating a new command dedicated to MCP configuration (readiness-generate already handles .mcp.json)
- Adding new agents — existing agents gain new optional tool capabilities
- Integrating tools beyond Ref, Exa, and Perplexity in this plan

## Open Questions

1. ~~What problem are we solving?~~ → Answered above
2. Should we create a new skill (`skills/mcp-research/SKILL.md`) to teach tool selection heuristics? → Research phase
3. What's the right tool-to-command mapping? → Research phase
4. How do we handle `allowed-tools` frontmatter for tools that may not exist? → Research phase (likely: Claude Code ignores unknown tool names)

## Ownership

- Plan owner: Kyle
- Tech reviewer: TBD
- Business approver: TBD
