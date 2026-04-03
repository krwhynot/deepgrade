# Test Plan: MCP Research Integration
Date: 2026-04-03

## Tier 1 — Automated Verification (COMPLETE)

| Check | Result |
|-------|--------|
| plan.md has 6 MCP tools in allowed-tools | PASS |
| troubleshoot.md has 4 MCP tools in allowed-tools (no Perplexity) | PASS |
| doc.md has 3 MCP tools in allowed-tools | PASS |
| integration-scanner.md has 2 Ref tools in tools: | PASS |
| dependency-mapper.md has 2 Ref tools in tools: | PASS |
| skills/mcp-research/SKILL.md exists | PASS |
| Graceful degradation tags present in all modified files | PASS (13 total) |
| readiness-generate.md has research MCP generation section | PASS (4 keywords found) |
| Documentation skill has External Enrichment section | PASS (7 references found) |
| Perplexity excluded from troubleshoot.md | PASS (0 references) |
| METHODOLOGY.md Track 3 updated | PASS |

**Tier 1 Result: 11/11 PASS**

## Tier 2 — Manual Verification (User)

- [ ] Run `/deepgrade:plan test` WITHOUT MCP servers → verify no errors, Track 3 skips gracefully
- [ ] Run `/deepgrade:plan test from "idea: test"` WITH Ref MCP connected → verify Track 3 uses ref_search_documentation
- [ ] Run `/deepgrade:troubleshoot "test error"` WITHOUT MCP → verify Step 0.2 is skipped
- [ ] Run `/deepgrade:codebase-audit` on a project → verify integration-scanner includes [API-UNVERIFIED] tags
- [ ] Verify plugin loads cleanly: `claude plugin install deepgrade@deepgrade-marketplace --scope user`
