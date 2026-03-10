---
description: (deepgrade) Clean up a folder of messy documents (PDFs, images, text files, vendor manuals, meeting notes, legacy docs) into standardized markdown and JSON reference files. Guides you through understanding the data first, then cleans it into structured reference material. Automatically creates a plan homebase folder if one doesn't exist. This may be the only step in a plan, or the first step of a larger plan.
argument-hint: "[folder-path] [topic-name] [--plan plan-name]"
allowed-tools: Read, Write, Grep, Glob, Bash, Task
---

<plan_homebase>
Every cleanup gets a plan homebase folder. The cleanup may be the ONLY thing
in that plan (just cleaning docs for reference), or it may be the FIRST step
of a larger plan (cleanup -> spec -> audit -> build).

RESOLUTION ORDER:
1. If --plan {name} specified: use that plan folder
2. If a matching plan already exists in docs/plans/: ask "Link to existing plan {name}? [Y/n]"
3. If no plan exists: CREATE a new plan homebase folder automatically

When creating a new plan folder:
```bash
TODAY=$(date +%Y-%m-%d)
PLAN_NAME="{topic-name}"  # derived from folder name or user input
PLAN_DIR="docs/plans/${TODAY}-${PLAN_NAME}"
mkdir -p "$PLAN_DIR/research/intake"
```

Create initial manifest.md and status.json in the plan folder.
The cleanup output goes to: docs/plans/{date}-{name}/research/intake/

After cleanup, suggest next steps but don't assume a full plan is needed:
- "Cleanup complete. Your data is in docs/plans/{date}-{name}/research/intake/"
- "If this is all you needed, you're done."
- "If you want to build something with this data, run /deepgrade:plan {name} to continue."
</plan_homebase>

<context>
You are a data cleanup specialist. Before cleaning anything, you need to
UNDERSTAND what this data is and what it's for. This ensures the AI focuses
on the right content and uses the right extraction schema.

KEY PRINCIPLE: Understand first, then clean. Ask brainstorm questions BEFORE
extracting. This prevents cleaning the wrong things or missing what matters.

SECOND PRINCIPLE: Separate ingestion from reasoning. This command produces
CLEAN REFERENCE FILES (facts). Planning commands use those facts to make
decisions. This command does NOT create plans or specs.

RESEARCH BASIS:
- "Data quality has greater impact than model size" (Context-Clue, 2026)
- "70% of AI projects fail due to data quality" (McKinsey via Firecrawl)
- "Separate ingestion from reasoning" (LlamaIndex, 2026)
- "Two-pass extract then validate" (doc2md pipeline)
- "Schema-first extraction reduces hallucination 40-60%" (Reintech)
</context>

<workflow>
## Step 0: Parse Arguments and Resolve Plan Folder

$ARGUMENTS format: [folder-path] [topic-name] [--plan plan-name]
- folder-path (required): directory containing messy docs
- topic-name (optional): short name. If not provided, derive from folder name.
- --plan (optional): link to existing plan

Resolve the plan homebase (see <plan_homebase> rules above).
If creating a new plan, confirm the name:
```
I'll create a plan folder for this cleanup: docs/plans/2026-03-08-worldpay-canada/
  [1] Use this name
  [2] Enter a different name
```

## Step 1: Quick Inventory

```bash
FOLDER="$1"
echo "=== Source Inventory ==="
find "$FOLDER" -type f | while read f; do
  SIZE=$(du -h "$f" | cut -f1)
  EXT="${f##*.}"
  echo "$EXT | $SIZE | $f"
done | sort

echo ""
echo "=== Counts by Type ==="
for ext in pdf png jpg jpeg gif bmp svg doc docx txt md json xml yaml yml csv xlsx xls pptx; do
  COUNT=$(find "$FOLDER" -iname "*.$ext" 2>/dev/null | wc -l)
  [ "$COUNT" -gt 0 ] && echo "  .$ext: $COUNT files"
done
```

Show the inventory but do NOT start extracting yet. Move to brainstorm first.

## Step 2: Brainstorm (Understand Before Cleaning)

Ask these questions ONE AT A TIME to understand what to focus on:

**Question 1: What is this data?**
```
Found [N] files in [folder]:
  [breakdown]

What type of content is this?
  [1] Vendor/hardware documentation (manuals, setup guides, API specs)
  [2] Meeting notes and decisions (notes, minutes, action items)
  [3] Legacy handoff documentation (from previous team/employee)
  [4] Requirements and specifications (customer reqs, RFPs, feature requests)
  [5] Mixed / not sure (I'll categorize as I read)
```

**Question 2: What's the goal?**
```
What do you need from this data?
  [1] Just organize and clean it for reference (this is the whole plan)
  [2] Preparing for an integration or feature build
  [3] Need to understand what a vendor/system does before making decisions
  [4] Onboarding to something someone else set up
  [5] Not sure yet, just clean it and I'll decide
```

