---
name: mcp-research
description: (deepgrade) Knowledge about when and how to use external MCP search tools (Ref, Exa, Perplexity) for documentation lookup, best practices search, code example discovery, and deep research. Auto-invoked when agents need external research, documentation lookup, framework docs, web research, or MCP search guidance. Teaches tool selection heuristics, token budget rules, and graceful degradation patterns.
---

# MCP Research Tool Selection Guide

When external MCP search tools are available, use them to strengthen evidence
quality. When they are NOT available, fall back to built-in tools or skip
external research with an explicit tag.

## Tool Selection Matrix

Pick the RIGHT tool for the task. Do not use all three for the same question.

| Task | Best Tool | Why |
|------|-----------|-----|
| Framework/library API docs | **Ref** (`ref_search_documentation`) | Smart 5K extraction, session dedup, lowest token cost |
| Read a specific doc page | **Ref** (`ref_read_url`) | Markdown conversion, trajectory-aware dropout |
| Code examples & patterns | **Exa** (`get_code_context_exa`) | Neural search across GitHub, SO, technical docs |
| General web search | **Exa** (`web_search_exa`) | Semantic matching, clean ready-to-use content |
| Known bugs / GitHub issues | **Exa** (`web_search_exa`) | Matches error signatures semantically |
| Quick factual lookups | **Perplexity** (`perplexity_search`) | Fast, current, low cost |
| Conversational questions | **Perplexity** (`perplexity_ask`) | sonar-pro model, web-grounded |
| Deep research with citations | **Perplexity** (`perplexity_research`) | sonar-deep-research, comprehensive |
| Analytical comparisons | **Perplexity** (`perplexity_reason`) | sonar-reasoning-pro, step-by-step |

## Tiered Search Strategy

When researching a topic, use tools in this order. **Stop when you have
sufficient evidence.** Do not escalate unnecessarily.

```
1. Ref (docs)        → cheapest, ~5K tokens per query
2. Exa (web/code)    → moderate, variable token count
3. Perplexity (ask)  → moderate, synthesized with citations
4. Perplexity (research) → expensive, 30+ seconds, thorough
5. WebSearch/WebFetch → generic fallback if MCP tools unavailable
```

## Token Budget Rules

Each MCP tool call adds tokens to the session. Be intentional:

- **Ref before Perplexity** for documentation lookups (Ref returns ~5K tokens;
  Perplexity can return much more)
- **Search before fetch** — use `ref_search_documentation` to find the right
  page, then `ref_read_url` to read it. Don't fetch blindly.
- **Exa search before get_contents** — filter results first, fetch content second
- **Perplexity search before research** — use the cheapest tier that answers
  the question. Only escalate to `perplexity_research` for complex topics.
- **Never run all three** for the same question — pick the best fit

## Graceful Degradation Pattern

Every use of MCP tools MUST include a fallback. Use this template:

```
IF {mcp_tool} is available:
  Use it for {specific purpose}.
  Tag results with evidence tier.

OTHERWISE:
  {Fall back to built-in tools / WebSearch / skip with tag}
  Tag: "[EXTERNAL RESEARCH UNAVAILABLE — {reason}]"
```

## Evidence Tier Mapping

When using MCP tools, classify the evidence quality:

| Source | Tier | When to Use |
|--------|------|------------|
| Ref official docs | **TIER A** | Framework/library documentation |
| Ref read of specific doc page | **TIER A** | Verified URL content |
| Exa GitHub issues with resolution | **TIER B** | Community evidence with outcome |
| Exa Stack Overflow (high votes) | **TIER B** | Community-validated answers |
| Perplexity with citations | **TIER B** | Synthesized answer with sources |
| Perplexity without citations | **TIER C** | Flag as "[UNVERIFIED — synthesized without primary source]" |
| No MCP tools available | **TIER C** | Flag as "[UNVERIFIED — based on training data only]" |

## Verified Tool Names (as of 2026-04-03)

These are the tool names as registered by each MCP server. If a tool name
doesn't match, the tool is simply unavailable (graceful degradation applies).

**Ref Tools MCP:**
- `ref_search_documentation` — search docs with a natural language query
- `ref_read_url` — fetch and convert a specific URL to markdown

**Exa MCP:**
- `web_search_exa` — general semantic web search
- `get_code_context_exa` — code-specific search (GitHub, SO, docs)
- `crawling_exa` — full page content retrieval
- `web_search_advanced_exa` — advanced search with filters (optional, must be enabled)

**Perplexity MCP:**
- `perplexity_search` — fast factual lookup
- `perplexity_ask` — conversational Q&A (sonar-pro)
- `perplexity_research` — deep investigation (sonar-deep-research)
- `perplexity_reason` — analytical reasoning (sonar-reasoning-pro)

## When NOT to Use External Search

- **Troubleshooting hypothesis formation** — do NOT use Perplexity in
  troubleshooting. It conflicts with the "plausible hypothesis" warning.
  Only use Ref (official docs) and Exa (exact-match GitHub issues) for
  troubleshooting. External matches inform but never replace reading
  THIS codebase's actual code.
- **Release notes** — content comes from git log, not web search
- **BRDs** — business requirements come from stakeholders, not web search
- **Codebase-internal questions** — use Grep/Glob/Read instead
