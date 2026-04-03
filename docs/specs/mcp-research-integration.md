# Spec: MCP Research Integration
Date: 2026-04-03
Plan: docs/plans/2026-04-03-mcp-research-integration/

## Leadership Summary

Integrate three specialized MCP search tools (Ref, Exa, Perplexity) into the DeepGrade plugin as optional enhancements. Every integration degrades gracefully — the plugin works identically without any MCP servers connected. The integration improves evidence quality in planning, troubleshooting, documentation, and audit workflows.

**Timeline:** 3 phases over 1-2 sessions
**Risk:** LOW — all changes are additive, no existing behavior modified
**Go/No-Go:** Test `allowed-tools` behavior with absent tools on first ticket before proceeding

## Phase 1: Foundation (No dependencies)

### MCP-001: Create `skills/mcp-research/SKILL.md`
**Risk:** LOW
**Files:** `skills/mcp-research/SKILL.md` (NEW)
**Acceptance Criteria:**
- [ ] Skill has proper frontmatter (name, description with trigger words)
- [ ] Contains tool selection matrix (Ref vs Exa vs Perplexity, when to use each)
- [ ] Contains token budget rules (Ref first, escalate to Perplexity last)
- [ ] Contains graceful degradation template (IF available / OTHERWISE pattern)
- [ ] Contains evidence tier mapping (Ref = Tier A, Exa/Perplexity with citations = Tier B)
- [ ] Trigger words include: "external research", "documentation lookup", "best practices search", "framework docs", "MCP search", "web research"
**Testing:** Characterization — verify skill auto-invokes when planning context includes trigger words
**Rollback:** Delete file

### MCP-002: Verify `allowed-tools` behavior with absent tools
**Risk:** MEDIUM (assumption verification)
**Files:** `commands/plan.md` (EDIT — frontmatter only)
**Acceptance Criteria:**
- [ ] Add one MCP tool name to plan.md `allowed-tools` (e.g., `ref_search_documentation`)
- [ ] Run `/deepgrade:plan test` WITHOUT Ref MCP connected
- [ ] Verify: no error, plan proceeds normally, Track 3 skips gracefully
- [ ] If verified: proceed with remaining tickets. If fails: fall back to Option C (ambient-only)
**Testing:** Manual — empirical test of Claude Code behavior
**Rollback:** Remove added tool name from frontmatter

---

## Phase 2: Command & Agent Integration (Depends on MCP-002 verification)

### MCP-003: Enhance `commands/plan.md` — Track 3 + Confidence Brief
**Risk:** LOW
**Files:** `commands/plan.md` (EDIT)
**Changes:**
1. **Line 3 (frontmatter):** Add MCP tools to `allowed-tools`:
   ```
   allowed-tools: Read, Write, Grep, Glob, Bash, Task, ref_search_documentation, ref_read_url, web_search_exa, get_code_context_exa, perplexity_search, perplexity_ask
   ```
2. **Lines 301-305 (Track 3):** Replace generic WebSearch/WebFetch with tiered MCP strategy:
   ```
   TRACK 3 - BEST PRACTICES (Subagent: Sonnet, if external search tools available):
   Objective: Find how others solved similar problems.
   Tools: Read, ref_search_documentation, ref_read_url, web_search_exa, get_code_context_exa, perplexity_ask, WebSearch, WebFetch
   Output: docs/plans/{date}-{name}/research/best-practices.md
   
   Search strategy (use in order, stop when sufficient):
   1. Ref: Search framework/library docs for the specific technologies in scope
   2. Exa: Search for code examples of the pattern being considered
   3. Perplexity ask: If above insufficient, ask a targeted research question
   4. WebSearch/WebFetch: Fallback if MCP tools not available
   
   If NO external search tools are available:
     Fall back to codebase-only research using built-in tools.
     Tag in findings.md: "[EXTERNAL RESEARCH UNAVAILABLE — findings based on codebase and training data only]"
   ```
