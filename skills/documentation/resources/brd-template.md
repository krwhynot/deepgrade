
Generate a BRD for "$1".

**Step 0: Disambiguate**

Read `docs/audit/baseline/feature-inventory.json` and identify domains
matching "$1".

If no baseline exists: "No audit baseline found. Run /audit first."

If "$1" matches a domain name exactly (e.g., "Ordering", "Payments"):
proceed with that domain.

If "$1" is vague or matches multiple domains, present options:
```
"$1" relates to features in multiple domains:
  [1] Ordering (12 features, avg confidence: 0.88)
  [2] Payments (8 features, avg confidence: 0.91)
  [3] Reporting (15 features, avg confidence: 0.72)
Which domain should the BRD cover?
```

Wait for the developer's choice.

If "$1" matches no existing domain:
```
"$1" doesn't match any existing domain in the baseline.
  [1] Create a BRD for a new business area named "$1"
  [2] Search the codebase for related features
```

**Step 1: Show Domain Scope**

Present the features that will be covered by this BRD:
```
BRD for [Domain] will cover [N] features:

  | Feature | Confidence | PRD? | Test Coverage |
  |---------|-----------|------|---------------|
  | [name]  | [score]   | [Y/N]| [status]      |

  Average confidence: [score]
  Features below 0.90: [count]

  [1] Proceed with BRD generation
  [2] Run deep scan on low-confidence features first
  [3] Cancel
```

**Step 2: Deep Scan (if chosen)**

For each feature below 0.90 confidence in this domain, read the source files,
verify entry points and database tables, and update confidence in the baseline.

**Step 3: Generate BRD**

Deploy the **brd-generator** agent with:
- The selected domain name
- The list of feature IDs in this domain
- Links to any existing PRDs and ADRs for cross-referencing

The agent will:
1. Write the BRD to `docs/brd/{domain}.md`
2. Update document-linkage.json for all features in this domain
3. Update feature-inventory.json linked_docs for all features
4. Validate all JSON files

**Step 4: Post-Generation**

After the BRD is created, check for PRD gaps:
```
BRD created: docs/brd/{domain}.md
Covers [N] features in the [Domain] domain.

Document chain status:
  [N] features have PRDs (complete chain: BRD -> PRD)
  [N] features need PRDs (run /create-prd [feature] for each)

  [1] Generate PRDs for all features missing them
  [2] Done for now
```
