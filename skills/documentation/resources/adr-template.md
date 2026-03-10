
Generate an ADR for "$1".

**Step 0: Disambiguate**

Search the audit baselines for content related to "$1":
- `docs/audit/baseline/risk-assessment.json` - risk-related decisions
- `docs/audit/baseline/integration-map.json` - integration/security decisions
- `docs/audit/baseline/dependency-map.json` - dependency decisions
- `docs/audit/baseline/feature-inventory.json` - feature-related decisions

If no baseline exists: "No audit baseline found. Run /audit first."

If "$1" is vague or could map to multiple decisions, present options:
```
"$1" could relate to several architectural decisions:
  [1] Credential rotation strategy (9 security findings)
  [2] Supabase RLS policy strategy (sec-008: 9 tables without row-level security)
  [3] Edge Function architecture (daily-digest, check-overdue-tasks)
Which decision should the ADR document?
```

Wait for the developer's choice.

If "$1" is specific enough (e.g., "React Admin v5 migration strategy"):
proceed directly.

**Step 1: Show Context**

Present the evidence from the baseline that relates to this decision:
```
ADR topic: [decision]

Related evidence from the audit:
  - [finding/metric from baseline]
  - [finding/metric from baseline]
  - [finding/metric from baseline]

Related features: [list from feature-inventory.json]
Related existing ADRs: [list from docs/adr/]

  [1] Proceed with ADR generation
  [2] I want to narrow or change the scope
  [3] Cancel
```

**Step 2: Generate ADR**

Deploy the **adr-generator** agent with:
- The specific decision topic
- Related feature IDs
- Related findings from the baselines

The agent will:
1. Create `docs/adr/` directory if needed
2. Read existing ADRs to match style
3. Write ADR-{NNN}-{topic}.md
4. Update document-linkage.json for related features
5. Update feature-inventory.json linked_docs
6. Validate all JSON files

**Step 3: Post-Generation**

```
ADR created: docs/adr/ADR-{NNN}-{topic}.md
Status: Proposed (needs team review to accept)
Linked to: [N] features, [N] PRDs, [N] BRDs

Next steps:
  - Review with team and change Status to Accepted/Rejected
  - Related PRDs that reference this decision: [list]
```
