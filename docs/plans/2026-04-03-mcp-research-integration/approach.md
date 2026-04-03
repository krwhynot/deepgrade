# Approach: MCP Research Integration
Date: 2026-04-03

## Scope

### IN
1. New skill: `skills/mcp-research/SKILL.md` — tool selection heuristics knowledge
2. Enhance `commands/plan.md` — Phase 2 Track 3 + Phase 3 confidence brief
3. Enhance `commands/troubleshoot.md` — add Step 0.2 external doc/issue lookup
4. Enhance `skills/documentation/SKILL.md` — external enrichment section
5. Enhance `commands/doc.md` — add MCP tools to allowed-tools
6. Enhance `agents/integration-scanner.md` — API validation against external docs
7. Enhance `agents/dependency-mapper.md` — deprecation checking via docs
8. Extend `commands/readiness-generate.md` — offer research MCP .mcp.json generation
9. Update `METHODOLOGY.md` — keep Track 3 documentation in sync

### OUT
- No new agents (MCP tools augment existing agents)
- No new commands for MCP configuration (readiness-generate handles .mcp.json)
- No Perplexity in troubleshooting (conflicts with plausible hypothesis warning)
- No hard MCP dependencies — plugin must work identically without any MCP servers
- No changes to readiness-scan scoring (Check 5.7 and 8.5 already cover MCP)
- No Codex Challenge changes in this phase (defer to follow-up)

## Options Analysis

### Option A: Full Integration (Recommended)
Add MCP tools to `allowed-tools` frontmatter + prose-conditional instructions in 4 commands and 2 agents. Create new skill for selection heuristics.

| Criterion | Score |
|-----------|-------|
| Implementation ease | 4/5 — mostly prose additions to existing files |
| Timeline | 3/5 — 9 files to modify, testing needed |
| Strategic value | 5/5 — evidence quality improvement across entire plugin |
| Risk profile | LOW — graceful degradation means zero breakage risk |
| Rollback complexity | LOW — revert frontmatter + prose changes |

### Option B: Planning-Only Integration
Only modify `commands/plan.md` and create the skill. Leave other commands/agents untouched.

| Criterion | Score |
|-----------|-------|
| Implementation ease | 5/5 — only 2 files |
| Timeline | 5/5 — under 1 hour |
| Strategic value | 3/5 — only planning benefits, other commands unchanged |
| Risk profile | LOW |
| Rollback complexity | LOW |

### Option C: Skill-Only (Knowledge-Based)
Create `skills/mcp-research/SKILL.md` only. No `allowed-tools` changes. Rely on ambient tool availability.

| Criterion | Score |
|-----------|-------|
| Implementation ease | 5/5 — 1 new file |
| Timeline | 5/5 — under 30 minutes |
| Strategic value | 2/5 — skill loads but can't invoke tools without allowed-tools |
| Risk profile | LOW |
| Rollback complexity | LOW |

### Decision Rationale
**Option A wins.** The marginal effort over Option B is small (7 additional files, mostly frontmatter + prose additions), but the strategic value is significantly higher — troubleshooting, documentation, and audit all benefit from external research. The risk is identical across all options (LOW) because of graceful degradation.

Would revisit Option B if: timeline is extremely compressed or we want to ship incrementally.
Would revisit Option C if: `allowed-tools` behavior with unknown tools turns out to cause errors.

## Approach / Pattern

**Pattern: Additive Enhancement with Graceful Degradation**

Each integration follows the same template:
1. Add MCP tool names to `allowed-tools` (command) or `tools:` (agent) frontmatter
2. Write prose instruction: "IF {tool} is available, use it for {purpose}"
3. Write fallback: "IF not available, {current behavior / skip with tag}"
4. Tag unavailable-tool outputs: `[EXTERNAL RESEARCH UNAVAILABLE]`

This mirrors Pattern A (prose-fallback) found in `agents/security-scanner.md`.

## Top 3 Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Unknown `allowed-tools` entries cause errors | MEDIUM | Test with plan.md first before touching other files |
| Runtime token overhead (3,150 tokens) causes context pressure | LOW | MCP servers are user-installed, not plugin-bundled; document in README |
| MCP tool names don't match server registration | LOW | Verify actual tool names from each MCP server's documentation at build time |

## Constraints

- **Timeline:** No hard deadline — plugin enhancement, not incident response
- **Team:** Solo development (Kyle)
- **Technology:** Must stay within Claude Code plugin architecture (commands/agents/skills)

## Dependencies

| Dependency | Type | Owner |
|-----------|------|-------|
| Ref MCP tool name verification | External, soft | Kyle (check docs) |
| Exa MCP tool name verification | External, soft | Kyle (check docs) |
| Perplexity MCP tool name verification | External, soft | Kyle (check docs) |
| Claude Code `allowed-tools` behavior with absent tools | Internal, soft | Kyle (test empirically) |
