# Multi-Agent Mode (only when escalated from Phase 1)

Phase file for /toque:troubleshoot, loaded by SKILL.md on entry.

## MULTI-AGENT MODE (only when escalated from Phase 1)

When escalated, the orchestrator spawns up to 4 specialist subagents that
investigate in parallel. The orchestrator then cross-references their findings
to form a hypothesis.

### Specialist Agents

Spawn ONLY the agents relevant to this bug (not all 4 every time):

**Code Tracer** (spawn when: bug involves code logic or data flow)
```
Task: Read the code path from entry point to error.
- Trace the function call chain
- Identify where data transforms from correct to incorrect
- Check for assumptions that might not hold
- Report: which function, which line, what the data looks like
```

**Git Historian** (spawn when: "this used to work" or regression suspected)
```
Task: Check what changed and when.
- git log for recent changes to affected files
- git diff to identify exact changes
- git bisect if regression window is known
- Report: which commit, who changed it, what changed
```

**Data Inspector** (spawn when: bug involves wrong data, missing records, config)
```
Task: Check the data state and configuration.
- Query the database for the specific records involved
- Check config files for environment-specific values
- Check feature flags, environment variables
- Report: what the data actually is vs what it should be
```

**Integration Checker** (spawn when: bug crosses component boundaries)
```
Task: Test the boundaries between components.
- Check API request/response at each boundary
- Verify auth tokens, headers, content types
- Check for schema mismatches between caller and callee
- Report: where the contract breaks between components
```

### Orchestrator Synthesis

After specialists report back, the orchestrator:

1. CROSS-REFERENCE: Where do the findings agree? Where do they conflict?
   "Code Tracer found the function expects a string. Data Inspector found
   the database returns an integer. Git Historian shows the column type
   changed 3 commits ago. These findings converge on the same root cause."

2. IDENTIFY CONFLICTS: If findings contradict, investigate the gap.
   "Code Tracer says the function is never called. But Integration Checker
   found it IS called via the webhook handler. Let me check that path."

3. FORM HYPOTHESIS: Based on converged evidence from multiple agents.
   "Root cause: the migration in commit {hash} changed the column type
   from varchar to int, but the business logic still casts to string.
   This causes the data flow error found by Code Tracer."

4. PROCEED TO PHASE 4 (Fix): With the synthesized root cause.
   The multi-agent investigation replaces Phases 2 and 3 because:
   - Pattern Analysis was done by Code Tracer (found working vs broken)
   - Hypothesis was formed by cross-referencing all agent findings

LOG all specialist findings and the synthesis in the troubleshooting log.
Each specialist's full report is captured under its own heading in the log.
The orchestrator's synthesis (agreements, conflicts, hypothesis) is logged
as a separate section. Dead ends from specialists are logged too.

After synthesis, proceed directly to Phase 4 (Fix) and then Step 5 (Log).

---