3. **Lines 535-538 (URL verification):** Expand tool condition:
   ```
   URL VERIFICATION: When ref_read_url, WebSearch, WebFetch, or web_search_exa
   tools are available, verify that reference URLs for HIGH-impact entries are
   reachable before writing them.
   - Prefer ref_read_url for documentation URLs (returns clean markdown)
   - Use web_search_exa for general web URLs
   - Fall back to WebFetch if MCP tools unavailable
   ```
**Acceptance Criteria:**
- [ ] `allowed-tools` includes all 6 MCP tool names
- [ ] Track 3 uses tiered search strategy (Ref → Exa → Perplexity → WebSearch)
- [ ] URL verification references MCP tools alongside WebSearch/WebFetch
- [ ] Fallback behavior explicitly documented for no-MCP case
- [ ] Error handling row (line 1497) updated to enumerate tool names
**Testing:** Manual — run `/deepgrade:plan test-mcp from "idea: add caching"` with and without MCP servers
**Rollback:** Revert plan.md to previous version

### MCP-004: Enhance `commands/troubleshoot.md` — Step 0.2
**Risk:** LOW
**Files:** `commands/troubleshoot.md` (EDIT)
**Changes:**
1. **Line 3 (frontmatter):** Add Ref + Exa to `allowed-tools`:
   ```
   allowed-tools: Read, Write, Grep, Glob, Bash, Task, ref_search_documentation, ref_read_url, web_search_exa, get_code_context_exa
   ```
   (No Perplexity — conflicts with plausible hypothesis warning)
2. **After line ~203 (after Step 0 KB check, before Phase 1):** Insert Step 0.2:
   ```
   ### Step 0.2: External Context (if MCP search tools available)
   
   After checking the local knowledge base, search external sources for known issues:
   
   IF ref_search_documentation is available:
     Search for the error message or symptom in the framework's official docs.
     Example: ref_search_documentation("NullReferenceException in ASP.NET middleware pipeline")
   
   IF web_search_exa or get_code_context_exa is available:
     Search for the exact error message on GitHub issues and Stack Overflow.
     Example: web_search_exa("{exact error message}")
   
   Mark external findings with evidence tier:
     - Framework docs match: "A-HIGH: confirmed in {framework} docs v{version}"
     - GitHub issue match: "B-MEDIUM: matches GitHub issue #{number}, {status}"
     - SO answer match: "B-MEDIUM: matches SO answer with {votes} votes"
   
   IMPORTANT: External matches inform hypothesis formation but do NOT replace
   reading THIS codebase's actual code. Always verify external findings against
   the local implementation before forming a hypothesis.
   
   IF no MCP search tools available:
     Skip this step. Proceed to Phase 1 with codebase-only investigation.
   ```
**Acceptance Criteria:**
- [ ] `allowed-tools` includes Ref and Exa tool names (NOT Perplexity)
- [ ] Step 0.2 is positioned AFTER local KB check, BEFORE Phase 1
- [ ] External findings tagged with evidence tiers
- [ ] Warning reinforces "verify against local code" principle
- [ ] Graceful skip when no MCP tools available
**Testing:** Manual — run `/deepgrade:troubleshoot "test error"` with and without MCP
**Rollback:** Revert troubleshoot.md

### MCP-005: Enhance `skills/documentation/SKILL.md` + `commands/doc.md`
**Risk:** LOW
**Files:** `skills/documentation/SKILL.md` (EDIT), `commands/doc.md` (EDIT)
**Changes:**
1. **doc.md frontmatter:** Add `ref_search_documentation, ref_read_url, web_search_exa` to `allowed-tools`
2. **SKILL.md:** Add section after existing content:
   ```
   ## External Enrichment (when MCP search tools available)
   
   When generating documentation, agents can enhance quality by looking up
   external sources. This is OPTIONAL — all templates work without MCP tools.
   
   ### When to Search
   - **Specs/ADRs:** Search Ref for framework-specific configuration examples
     and recommended patterns before writing Technical Approach sections
   - **ADRs:** Search Exa for real-world architecture examples matching the
     decision context (e.g., "companies using event sourcing for order processing")
   - **READMEs:** Search Ref for the project's primary framework documentation
     to verify setup instructions are current
   
   ### How to Search
   - Use ref_search_documentation for official framework/library docs
   - Use web_search_exa for real-world examples and patterns
   - Always attribute external sources: "[Source: {title}]({url})"
   - Tag unverifiable claims: "[UNVERIFIED — based on training data]"
   
   ### When NOT to Search
   - Release notes (content comes from git log, not external sources)
   - BRDs (business requirements come from stakeholders, not web search)
   ```
