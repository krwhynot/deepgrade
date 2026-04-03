# Codebase Scan: MCP Research Integration
Date: 2026-04-03

## Current Tool Declarations

### Commands (`allowed-tools:` frontmatter)

Every full-featured command uses: `Read, Write, Grep, Glob, Bash, Task`
- `plan-status.md` is the exception: `Read, Grep, Glob, Bash` (no Write, no Task)
- `help.md` has no `allowed-tools` line

**Zero commands currently list any MCP or web search tool in `allowed-tools`.**

### Agents (`tools:` frontmatter)

| Agent | Tools |
|-------|-------|
| integration-scanner | `Read, Grep, Glob` (leanest — no Bash, no Write) |
| doc-auditor | `Read, Grep, Glob` (lean) |
| dependency-mapper | `Read, Grep, Glob, Bash` |
| All others | Various combos of Read, Write, Grep, Glob, Bash |

**Zero agents currently reference any MCP tool.**

## WebSearch/WebFetch References (4 total)

| File | Line | Context |
|------|------|---------|
| commands/plan.md | 303 | `Tools: Read, WebSearch, WebFetch` (Track 3) |
| commands/plan.md | 535 | `URL VERIFICATION: When WebSearch or WebFetch tools are available...` |
| commands/plan.md | 1497 | Error handling: `Web research unavailable | Skip web track, note limitation` |
| METHODOLOGY.md | 309 | Documentation mirror of Track 3 |

## Primary Integration Points

1. **plan.md:301-305** — Track 3 BEST PRACTICES subagent (replace/augment WebSearch/WebFetch)
2. **plan.md:535** — URL VERIFICATION (expand tool condition)
3. **troubleshoot.md:194-203** — Step 0 KB check (add Step 0.2 for external doc lookup)
4. **agents/integration-scanner.md** — After finding API endpoints, validate against external docs
5. **agents/dependency-mapper.md** — After finding packages, check deprecation via docs
6. **commands/doc.md** — Enrich template generation with framework examples
7. **commands/quick-plan.md** — Ground recommendations with best practices lookup
8. **commands/readiness-generate.md** — Offer recommended .mcp.json for research tools
