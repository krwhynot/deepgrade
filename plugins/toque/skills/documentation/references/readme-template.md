
Generate a README for "$1".

**Step 0: Disambiguate**

Read `docs/audit/baseline/dependency-map.json` and search for projects
matching "$1".

If no baseline exists: "No audit baseline found. Run /toque-audit:codebase-audit first."

If multiple projects match (e.g., "contact" matches contacts and
contacts.test), present a numbered list:
~~~
"$1" matches [N] projects:
  [1] contacts (MEDIUM risk, core module)
  [2] contacts.test (LOW risk)
Which project needs a README?
Or [A] All matching projects
~~~

Wait for the developer's choice.

**Step 1: Preview**

Show what the README will contain:
~~~
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
~~~

**Step 2: Generate README**

Generate the README directly, using:
- The project name and path
- Relevant baseline data

Write `{project-path}/README.md` using the skeleton below. Drop any section
with nothing verified to say rather than filling it with guesses; an outdated
or invented README is worse than a short one.

**Document skeleton**

~~~markdown
# {Project Name}

{One paragraph: what this project does, who calls it, and where it sits in
the system. Risk level and phase from the baseline if available.}

## Quick Start

```bash
{install command}
{build or run command}
{test command}
```

## Structure

| Path | Purpose |
|------|---------|
| `{dir or file}` | {what lives there} |

## Dependencies

- **Internal:** {modules this project imports, from dependency-map}
- **External:** {packages, with the ones that matter for security or upgrades}
- **Depended on by:** {modules that import this project}

## Integrations

| System | Direction | Touchpoint | Notes |
|--------|-----------|------------|-------|
| {external service, DB, queue} | In / Out / Both | {file:function} | {auth, rate limits, failure mode} |

## Configuration

| Variable | Required | Purpose | Default |
|----------|----------|---------|---------|
| `{ENV_VAR}` | Yes / No | {what it controls} | {value or none} |

## Testing

{Test project name, how to run it, what is covered and what is not.}

## Known Issues and Risks

{Findings from the baseline that touch this project, by ID. Link, don't
duplicate.}

## Related Documents

- PRDs: {links}
- ADRs: {links}
- Runbooks: {links}
~~~

**Step 3: Confirmation**

~~~
README created: {project-path}/README.md

[N] of [total] projects now have READMEs.
Projects still missing READMEs: [list top 5 by risk level]
~~~