**Acceptance Criteria:**
- [ ] doc.md `allowed-tools` includes Ref and Exa tool names
- [ ] SKILL.md has External Enrichment section with when/how/when-not guidance
- [ ] Attribution format specified
- [ ] Release notes and BRDs explicitly excluded from external search
**Testing:** Manual — run `/deepgrade:doc adr test-topic` with Ref connected
**Rollback:** Revert both files

### MCP-006: Enhance `agents/integration-scanner.md`
**Risk:** LOW
**Files:** `agents/integration-scanner.md` (EDIT)
**Changes:**
1. **Frontmatter:** Add Ref tools: `tools: Read, Grep, Glob, ref_search_documentation, ref_read_url`
2. **After main scanning section:** Add:
   ```
   ## External API Validation (if ref_search_documentation available)
   
   After identifying integration touchpoints, validate key integrations:
   
   For each payment processor, auth provider, or major API found:
   1. Search official docs for the API version detected in codebase
   2. Check for deprecation notices or breaking changes
   3. Verify authentication patterns match vendor recommendations
   
   Tag findings:
   - [API-CURRENT] — confirmed current via official docs
   - [API-DEPRECATED] — deprecation notice found (include migration URL)
   - [API-UNKNOWN] — could not verify (no MCP tools or no docs found)
   
   If ref_search_documentation is not available:
     Skip external validation. Tag all integrations as [API-UNKNOWN].
   ```
**Acceptance Criteria:**
- [ ] `tools:` includes `ref_search_documentation, ref_read_url`
- [ ] External validation runs after main scan
- [ ] Three tag levels: CURRENT, DEPRECATED, UNKNOWN
- [ ] Graceful skip with UNKNOWN tags when no Ref
**Testing:** Run `/deepgrade:codebase-audit` on a project with known API integrations
**Rollback:** Revert integration-scanner.md

### MCP-007: Enhance `agents/dependency-mapper.md`
**Risk:** LOW
**Files:** `agents/dependency-mapper.md` (EDIT)
**Changes:**
1. **Frontmatter:** Add Ref tools: `tools: Read, Grep, Glob, Bash, ref_search_documentation, ref_read_url`
2. **After dependency mapping section:** Add:
   ```
   ## Deprecation Check (if ref_search_documentation available)
   
   For packages flagged as potentially outdated (major version behind latest):
   1. Search official docs for deprecation notices or migration guides
   2. Check for end-of-life dates
   
   Add to dependency table:
   - [DEPRECATED — migration guide: {url}] if deprecation found
   - [EOL — end of life {date}] if end of life found
   - [VERSION-CHECK-UNAVAILABLE] if no MCP tools available
   
   If ref_search_documentation is not available:
     Skip deprecation check. Note: "Deprecation check skipped (no external docs tool)"
   ```
**Acceptance Criteria:**
- [ ] `tools:` includes `ref_search_documentation, ref_read_url`
- [ ] Deprecation check runs after main dependency mapping
- [ ] Tags for DEPRECATED, EOL, and VERSION-CHECK-UNAVAILABLE
- [ ] Graceful skip when no Ref
**Testing:** Run `/deepgrade:codebase-audit` on a project with outdated packages
**Rollback:** Revert dependency-mapper.md

---

## Phase 3: Documentation & Readiness (No dependencies on Phase 2)

