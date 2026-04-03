# Best Practices: MCP Tool Integration
Date: 2026-04-03

## Key Findings

### 1. Unknown `allowed-tools` Entries → Silent Ignore
Claude Code treats `allowed-tools` as a whitelist. If a tool name is listed but the MCP server isn't connected, the tool simply doesn't appear in the available set. No error. This means we can safely add MCP tool names to `allowed-tools` without breaking anything when servers aren't present.

**Confidence: MEDIUM** — Inferred from architecture; not explicitly documented in plugin.

### 2. "If web search available" = Prose-Conditional Only
In plan.md, the phrase "if web search available" at line 301 is a prose instruction to the LLM, not a programmatic check. WebSearch and WebFetch are NOT listed in `allowed-tools` — they work only if ambient in the session. The detection mechanism is: "try the tool, observe whether it works."

### 3. Three Conditional Tool Patterns Exist

| Pattern | Example | How It Works |
|---------|---------|-------------|
| **A. Prose-fallback** | security-scanner.md | Lists tool in `tools:`, writes "if not available, grep instead" |
| **B. Ambient-optional** | plan.md Track 3 | Body says "if available" but tool not in `allowed-tools` |
| **C. Hard-dependency** | Most commands | Lists tools that always exist (Read, Write, etc.) |

**Pattern A is recommended** for MCP integration — explicit, with readable audit trail.

### 4. Token Overhead

| Source | Tokens Added |
|--------|-------------|
| `allowed-tools` entries (6 names × 3-4 commands) | ~90-180 tokens total |
| `.mcp.json` config (3 servers) | ~50-100 tokens (measured by Check 8.1) |
| Runtime tool descriptions (3 servers × 3 tools × 350 tokens) | ~3,150 tokens (NOT measured by scanner) |

The budget scanner (Check 8.1) only measures `.mcp.json` file size, not runtime tool description injection. The brainstorm's "< 1,000 tokens" target applies to plugin-level overhead only — the 3,150 runtime tokens are a user-level cost of connecting MCP servers.

### 5. Budget Scanner Thresholds

- **Check 8.5**: Under 5 MCP servers = PASS. Adding 3 servers → 3 total. Safe.
- **Check 8.1**: Under 10,000 persistent tokens = PASS. Plugin overhead stays ~200 tokens. Safe.

### 6. Skills Cannot Reference Tools
Skills are knowledge-only (name + description frontmatter). No `tools:` field. MCP tool calls must live in commands/agents. A new `skills/mcp-research/SKILL.md` can teach selection heuristics as knowledge, but the actual invocations happen in command bodies.

## Recommended Integration Pattern

1. Add MCP tool names to `allowed-tools` in commands that may use them
2. Write prose instructions using Pattern A: "Use X if available. If not, fall back to Y. If neither, skip."
3. Limit `skills/mcp-research/SKILL.md` to knowledge (tool selection heuristics)
4. Keep MCP servers out of plugin's `.mcp.json` — document as user-installed optionals
5. Verify MCP tool description lengths manually (scanner doesn't catch runtime cost)
