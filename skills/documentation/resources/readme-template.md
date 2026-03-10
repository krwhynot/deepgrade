
Generate a README for "$1".

**Step 0: Disambiguate**

Read `docs/audit/baseline/dependency-map.json` and search for projects
matching "$1".

If no baseline exists: "No audit baseline found. Run /audit first."

If multiple projects match (e.g., "contact" matches contacts and
contacts.test), present a numbered list:
```
"$1" matches [N] projects:
  [1] contacts (MEDIUM risk, core module)
  [2] contacts.test (LOW risk)
Which project needs a README?
Or [A] All matching projects
```

Wait for the developer's choice.

**Step 1: Preview**

Show what the README will contain:
```
README for [Project Name]:
  - Language: [detected from project files]
  - Risk: [level], Phase: [N]
  - Features: [N] features in this project
  - Dependencies: [N] internal imports, [N] npm packages
  - Integrations: [N] external touchpoints
  - Test project: [name or None]
  - Existing README: [Yes (will overwrite) / No]

  [1] Generate README
  [2] Cancel
```

**Step 2: Generate README**

Deploy the **readme-generator** agent with:
- The project name and path
- Relevant baseline data

The agent writes `{project-path}/README.md`.

**Step 3: Confirmation**

```
README created: {project-path}/README.md

[N] of [total] projects now have READMEs.
Projects still missing READMEs: [list top 5 by risk level]
```
