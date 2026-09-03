# Phase 1: Root Cause Investigation

Phase file for /toque:troubleshoot, loaded by SKILL.md on entry.

## Phase 1: ROOT CAUSE INVESTIGATION

### Step 1.1: Categorize the Bug Type

Based on the user's description, categorize:

| Category | Signals | First Check |
|----------|---------|------------|
| Logic | Wrong output, wrong behavior | Read the function, trace the logic |
| Boundary | Works sometimes, fails on edge cases | Check input ranges, null, empty |
| Error Handling | Crashes, unhandled exception | Read the catch/finally blocks |
| Data Flow | Data is wrong downstream | Trace from source to where it's wrong |
| Integration | Works alone, fails with other components | Check the boundaries between components |
| Timing | Intermittent, works then doesn't | Check async, race conditions, order |

Tell the user: "This looks like a {category} issue. Here's my approach..."

### Step 1.2: Check Recent Changes (ALWAYS do this first)

```bash
echo "=== Recent commits ==="
git log --oneline -10 2>/dev/null

echo "=== Files changed in last 3 commits ==="
git diff --name-only HEAD~3 2>/dev/null

echo "=== Uncommitted changes ==="
git status --short 2>/dev/null
```

"These files changed recently: {list}. The bug may be in one of these changes."

### Step 1.3: Reproduce the Issue

Ask: "Can you reproduce this consistently? What are the exact steps?"

If yes: "Good. A reproducible bug is a solvable bug."
If no: "Intermittent issues are often timing-related. Let me check for
race conditions, shared state, or order-dependent behavior."

### Step 1.4: Read the Actual Code

Read the files involved. Don't guess.

```bash
grep -rn "{error-or-function}" --include="*.cs" --include="*.vb" \
  --include="*.ts" --include="*.tsx" . 2>/dev/null | grep -v node_modules | head -20
```

Read the files. Understand the data flow. Note what you see.

### Step 1.5: Gather Evidence

For multi-component issues, trace data across boundaries:
- What goes IN to the function?
- What comes OUT?
- Where does the data change from correct to incorrect?

LOG: "Phase 1 complete. The issue is in {file}:{function}.
The data is correct at {point A} but wrong at {point B}."

### Step 1.6: Escalation Check (Auto-Detect Multi-Agent Need)

After Phase 1, assess whether this bug needs parallel investigation.

ESCALATION CRITERIA (if ANY are true, offer multi-agent):
- Bug spans 3+ layers (frontend + backend + database, or UI + business logic + config)
- 2+ competing hypotheses exist and each requires reading different codebases
- Investigation requires holding 4+ mental contexts simultaneously
- The same investigation area keeps branching (checking one thing reveals 3 more things)
- Serial investigation would take 15+ minutes of context-switching

If escalation criteria are NOT met (most bugs):
  "This looks like a straightforward {category} issue in {file}. Continuing
  single-agent investigation."
  -> Proceed to Phase 2 (Pattern Analysis) normally.

If escalation criteria ARE met:
  "This looks like a cross-layer issue spanning {areas}. I can investigate
  faster by running parallel agents. Escalate to multi-agent mode? [Y/n]"

  If user confirms, switch to MULTI-AGENT MODE (see below).
  If user declines, continue single-agent through Phases 2-4.

---

