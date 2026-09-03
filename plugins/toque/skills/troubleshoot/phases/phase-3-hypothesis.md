# Phase 3: Hypothesis and Testing

Phase file for /toque:troubleshoot, loaded by SKILL.md on entry.

## Phase 3: HYPOTHESIS AND TESTING

### Step 3.1: Form ONE Hypothesis

"Based on the evidence: the bug is caused by {specific cause}
because {evidence from THIS codebase}."

The hypothesis MUST:
- Be specific (not "something is wrong with the data")
- Be testable (we can verify with a specific check)
- Reference evidence from Phase 1 and 2 (not general patterns)

### Step 3.2: Five Whys (for stubborn bugs)

If the first hypothesis doesn't hold, go deeper:
1. Why did it fail? -> "Because the receipt string was null"
2. Why was it null? -> "Because the lookup returned no result"
3. Why no result? -> "Because the key was French but the table has English keys"
4. Why English keys? -> "Because the migration only loaded English strings"
5. Why only English? -> "Because the French resource file wasn't in the build"

ROOT CAUSE: French resource file missing from build configuration.

### Step 3.3: Test Minimally

Change ONE variable at a time. Never bundle changes.

If confirmed: "Root cause confirmed: {cause}. Ready to fix."
If disproved: "That wasn't it. New hypothesis based on what we learned."

LOG: "Phase 3 complete. Root cause: {cause}. Evidence: {what we verified}."

