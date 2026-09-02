# Phase 2: RESEARCH

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

Question: What is true about our situation?

Run three research tracks IN PARALLEL using subagents:

PARALLELIZATION RULE: The three tracks are independent. Deploy them
simultaneously as subagents, each with its own context window. Do NOT
run them sequentially. Each writes its output to the plan folder.

TRACK 1 - CODEBASE SCAN (Subagent: Sonnet):
Objective: Find all related code in the current codebase.
Tools: Read, Grep, Glob, Bash
Output: docs/plans/{date}-{name}/research/codebase-scan.md
```bash
# Search for related code based on brainstorm keywords
grep -ri "{keywords}" --include="*.cs" --include="*.vb" --include="*.ts" \
  --include="*.config" --include="*.json" . 2>/dev/null | grep -v node_modules | head -30
```
Read the key files found. Note existing patterns, current implementation, dependencies.

TRACK 2 - SOURCE DOC CLEANUP (Subagent: Sonnet, if docs were provided):
Objective: Clean and structure provided source documents.
Tools: Read, Write, Bash
Output: docs/plans/{date}-{name}/research/intake/ (structured files)
Read all files in the source folder. Extract structured data per content type.
Write cleaned data to research/intake/.

TRACK 3 - BEST PRACTICES (Subagent: Sonnet, if external search tools available):
Objective: Find how others solved similar problems.
Tools: Read, WebSearch, WebFetch, plus any connected MCP search tool whose name
ends in `__ref_search_documentation`, `__ref_read_url`, `__web_search_exa`,
`__web_fetch_exa`, or `__perplexity_ask` (see the `deepgrade:mcp-research` skill —
match by suffix, never by bare name)
Output: docs/plans/{date}-{name}/research/best-practices.md

Search strategy (use in order, stop when sufficient):
1. Ref: Search framework/library docs for the specific technologies in scope.
   Use ref_search_documentation with a complete question (not keywords).
2. Exa: Search for code examples of the pattern being considered.
   Use web_search_exa for both implementation examples and general patterns, then
   web_fetch_exa on the one result worth reading in full.
3. Perplexity: If Ref + Exa are insufficient, ask a targeted research question.
   Use perplexity_ask for focused answers with citations.
4. WebSearch/WebFetch: Fallback if MCP tools are not available.

If NO external search tools are available:
  Fall back to codebase-only research using built-in tools.
  Tag in findings.md: "[EXTERNAL RESEARCH UNAVAILABLE — findings based on codebase and training data only]"

SYNTHESIS (after all tracks complete):
Read all three track outputs. Cross-reference findings.
Write docs/plans/{date}-{name}/research/findings.md as the combined summary.

STOP RUBRIC - Research is DONE when:
- All brainstorm open questions are answered or explicitly deferred
- At least one viable implementation path is identified
- Top risks have mitigation ideas
- Remaining unknowns are non-blocking

When stop criteria are met, present findings:
```
Research complete. Key findings:

CODEBASE: [what exists, what we can reuse]
SOURCE DOCS: [key facts extracted]
BEST PRACTICES: [recommended approach]

What we still don't know: [gaps, with assessment: blocking vs non-blocking]
Open questions resolved: [X of Y]

Ready to set scope.
```

Write research/findings.md and research/reference-data.json.
Record path-scoped fingerprints for referenced files (not full repo SHA).

Update status.json: research -> complete with file hashes
Update manifest.md: add research files to Plan Files table with date.

GATE: Automatic. Tool proceeds when stop rubric is met.
