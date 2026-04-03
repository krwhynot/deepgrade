# Confidence Brief: MCP Research Integration
Created: 2026-04-03 (Phase 3)
Last reinforced: Pending (Phase 5)

> This document explains WHY the tools, methods, and patterns in this plan
> are industry-proven choices. Each entry defines what it is, who uses it
> at scale, and why it works — then briefly connects it to this plan.

---

## Dependencies & Tools

### Ref Tools MCP {#ref-tools-mcp}
**What it is:** An MCP server that provides AI agents with token-efficient documentation search. Uses session-aware trajectory tracking to extract ~5,000 relevant tokens from documentation pages, preventing context bloat.

**Impact: HIGH** — Rationale: Ref is the primary documentation lookup tool across planning, troubleshooting, and audit. If it doesn't support the frameworks users work with, evidence gathering falls back to generic WebSearch or training data recall.

**Who uses it at scale:**
- **Ref Tools community** — Open-source MCP server with MIT license, used by Claude Code and Cursor users for documentation lookup

**Why it works:** Session-based deduplication prevents repeated results across iterative searches. The 5K token extraction limit respects context budgets while maintaining relevance. The search → read two-step pattern (search docs first, then fetch specific pages) minimizes unnecessary token consumption.

**Reference:** [Ref Tools MCP - GitHub](https://github.com/ref-tools/ref-tools-mcp)

**Connection to this plan:** Primary tool for Phase 2 Track 3 (framework documentation), Phase 3 confidence brief URL verification, troubleshoot Step 0.2 (known bug lookup), and integration scanner API validation.

---

### Exa MCP Server {#exa-mcp}
**What it is:** A neural/semantic web search MCP server that returns clean, ready-to-use content. Includes specialized `get_code_context_exa` for finding code examples from GitHub, Stack Overflow, and technical documentation.

**Impact: HIGH** — Rationale: Exa provides the code example search capability that neither Ref nor Perplexity offers. Without it, code pattern research falls back to generic web search without semantic understanding.

**Who uses it at scale:**
- **Exa Labs** — Commercial search API powering AI agent integrations across Claude, Cursor, and VS Code

**Why it works:** Neural search understands intent rather than matching keywords. The `get_code_context_exa` tool is specifically tuned for programming queries, finding relevant code snippets even when the user describes the problem in natural language rather than using exact API names. Category filtering (GitHub, financial reports, etc.) narrows results without manual domain filtering.

**Reference:** [Exa MCP Documentation](https://exa.ai/docs/reference/exa-mcp)

**Connection to this plan:** Code example search in Phase 2 Track 3, GitHub issue search in troubleshoot Step 0.2, and pattern discovery for documentation enrichment.

---

### Perplexity MCP Server {#perplexity-mcp}
**What it is:** An MCP server providing tiered AI-powered web research through four tools: `perplexity_search` (fast lookup), `perplexity_ask` (conversational, sonar-pro), `perplexity_research` (deep investigation, sonar-deep-research), and `perplexity_reason` (analytical, sonar-reasoning-pro).

**Impact: MEDIUM** — Rationale: Perplexity provides deep research and analytical capabilities that complement Ref and Exa, but the plan can function without it. Ref handles docs, Exa handles code examples. Perplexity adds depth for complex research questions where the first two are insufficient.

**Who uses it at scale:**
- **Perplexity AI** — Commercial AI search platform with official MCP server implementation

**Why it works:** The tiered model approach maps cognitive effort to cost: simple lookups use fast/cheap search, complex questions escalate to deep research. Citation grounding ensures answers are traceable to sources. The 2026 pricing change (citation tokens no longer billed for Sonar/Sonar Pro) makes the lower tiers very cost-effective.

**Reference:** [Perplexity MCP Server Docs](https://docs.perplexity.ai/docs/getting-started/integrations/mcp-server)

**Connection to this plan:** Fallback research tool in Phase 2 Track 3 when Ref + Exa are insufficient. Used for "who uses X at scale" evidence in confidence briefs.

---

## Methods & Patterns

### Graceful Degradation Pattern (Prose-Conditional Fallback) {#graceful-degradation}
**What it is:** A pattern where optional tool integrations include explicit prose instructions for what to do when the tool is not available, ensuring zero-breakage operation regardless of environment configuration.

**Impact: HIGH** — Rationale: This is the core architectural pattern of the entire integration. If it doesn't work reliably, every MCP integration becomes a hard dependency.

**Origin:** Standard resilience pattern in distributed systems. In the DeepGrade context, already implemented in `agents/security-scanner.md` (lines 63-65) for optional vulnerability scanning tools.

**Who uses it at scale:**
- **DeepGrade plugin** — existing pattern in security-scanner agent
- **Feature flag platforms (LaunchDarkly, Flagsmith)** — same principle: if flag service is down, use default value

**Why it works:** By making external tool usage conditional at the prose level (not the code level), the LLM can make runtime decisions about tool availability without programmatic pre-flight checks. The fallback path preserves all existing functionality.

**Reference:** [UNVERIFIED — common pattern, no primary source found]

**Connection to this plan:** Every MCP integration in this plan follows this pattern: "IF tool available → use it; OTHERWISE → current behavior + tag `[EXTERNAL RESEARCH UNAVAILABLE]`"

---

### Tiered Research Escalation {#tiered-escalation}
**What it is:** A search strategy that starts with the cheapest/fastest tool and escalates to more expensive/thorough tools only when needed: Ref (docs) → Exa (code/web) → Perplexity (deep research).

**Impact: MEDIUM** — Rationale: Ordering matters for token budget, but the plan works with any single tool.

**Origin:** General optimization principle. Similar to DNS resolution cascades and CDN fallback chains.

**Why it works:** Ref returns ~5K tokens per query (smallest footprint). Exa returns clean content but at variable length. Perplexity deep research can return thousands of tokens. By starting with Ref, most documentation questions are answered without triggering the more expensive tools.

**Reference:** [UNVERIFIED — optimization principle applied to MCP tool selection]

**Connection to this plan:** Phase 2 Track 3 uses this ordering: "Search Ref first. If insufficient, try Exa. If still insufficient, use Perplexity ask."

---

## Best Practices & Standards

### MCP Tool Search (Context Pollution Prevention) {#mcp-tool-search}
**What it is:** Claude Code's 2026 feature that discovers MCP tools on-demand rather than loading all tool definitions upfront, reducing token overhead by ~95%.

**Impact: MEDIUM** — Rationale: Mitigates the runtime token cost of adding 3 MCP servers. Without Tool Search, 3 servers × 3 tools × 350 tokens = 3,150 tokens persistent overhead. With Tool Search, only the tools actually used in a session are loaded.

**Advocated by:** Anthropic (Claude Code team)

**Industry evidence:** Tool Search reduces context pollution from MCP tool descriptions by approximately 95% compared to clients that load all tool definitions upfront.

**Reference:** [MCP Tool Search - Claude Code](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)

**Connection to this plan:** Ensures that adding MCP tools to `allowed-tools` doesn't bloat context when the tools aren't actually needed in a given session.
