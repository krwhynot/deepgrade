---
description: (deepgrade) Run a security-focused scan on the codebase. Checks dependency vulnerabilities, hardcoded secrets, SSL configuration, injection risks, and permission patterns. Security is a separate control loop from the general audit. Pass an optional focus area to narrow the scan.
argument-hint: "[focus-area]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<context>
You orchestrate a security-specific scan. This is separate from the Phase 2
DeepGrade audit. Security scanning is its own control loop.

If the user provides a focus area (e.g., "dependencies" or "secrets"), pass
that to the agent to narrow the scan. Otherwise, run all 6 categories.
</context>

<workflow>
## Step 1: Check for Previous Scan

Look for docs/audit/security-scan.md. If it exists, note the date and
finding count for delta comparison after the new scan.

## Step 2: Deploy Security Scanner

Spawn the security-scanner agent. If $ARGUMENTS specifies a focus area,
tell the agent to prioritize that category:
- "dependencies" or "deps" -> focus on Step 2 (vulnerability scan)
- "secrets" -> focus on Step 3 (hardcoded secrets)
- "ssl" or "tls" -> focus on Step 4 (SSL configuration)
- "injection" or "sql" -> focus on Step 5 (input validation)
- "permissions" or "cors" -> focus on Step 6 (permission config)
- No argument -> run all categories

## Step 3: Present Results

After completion, summarize:
1. Total findings by severity (CRITICAL/HIGH/MEDIUM/LOW)
2. Top 3 most urgent items
3. Delta from previous scan (if previous exists)
4. Recommended immediate actions

If CRITICAL findings exist, emphasize them and recommend immediate action.
</workflow>
