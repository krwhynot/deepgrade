# Stage 1: PLAN

Stage file for /deepgrade:plan. Loaded by SKILL.md on entry; re-read after compaction. Do not read ahead.

Question: What problem are we solving, and what is true about our situation?
Reads: $ARGUMENTS (plan name, optional source material), the codebase, connected search tools
Produces: docs/plans/{date}-{name}/intent.md, research/findings.md, research/reference-data.json, research/intake/ (if source docs)
Gate: A named product owner sets intent.md Status to Accepted

## Contents

- Intent-only mode
- Step 1: Intent interview (writes intent.md)
- Step 2: Research (three parallel tracks, writes research/findings.md)
- Step 3: Synthesis into intent.md
- Gate: acceptance by a named product owner

This stage merges the old brainstorm and research phases. The single artifact is
intent.md: a short, structured statement of the problem that a product owner can
read and accept without engineering context, and that Stage 2 (Design) reads to
produce spec.md. Research does not get its own gate any more; it feeds the
Constraints and Open questions sections of intent.md, and acceptance of intent.md
is the only exit from this stage.

INTENT-ONLY MODE:
When invoked as `/deepgrade:plan intent {name}`, run this stage only. Complete
the interview, run research, write intent.md, commit it, ask the product owner
for acceptance, and STOP. Do not enter Stage 2 (Design) even if acceptance is
given in the same session; the owner resumes with `/deepgrade:plan {name}` when
design should begin. This mode exists so a non-engineer can originate a plan
without committing anyone to building it.

Update status.json: plan -> in_progress (set started timestamp)

## Step 1: Intent interview

The originator may be a non-engineer. Ask ONE question at a time, in plain
language, and accept short answers. Do not ask for file paths, architecture, or
technology choices here; those belong to Stage 2 (Design). Each question maps to
one section of intent.md.

IF input is a vague idea or just a plan name:
  1. "What cannot be done today, and why does it matter?"              -> ## Problem
  2. "What should be true when this is done? How would you know?"     -> ## Proposed outcome
  3. "Who is affected, and which systems or teams does this touch?
      Who owns the decision to accept this?"                           -> ## Affected users and systems
  4. "What is fixed: deadline, budget, compliance, brand, security,
      compatibility, anything non-negotiable?"                          -> ## Constraints
  5. "What should this explicitly NOT cover?"                          -> ## Out of scope
  6. "What do you not know yet that would change the answer?"         -> ## Open questions

IF input includes source docs (from keyword):
  Read the source material, draft every section of intent.md from it, then ask:
  "Based on what I read, here's the problem as I understand it: [Problem section].
   Is this right, or should I adjust?"
  Confirm the remaining sections one at a time, showing the draft for each.

IF input includes an existing ticket or spec:
  Extract the problem statement and outcome, confirm with the originator, and ask
  only the questions the source does not answer.

Write intent.md in the plan folder:

```markdown
# {Title}

- Author: {originator name}
- Source: {team, channel, ticket, or "conversation"}
- Status: Draft
- Date: {YYYY-MM-DD}
- Accepted by: (pending)

## Problem

{In the originator's own words: what cannot be done today, and why it matters.}

## Proposed outcome

{What should be true when this is done. Observable and measurable where possible.}

## Affected users and systems

{Who is affected, which systems are touched, who owns the decision.}

## Constraints

{Time, budget, compliance, brand, security, compatibility, non-negotiables.}

## Out of scope

{What this intent explicitly does not cover.}

## Open questions

{Questions that must be answered before or during design. Research (Step 2)
answers or defers each one; the answer or the deferral is recorded here.}
```

Keep every section short and concrete. The product owner reviews this file; a
section they cannot understand is a section that will not be accepted.

Ask "Problem defined. Ready to research? [Y/n]" before spending research effort.
This is a courtesy checkpoint, not the stage gate.

## Step 2: Research

Run three research tracks IN PARALLEL using subagents:

PARALLELIZATION RULE: The three tracks are independent. Deploy them
simultaneously as subagents, each with its own context window. Do NOT
run them sequentially. Each writes its output to the plan folder.

TRACK 1 - CODEBASE SCAN (Subagent: Sonnet):
Objective: Find all related code in the current codebase.
Tools: Read, Grep, Glob, Bash
Output: docs/plans/{date}-{name}/research/codebase-scan.md
```bash
# Search for related code based on intent.md keywords
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
Write research/reference-data.json.
Record path-scoped fingerprints for referenced files (not full repo SHA).

STOP RUBRIC - Research is DONE when:
- Every intent.md open question is answered or explicitly deferred
- At least one viable implementation path is identified
- Top risks have mitigation ideas
- Remaining unknowns are non-blocking

## Step 3: Synthesis into intent.md

Research does not change the Problem or Proposed outcome sections; those are the
originator's. It updates two sections:

- ## Constraints: add constraints the research discovered that the originator did
  not name (an existing pattern the change must fit, a dependency version, a
  compliance boundary found in the codebase). Mark each "(from research)".
- ## Open questions: replace each question with its answer and the finding that
  answers it, or mark it "Deferred to design: {reason}". A question that research
  could not answer and that blocks design stays open and is called out in the
  acceptance prompt.

Present findings to the originator in plain language:
```
Research complete. Key findings:

CODEBASE: [what exists, what we can reuse]
SOURCE DOCS: [key facts extracted]
BEST PRACTICES: [recommended approach]

What we still don't know: [gaps, with assessment: blocking vs non-blocking]
Open questions resolved: [X of Y]
```

Update manifest.md: add intent.md and research files to Plan Files table with date.
Update status.json: record research file hashes under documents.

## Gate: acceptance by a named product owner

The stage exits only when a named person accepts intent.md. The originator may
accept their own intent if they own the decision; otherwise ask who does.

Prompt:
"intent.md is ready for acceptance. Who is the product owner accepting it?
 [1] Enter the owner's name to accept
 [2] Request changes (say what to adjust)
 [3] Reject (record the reason; the plan closes)"

If [1]:
  - Set intent.md header: Status: Accepted; Accepted by: {name}, {YYYY-MM-DD}
  - status.json phases.plan: { "status": "complete", "accepted_by": "{name}",
    "accepted_date": "{YYYY-MM-DD}", "completed": "{ISO timestamp}" }
  - Commit intent.md and the research folder together.
  - Update status.json: plan -> complete (set completed timestamp)
  - Update manifest.md progress table.
  - In intent-only mode: report "Intent accepted and committed. Resume with
    /deepgrade:plan {name} to begin design." and STOP.
  - Otherwise: proceed to Stage 2 (Design).

If [2]: revise the named sections, re-present, re-prompt. Research is re-run
only if the Problem or Proposed outcome changed materially.

If [3]: set Status: Rejected with the reason under a "## Rejection" section,
update status.json: plan -> rejected (set completed timestamp), commit, STOP.

An intent nobody has accepted is a draft. Stage 2 (Design) must not start from
a draft: an unaccepted intent produces a spec for a problem no one agreed exists.
