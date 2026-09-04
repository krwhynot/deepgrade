# Optional inputs

Toque reads a handful of files it does not write. If a codebase-analysis tool
has left them in `docs/audit/`, the planning commands and the documentation
templates use them to ground their output. If nothing has, everything still
works — the files make plans better-informed, and not one of them is required.

This file is the list, and it exists for one reason: nothing writes these paths
in this repository, so nothing exercises them. A typo in one reads exactly like
a repository that has never been analysed — silence either way. The sweep in
`tests/layer1-repo.sh` holds the list and the tree to each other, so a path can
neither drift nor appear undocumented.

**What it cannot do is tell you the file will ever exist.** These are inputs
from outside, and their producers are not this repository's concern. Nothing
here breaks if they never arrive.

## The list

Format rules (the sweep depends on them):

- One row per artifact. Column 1 is the repo-relative path Toque looks for at
  runtime, in the project it is planning against.
- Column 2 is every Toque file that reads it, comma-separated, repo-relative.
- Only functional files count — `commands/`, `agents/`, `skills/`, `scripts/`.
  README/GUIDE mentions are description, not consumption, and are not swept.

| Artifact | Read by |
| -------- | ------- |
| docs/audit/risk-assessment.md | plugins/toque/agents/plan-auditor.md, plugins/toque/agents/plan-scaffolder.md, plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/SKILL.md, plugins/toque/skills/documentation/references/spec-template.md |
| docs/audit/dependency-map.md | plugins/toque/agents/plan-auditor.md, plugins/toque/agents/plan-scaffolder.md, plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/references/spec-template.md, plugins/toque/skills/plan/stages/stage-3-build.md |
| docs/audit/integration-scan.md | plugins/toque/agents/plan-auditor.md, plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/references/spec-template.md, plugins/toque/skills/plan/stages/stage-3-build.md |
| docs/audit/feature-inventory.md | plugins/toque/commands/quick-plan.md, plugins/toque/skills/documentation/SKILL.md, plugins/toque/skills/documentation/references/spec-template.md |
| docs/audit/readability/readability-report.md | plugins/toque/skills/documentation/references/spec-template.md |
| docs/audit/baseline/feature-inventory.json | plugins/toque/skills/documentation/references/adr-template.md, plugins/toque/skills/documentation/references/brd-template.md, plugins/toque/skills/documentation/references/prd-template.md |
| docs/audit/baseline/dependency-map.json | plugins/toque/skills/documentation/references/adr-template.md, plugins/toque/skills/documentation/references/readme-template.md |
| docs/audit/baseline/risk-assessment.json | plugins/toque/skills/documentation/references/adr-template.md |
| docs/audit/baseline/integration-map.json | plugins/toque/skills/documentation/references/adr-template.md |

## Toque's own paths under docs/audit/

These live in the same directory but Toque writes them itself. They are listed
so the sweep can tell them apart from the inputs above — adding one needs an
entry here, not a row in the table.

- `docs/audit/plan-audit.md` — written by the design gate. `quick-audit.md`
  explicitly refuses to create it, which is why it appears in two files while
  being nobody's input.

## Not inputs

- **Plan folders (`docs/plans/{date}-{name}/`) are Toque's own.** Written by the
  planning commands and Toque's hooks (`tq-subagent-stop` appends
  `subagent-log.txt` there). Nothing outside Toque reads or writes them.
- **Session markers (`$TMPDIR/tq-*`) no longer exist.** The marker bus shipped
  inside `toque-guard` and was retired with it in 9.0.0. Layer 1's per-plugin
  core fails any plugin that grows a marker surface, so the bus cannot come back
  by accident.
- **The audit report staleness warning is gone.** Until 11.0.0 the SessionStart
  hook stat-ed an audit report and warned when it was more than a week old. That
  made a session message depend on another tool having run in the same
  repository. Toque reports on its own plans.
- **`readability-score.json` is not read.** It was the one machine-read file in
  the old contract, and Toque was never a consumer — only a neighbour was.

## Change protocol

Adding a read: add the path to the table with every file that reads it, in the
same commit. Removing the last reader: delete the row. The sweep fails on either
half done alone.

Renaming is the case with no safe protocol, because the other end of the rename
is not here. Accept both names, ship, and drop the old one only when no
repository still carries it — which is not observable from this side, so it is a
judgement call rather than a check.
