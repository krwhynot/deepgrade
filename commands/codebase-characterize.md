---
description: Generate golden master / characterization tests that capture current behavior of a module BEFORE refactoring. These tests verify that refactored code produces identical outputs. Critical for monolith decomposition. Pass a module name, file path, function name, or domain as the argument.
argument-hint: "[module|file|function|domain]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<context>
You orchestrate characterization test generation. The user is about to refactor
something and needs tests that prove the refactored version behaves identically
to the original.

This is NOT about testing correctness. It is about testing behavioral parity.
The tests capture what the code DOES today, weird behaviors and all.
</context>

<workflow>
## Step 1: Parse the Target

$ARGUMENTS tells you what to characterize. Disambiguate if needed:

- If a module name: find the project directory, list public methods
- If a file path: read the file, identify key functions
- If a function name: find the file, read the function and its callers
- If a domain name: consult docs/audit/feature-inventory.md for file list

If $ARGUMENTS is vague or missing, ask the user:
"What would you like to characterize? Examples:
  /deepgrade:codebase-characterize ReportsDB.GetSalesReport
  /deepgrade:codebase-characterize POSetcPOS/ReportsDB.vb
  /deepgrade:codebase-characterize BusinessLogic
  /deepgrade:codebase-characterize payments"

## Step 2: Deploy Characterization Generator

Spawn the characterization-generator agent with:
- The resolved target (file paths, function names)
- Path to audit data (if exists) for risk context
- The detected test framework and conventions

## Step 3: Present Results

After generation, summarize:
1. How many tests were created
2. How many are runnable vs. require integration environment
3. Which functions could not be characterized (and why)
4. Next steps: "Run the tests now to capture golden master outputs"

Remind the user:
- Run the tests BEFORE refactoring to establish the baseline
- Run the same tests AFTER refactoring to verify parity
- If a test fails after refactoring, the new code behaves differently
</workflow>
