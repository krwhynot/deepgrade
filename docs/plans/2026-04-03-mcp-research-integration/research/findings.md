# Research Findings: MCP Research Integration
Date: 2026-04-03

## Summary

Three MCP search tools (Ref, Exa, Perplexity) can be integrated into the DeepGrade plugin as optional enhancements. The plugin's architecture already supports conditional tool usage via prose-fallback patterns. The primary risk is token budget at runtime (3,150 tokens for tool descriptions), but plugin-level overhead stays under 200 tokens.

## Codebase

**What exists:**
- 16 commands, all using `Read, Write, Grep, Glob, Bash, Task` only
- 22 agents, all using built-in tools only
- 5 skills, knowledge-only (no tool declarations)
- 1 existing web search integration: plan.md Track 3 (WebSearch/WebFetch, ambient-optional)
- Budget scanner already measures MCP overhead (Check 8.5: <5 servers, Check 8.1: <10K tokens)

**What we can reuse:**
- Pattern A (prose-fallback) from security-scanner.md — cleanest conditional pattern
- Track 3's "if web search available" conditional — already proven approach
- Readiness-generate's .mcp.json generation capability — already handles database MCP

## Best Practices

**Recommended approach:** Add MCP tool names to `allowed-tools` in target commands + write prose-conditional instructions with explicit fallbacks. Keep MCP servers as user-installed optionals, not plugin requirements.

**Key architecture rule:** Skills teach knowledge (when to use which tool), commands/agents declare and invoke tools.

## Tool-to-Use-Case Mapping

| Use Case | Tool | Why |
|----------|------|-----|
| Framework/library API docs | Ref (`ref_search_documentation`) | Smart 5K extraction, session dedup |
| Specific doc page | Ref (`ref_read_url`) | Markdown conversion, trajectory-aware |
| Code examples/patterns | Exa (`get_code_context_exa`) | Neural search across GitHub/SO/docs |
| General web search | Exa (`web_search_exa`) | Semantic matching, clean content |
| Quick factual lookups | Perplexity (`perplexity_search`) | Fast, current |
| Conversational questions | Perplexity (`perplexity_ask`) | sonar-pro model |
| Deep research with citations | Perplexity (`perplexity_research`) | sonar-deep-research model |
| Analytical comparisons | Perplexity (`perplexity_reason`) | sonar-reasoning-pro model |

## Integration Priority (by impact)

| # | Target | Tools | Impact |
|---|--------|-------|--------|
| 1 | Plan Phase 2 Track 3 + Phase 3 Confidence | Ref + Exa + Perplexity | HIGH — evidence quality drives confidence brief |
| 2 | Troubleshoot Step 0.2 | Ref + Exa | HIGH — known bugs found faster |
| 3 | Documentation enrichment | Ref + Exa | MEDIUM — better templates |
| 4 | Integration scanner validation | Ref | MEDIUM — API deprecation detection |
| 5 | Dependency mapper validation | Ref | MEDIUM — package deprecation |
| 6 | Readiness-generate .mcp.json offer | N/A (generation) | LOW — setup convenience |
| 7 | Codex challenge evidence | Perplexity + Exa | LOW — supporting evidence |

## What We Still Don't Know

| Gap | Blocking? | Mitigation |
|-----|-----------|------------|
| Exact Claude Code behavior for unknown `allowed-tools` | Non-blocking | Test with one command first |
| Runtime MCP tool description token counts | Non-blocking | Measure manually after integration |
| Whether Exa/Perplexity tool names match their MCP server registration | Non-blocking | Check at build time |

## Open Questions Resolved

- ~~Should we create skills/mcp-research/SKILL.md?~~ → YES, for selection heuristics
- ~~What's the tool-to-command mapping?~~ → See priority table above
- ~~How do we handle `allowed-tools` for optional tools?~~ → Add them; silently ignored when absent
- ~~What pattern for conditional usage?~~ → Pattern A (prose-fallback)