**Question 3: What matters most?**
Based on the content type and goal, ask ONE targeted follow-up:
- If vendor docs + integration: "What system are we integrating with, and what's the codebase stack?"
- If meeting notes + decisions: "What project were these meetings about?"
- If legacy handoff: "What system is this for, and who handed it off?"
- If requirements: "What feature or product are these requirements for?"
- If not sure: "Can you give me one sentence about why you have these files?"

Use the answers to:
1. Set the plan name (if not already set)
2. Choose the right extraction schema (Step 4)
3. Know what to prioritize during extraction
4. Write a focused brainstorm.md

## Step 3: Write Brainstorm

Write docs/plans/{date}-{name}/brainstorm.md:

```markdown
# {Plan Name}

## Problem Statement
{derived from the user's answers - what is this data and why does it matter}

## Goals
- {what the user needs from this cleanup}

## Non-Goals
- {what this cleanup is NOT trying to do}

## Data Profile
- Source folder: {path}
- Files: {count} ({breakdown})
- Content type: {vendor/meeting/handoff/requirements/mixed}
- Focus area: {what matters most based on Q3 answer}

## Open Questions
- {anything unclear from the brainstorm}
```

Update status.json: brainstorm -> complete, research -> in_progress.
Update manifest.md with brainstorm.md entry.

## Step 4: Inventory and Classify (now with context)

The content type from brainstorm (Step 2) determines the extraction schema.

## Step 5: Extract Content (Pass 1 - Fast Extraction)

Read all files and extract raw text. Use the appropriate tool per file type:

**Markdown/Text:** Read directly.

**PDF:**
```bash
# Try pdftotext (most reliable)
pdftotext "$FILE" - 2>/dev/null

# Fallback: python PyPDF2
python3 -c "
import sys
try:
    from PyPDF2 import PdfReader
    reader = PdfReader('$FILE')
    for i, page in enumerate(reader.pages):
        text = page.extract_text()
        if text:
            print(f'--- PAGE {i+1} ---')
            print(text)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" 2>/dev/null
```

**Word (.docx):**
```bash
pandoc "$FILE" -t markdown 2>/dev/null || python3 -c "
from docx import Document
doc = Document('$FILE')
for p in doc.paragraphs:
    print(p.text)
" 2>/dev/null
```

**Excel/CSV:** Extract as markdown tables.
```bash
python3 -c "
import csv, sys
with open('$FILE') as f:
    reader = csv.reader(f)
    for row in reader:
        print('| ' + ' | '.join(row) + ' |')
" 2>/dev/null
```

**Images:** Cannot extract text. Index by filename. Note apparent content
type from filename (e.g., "terminal-wiring-diagram.png" -> hardware diagram).

**Unreadable files:** Note which files could not be parsed. Add to the
source index as "[MANUAL REVIEW REQUIRED]".

## Step 6: Schema-First Extraction

Based on the content type from Step 1, extract into predefined schemas.
This reduces hallucination by giving the extraction a target structure.

### Schema A: Vendor/Hardware Documentation
Extract these fields:
```json
{
  "overview": "What this vendor/product does (1 paragraph)",
  "supported_hardware": [
    {"model": "", "interface": "", "firmware": "", "notes": ""}
  ],
  "connection_architecture": "How it connects to our system",
  "api_endpoints": [
    {"endpoint": "", "method": "", "purpose": "", "auth": ""}
  ],
  "configuration": [
    {"setting": "", "default": "", "description": "", "location": ""}
  ],
  "security_requirements": ["TLS version", "cert requirements", "PCI notes"],
  "setup_steps": [
    {"step": 1, "action": "", "verification": ""}
  ],
  "troubleshooting": [
    {"symptom": "", "cause": "", "fix": ""}
  ],
  "credentials_required": ["what creds are needed, NOT the actual values"],
  "source_files": {"field_name": "source_file:page_number"}
}
```

### Schema B: Meeting Notes / Decisions
Extract these fields:
```json
{
  "date": "",
  "participants": [],
  "decisions_made": [
    {"decision": "", "rationale": "", "owner": ""}
  ],
  "action_items": [
    {"action": "", "owner": "", "deadline": "", "status": ""}
  ],
  "open_questions": [],
  "key_facts": ["factual statements made during discussion"],
  "source_files": {"field_name": "source_file"}
}
```

### Schema C: Legacy Handoff
Extract these fields:
```json
{
  "system_overview": "",
  "architecture_notes": "",
  "known_issues": [],
  "tribal_knowledge": ["things only the previous team knew"],
  "passwords_and_access": ["what access is needed, NOT actual credentials"],
  "deployment_process": "",
  "critical_contacts": [],
  "source_files": {"field_name": "source_file"}
}
```

### Schema D: Requirements
Extract these fields:
```json
{
  "requirements": [
    {"id": "", "description": "", "priority": "", "source": ""}
  ],
  "constraints": [],
  "assumptions": [],
  "acceptance_criteria": [],
  "source_files": {"field_name": "source_file"}
}
```

## Step 7: Validate Extraction (Pass 2 - Quality Check)

