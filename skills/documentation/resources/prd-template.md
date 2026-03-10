
Generate a PRD for "$1".

**Step 0: Disambiguate**

Read `docs/audit/baseline/feature-inventory.json` and search for features
matching "$1" by name, domain, namespace, or keyword.

If no baseline exists: "No audit baseline found. Run /audit first."

If multiple features match, present a numbered list:
```
"$1" matches N features:
  [1] Feature A (Domain, confidence: 0.92)
  [2] Feature B (Domain, confidence: 0.78)
  [3] Feature C (Domain, confidence: 0.65)
Which feature do you want a PRD for?
Or [A] All of the above (separate PRD per feature)
```

Wait for the developer's choice. Never assume which one they meant.

If zero features match in the baseline, ask:
```
"$1" was not found in the audit baseline.
  [1] Search the codebase directly (may find unindexed features)
  [2] Create a forward-looking PRD for a new feature named "$1"
```

**Step 1: Confidence Check**

Once a feature is selected, check its confidence score.

If confidence >= 0.90:
```
[Feature Name] confidence is [score]. Ready to generate PRD.
  [1] Generate PRD now
  [2] Run deep scan first to maximize accuracy
```

If confidence < 0.90:
```
[Feature Name] confidence is [score] (below 0.90 threshold).
The PRD may contain [ASSUMPTION] tags and unverified requirements.
  [1] Run deep scan first to verify to 95%+ (recommended)
  [2] Generate PRD at current confidence (will include assumption tags)
```

Wait for the developer's choice.

**Step 2: Deep Scan (if chosen)**

Read every entry point file for this feature. Trace database access patterns.
Verify table names. Check for feature flags. Search for callers.
Update the feature's confidence in feature-inventory.json.
Validate the JSON after writing.

**Step 3: Generate PRD**

Deploy the **prd-generator** agent with:
- The selected feature ID
- Whether to reverse-engineer (existing feature) or template (new feature)
- The verified confidence level

The agent will:
1. Create `docs/prd/{domain}/` directory
2. Write the PRD using the standard template
3. Update document-linkage.json and feature-inventory.json
4. Validate all JSON files

**Step 4: Post-Generation**

After the PRD is created, check document-linkage.json:

If no BRD exists for this feature's domain:
```
PRD created: docs/prd/{domain}/PRD-{name}.md

Note: No BRD exists for the [Domain] domain.
A BRD defines the business context for this feature.
  [1] Generate BRD now with /create-brd [domain]
  [2] Skip for now
```

If a BRD already exists:
```
PRD created: docs/prd/{domain}/PRD-{name}.md
Linked to: BRD-{NNN} and [N] ADRs
Document chain: BRD -> PRD -> [ADR status]
```

If no ADR exists for this feature:
```
Note: No ADR exists documenting the architectural decisions for this feature.
An ADR should document how and why this feature was built the way it is.
  [1] Generate ADR now with /create-adr [feature topic]
  [2] Skip for now
```