### MCP-008: Extend `commands/readiness-generate.md`
**Risk:** LOW
**Files:** `commands/readiness-generate.md` (EDIT)
**Changes:** Add a new generation offer for research MCP server configuration:
```
### Check 5.7 Remediation: Research MCP Servers

When no MCP servers are configured (Check 5.7 fails), offer to generate
a recommended .mcp.json with research tools:

All stacks:
  - Ref (documentation search — always useful)

Web/frontend stacks (detected by package.json with React/Vue/Angular):
  - Exa (code context search — GitHub/SO examples)

Enterprise/complex stacks (detected by multiple services or migration context):
  - Perplexity (deep research with citations)

Respect Check 8.5: recommend at most 2 research servers.
If database MCP already exists in .mcp.json, recommend at most 1 research server.

Template:
{
  "mcpServers": {
    "ref": {
      "type": "http",
      "url": "https://api.ref.tools/mcp?apiKey=YOUR_API_KEY"
    }
  }
}
```
**Acceptance Criteria:**
- [ ] Generation offer appears when Check 5.7 fails
- [ ] Stack detection influences which servers are recommended
- [ ] Budget-aware: respects Check 8.5 (<5 servers)
- [ ] Template uses correct MCP server URLs
**Testing:** Run `/deepgrade:readiness-generate 5.7` on a project with no .mcp.json
**Rollback:** Revert readiness-generate.md

### MCP-009: Update `METHODOLOGY.md`
**Risk:** LOW
**Files:** `METHODOLOGY.md` (EDIT)
**Changes:** Update the Track 3 documentation (line ~309) to reflect the new tiered search strategy, keeping it in sync with plan.md changes.
**Acceptance Criteria:**
- [ ] METHODOLOGY.md Track 3 description matches plan.md Track 3
- [ ] MCP tool names appear in the tools column
**Testing:** Visual review
**Rollback:** Revert METHODOLOGY.md

---

## Dependency Graph

```
MCP-001 (skill)        ─┐
MCP-002 (verification)  ─┤─── Gate: MCP-002 must pass before Phase 2
                         │
Phase 2 (parallel):      │
  MCP-003 (plan.md)     ─┤
  MCP-004 (troubleshoot) ┤ ← All independent, can run in parallel
  MCP-005 (doc)          ┤
  MCP-006 (int-scanner)  ┤
  MCP-007 (dep-mapper)  ─┘
                         
Phase 3 (parallel):
  MCP-008 (readiness)   ─┤ ← Independent of Phase 2
  MCP-009 (methodology) ─┘
```

## Timeline

| Phase | Tickets | Estimate | Go/No-Go |
|-------|---------|----------|----------|
| 1. Foundation | MCP-001, MCP-002 | 30 min | MCP-002 passes (absent tools don't error) |
| 2. Integration | MCP-003 through MCP-007 | 60-90 min | All files modified, manual smoke test |
| 3. Documentation | MCP-008, MCP-009 | 20 min | Visual review |

## Rollback Plan

Every ticket has individual rollback (revert the single file). For full rollback:
```bash
git revert --no-commit HEAD~{N}..HEAD  # Revert all MCP integration commits
```
No database changes, no config changes, no external dependencies affected.

## Operational Readiness

- **Monitoring:** N/A — no deployment, plugin-only changes
- **Config:** No new config required. MCP servers are user-installed.
- **Incident fallback:** Plugin works without MCP servers. Fallback is the current behavior.
- **Success metrics:** Confidence brief entries have TIER A/B sources when MCP tools are available; troubleshoot finds framework bugs faster; integration scanner flags deprecated APIs.

## Go/No-Go Criteria

| Gate | Criterion |
|------|-----------|
| Phase 1 → 2 | MCP-002 verified: `allowed-tools` with absent tools doesn't error |
| Phase 2 → 3 | All 5 command/agent modifications work with and without MCP |
| Phase 3 → Audit | METHODOLOGY.md stays in sync with plan.md |