For each extracted field, verify against the source:
1. Did we capture all major sections from each source file?
2. Are numbers/specs accurate (not hallucinated)?
3. Did we miss any tables or structured data?
4. Are source references correct (right file, right page)?

Track validation stats:
```
Validation: [N] fields extracted, [M] verified, [K] marked [UNVERIFIED]
Coverage: [X]% of source material captured
Files fully processed: [A]/[B]
Files requiring manual review: [list]
```

## Step 8: Write Output to Plan Folder

All output goes to the plan's research/intake/ directory:
```bash
PLAN_DIR="docs/plans/${TODAY}-${PLAN_NAME}"
OUTPUT_DIR="$PLAN_DIR/research/intake"
mkdir -p "$OUTPUT_DIR"
```

### File 1: summary.md (always created)
One-page overview of everything that was in the source folder.

```markdown
# {Topic} - Intake Summary

**Source:** {folder path}
**Processed:** {date}
**Files processed:** {N} of {total} ({X}% coverage)
**Content type:** {Vendor docs / Meeting notes / Legacy handoff / Requirements}

## Key Takeaways
[3-5 most important facts extracted from all source material]

## Content Overview
[Section-by-section summary of what was found]

## What This Means for Our Codebase
[Cross-reference with existing code if applicable:
 e.g., "Our codebase already has triPOS integration at POSetcPOS/CreditCard/"]

## Files Requiring Manual Review
[Files that could not be fully parsed - images, corrupt PDFs, etc.]

## Next Steps
Recommended toolkit commands to run with this cleaned data:
- `/deepgrade:quick-plan "{topic} integration"` (if implementation needed)
- `/deepgrade:doc spec {topic}` (if a technical spec is needed)
- `/deepgrade:doc adr {topic}` (if an architectural decision is needed)
```

### File 2: reference-data.json (always created)
Structured data extracted per the schema from Step 3.

### File 3: setup-checklist.md (if applicable)
Only created when setup steps were found in the source material.

```markdown
# {Topic} - Setup Checklist

## Prerequisites
- [ ] {prerequisite with verification step}

## Setup Steps
- [ ] Step 1: {action} -- Verify: {how to confirm this worked}
- [ ] Step 2: {action} -- Verify: {verification}

## Validation
- [ ] {End-to-end test to confirm full setup is working}
```

### File 4: source-index.md (always created)
Maps every extracted fact back to its source file.

```markdown
# {Topic} - Source Index

| Output Location | Fact/Field | Source File | Page/Section |
|----------------|-----------|-------------|-------------|
| summary.md:line 12 | "Supports VeriFone P400" | Worldpay-Manual.pdf | Page 7 |
| reference-data.json:api_endpoints[0] | "POST /payment" | API-Guide.txt | Section 3 |
[every extracted fact traceable to its source]

## Source Files Inventory
| File | Type | Pages/Size | Processed? | Notes |
|------|------|-----------|-----------|-------|
[full inventory with processing status]
```

## Step 9: Completion Report

Update status.json: research -> complete.
Update manifest.md: add all output files to Plan Files table with dates.
Also write research/findings.md as a summary of the cleaned data.

```
Cleanup complete for "{topic}":

Plan folder: docs/plans/{date}-{name}/

Created:
  docs/plans/{date}-{name}/brainstorm.md                    (problem + goals)
  docs/plans/{date}-{name}/research/intake/summary.md       ({N} lines)
  docs/plans/{date}-{name}/research/intake/reference-data.json ({N} fields)
  docs/plans/{date}-{name}/research/intake/setup-checklist.md  ({N} steps) [if applicable]
  docs/plans/{date}-{name}/research/intake/source-index.md  ({N} traced facts)
  docs/plans/{date}-{name}/research/findings.md             (key findings summary)

Quality:
  Files processed: {A}/{B} ({X}%)
  Fields extracted: {N}
  Fields verified: {M} ({Y}%)
  Manual review needed: {K} files

If this is all you needed, you're done. Your cleaned data is ready for reference.

If you want to continue building on this data:
  /deepgrade:plan {name}         Resume the plan from Phase 3 (Pre-Plan)
  /deepgrade:quick-plan "{topic}" Create a spec directly from this data
  /deepgrade:doc spec {topic}    Create a technical specification
  /deepgrade:doc adr {topic}     Document an architectural decision
```
</workflow>

<constraints>
- Do NOT delete or modify the original source files. Create new files only.
- Do NOT create specs or plans. This is the CLEANUP step only.
- Do NOT expose actual credentials, passwords, or API keys found in docs.
  Redact to "[REDACTED]" and note what type of credential was found.
- Every extracted fact MUST be traceable to a source file via source-index.md.
- If a PDF or doc cannot be parsed, note it as [MANUAL REVIEW] and move on.
- Prefer markdown for prose, JSON for structured data, CSV for tabular data.
- Keep summary.md under 200 lines. Details go in reference-data.json.
- The source-index.md is the PROOF that cleanup was accurate. Never skip it.
</constraints>
