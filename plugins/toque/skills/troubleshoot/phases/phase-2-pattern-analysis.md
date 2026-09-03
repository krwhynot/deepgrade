# Phase 2: Pattern Analysis (single-agent path)

Phase file for /toque:troubleshoot, loaded by SKILL.md on entry.

## Phase 2: PATTERN ANALYSIS (single-agent path)

### Step 2.1: Find Working Examples

```bash
grep -rn "{similar-pattern}" --include="*.cs" --include="*.vb" \
  . 2>/dev/null | grep -v node_modules | head -10
```

### Step 2.2: Compare Working vs Broken

"Working code does {X}. Broken code does {Y}. The difference is {Z}."

### Step 2.3: Check Dependencies and Assumptions

What does the broken code ASSUME that might not be true?
- Does it assume data exists? (null check missing)
- Does it assume order? (async timing)
- Does it assume format? (string vs number)
- Does it assume config? (environment-specific)

LOG: "Phase 2 complete. Working code does {X} differently.
The broken code assumes {Y} which is not true when {Z}."

