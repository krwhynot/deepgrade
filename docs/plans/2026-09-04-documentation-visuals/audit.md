# Documentation visuals audit — September 4, 2026

**Status: audit complete; the minimum set was applied on September 5, 2026 at the owner's request.** Applied: V1 and V1b (`documentation/install.md`), V2 (`documentation/the-plan-workflow.md`), V3a and V3b (`documentation/the-design-gate.md`), V4 (`plugins/toque/GUIDE.md`), and the R2 prose fix plus a link to V4 (`plugins/toque/README.md`). V5 through V11 and R5/R11 remain drafts. No plugin behavior, historical record, mascot asset, commit, or remote state was changed. Pre-existing uncommitted edits were preserved and audited as the current text.

Companion files: [visual-proposals.md](visual-proposals.md) holds every draft with placement and evidence; [verification.md](verification.md) holds rendering results, factual checks, and unresolved contradictions; [preview.html](preview.html) renders every Mermaid draft locally (serve the folder over HTTP; the page loads Mermaid 11 from a CDN); `previews/` holds three screenshots from that page.

## Scope and commit

| Item | Value |
| --- | --- |
| Repository | `krwhynot/toque`, checkout HEAD `95c53af1663e4eee57bddb4f32579fefd136e4ef` (`release: pin the catalog to the 11.0.1 release commit`) |
| Working tree | 18 tracked files modified and 6 untracked paths at the start of the audit (`git status`); the modified set includes `README.md`, `METHODOLOGY.md`, every page under `documentation/`, `interop.md`, `plugins/toque/GUIDE.md`, `plugins/toque/README.md`, four command or stage files, `tests/run-all.sh`, and `.github/workflows/suite.yml`. The audit reads the working tree, not HEAD, because the user asked for those edits to be preserved. |
| Installed plugin identity | `plugins/toque/.claude-plugin/plugin.json` version `11.0.1`; `.claude-plugin/marketplace.json` pins `plugins/toque` at `v11.0.1`, SHA `63a05063ed87b2a9168127ca715208c4cad74d5a` |
| Skills source | `anthropics/knowledge-work-plugins` at commit `1f517b9de47e827c80cd933ed364e16838072239` (merge of PR 1062, 2026-09-04 21:32 +0100), sparse-cloned into the session scratchpad; the four `SKILL.md` files were read in full |
| Audience | A developer meeting Toque for the first time; maintainers second |

## Skills applied

| Skill | Read | Concrete contribution |
| --- | --- | --- |
| `engineering/skills/documentation/SKILL.md` | Full file | Its five principles set the register's decision rule: a visual is added only where a reader currently has to reconstruct a relationship; "link, don't duplicate" produced the single-home rule (one authoritative diagram, links elsewhere) and the cross-page link table at the end of the proposals; its README and onboarding-guide outlines ("how systems connect", "environment setup") map to V1, V1b, and V4. |
| `design/skills/design-critique/SKILL.md` | Full file | Applied per page as first impression, reading order, hierarchy, consistency. It surfaced the four near-duplicate six-stage tables with drifting gate wording (R11), the existing METHODOLOGY flowchart that renders at 44% (V11), and the rule that a diagram answers one question, which split the gate into V3a and V3b. Its severity vocabulary was replaced by the task's High/Medium/Low rubric. |
| `design/skills/accessibility-review/SKILL.md` | Full file | WCAG 1.1.1 drove the "text explanation that survives a failed render" field on every draft and the alt-text check on existing images; 1.4.3 and 1.4.11 drove the measured contrast pass in verification.md; the "status by text, not colour" rule removed every `style` fill from the drafts; the 200% zoom item became the 380px check. Keyboard, focus, and form criteria were skipped as inapplicable to static Markdown. |
| `data/skills/data-visualization/SKILL.md` | Full file | **Not applied.** No verified numerical series exists in the documentation scope. Candidates considered and rejected: suite assertion counts (fixture counts, not a trend), the minute estimates in `plugins/toque/commands/help.md:57` (unsupported by any measurement in the repository), the "75 contradictions" figure in the changelog (historical). The skill's chart-selection guidance was consulted only to confirm that a workflow is not a Sankey or funnel. |

Native invocation of these plugins was not used; the Markdown instructions were read and applied directly. No plugin was installed globally and no connector was used.

## Page coverage ledger

Every page in scope was read in full, in bounded sections where longer than about 400 lines.

| Page | Lines | Read | Intended reader, primary question | Existing visuals | Decision |
| --- | --- | --- | --- | --- | --- |
| `README.md` | 162 | Full | New visitor: what is Toque, should I use it? | Mascot PNG, design-gate PNG (both with descriptive alt text), Without/With table, six-stage table, documentation-map table, repository tree block | Retain all; no new visual (R1) |
| `plugins/toque/README.md` | 166 | Full | Installed-plugin reader: what did I get? | Mascot PNG, command tables, six-stage table, hooks table, dependencies, output-locations table, architecture list | Retain visuals; two prose contradictions to fix (R2); link to V4 |
| `plugins/toque/GUIDE.md` | 281 | Full | Regular operator: how do I operate everything? | Mascot PNG, nine tables (entrypoints, stages, flags, agents, skills, templates, hooks, outputs) | Add component map (V4); retain tables |
| `documentation/install.md` | 110 | Full | Installer or upgrader | Mascot PNG, prerequisites table, scope table, troubleshooting table | Add V1; replace prerequisites with V1b; retain scope and troubleshooting tables |
| `documentation/quickstart.md` | 108 | Full | First-time operator: how do I finish one workflow? | Mascot PNG, numbered steps | No visual needed; steps are linear (R3); one link to V6 |
| `documentation/when-to-use.md` | 59 | Full | Developer choosing a command | Mascot PNG, job table | Add decision flowchart (V5); retain table as the authoritative list |
| `documentation/the-plan-workflow.md` | 215 | Full | Workflow operator: what happens at each stage? | Mascot PNG, testing-method table, assumption-state table | Add reads/writes/decisions table (V2); replace approval-tier prose with V7; link to METHODOLOGY flowchart; retain both existing tables (R8) |
| `documentation/plan-workspace.md` | 163 | Full | Returning operator: what files exist, how do I resume? | Mascot PNG, folder tree, `status.json` example, recovery, freshness, cascade, and migration tables | Add status state diagram (V6); retain everything else (R7) |
| `documentation/the-design-gate.md` | 110 | Full | Reviewer: what can the gate prove or refuse? | Design-gate PNG with alt text, verdict table, PASS block, term table, waiver block | Add two flowcharts (V3a, V3b); retain tables and PNG (R9) |
| `METHODOLOGY.md` | 1192 | Full, three bounded reads (1-400, 400-800, 800-1192) | Methodology reader: why these methods? | One Mermaid flowchart, stage-commits table, testing-foundation table, historical weight and grade tables, lint-rule table, decay table, hook table, worker table | Re-lay the flowchart top-down (V11); retain every table, including historical ones, and every heading and anchor (R10) |
| `interop.md` | 57 | Full | Integrator: what external analysis can Toque read? | Mascot PNG, artifact/reader table (format locked by `tests/layer1-repo.sh` INTEROP-1/2) | Retain; do not touch the table format (R4) |
| `CONTRIBUTING.md` | 147 | Full | Maintainer | Repository tree block | Add release flowchart (V8), suite-layer table (V9), CI-job table (V10) |
| `tests/mutation/README.md` | 64 | Full | Maintainer running the mutation harness | Failure-mode table | Retain (R6) |
| `plugins/toque/commands/help.md` | 161 | Full | In-session `/toque:help` reader | Verdict table, command tables, plan-versus-quick-plan comparison, output-locations table | Retain tables (Mermaid does not render in conversation output); two prose contradictions to fix (R5) |
| `docs/documentation-inventory.md` | 58 | Full | Working record from the rewrite | Two tables | Out of scope (not a published page); used as evidence for prior decisions |
| `CHANGELOG.md` | 1014 | First 60 lines only | Historical | — | Background only; not treated as current functionality |

Evidence sources read in full for verification: `plugins/toque/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `plugins/toque/hooks/hooks.json`, all five `plugins/toque/scripts/*.js`, `skills/plan/SKILL.md`, all six `skills/plan/stages/*.md`, both `agents/*.md`, `skills/troubleshoot/SKILL.md`, `skills/documentation/SKILL.md`, `commands/quick-plan.md`, `commands/quick-audit.md`, `commands/plan-status.md`, `commands/plan-export.md`, `commands/quick-cleanup.md`, `tests/run-all.sh`, `.github/workflows/suite.yml`, `.github/release.sh`, `.github/protected-artifacts.sh`, and the conformance audit's `manifest.md`, `findings.md`, and `verification.md`. Read in part: `tests/layer1-repo.sh` (interop section, lines 1255-1345), `docs/planning-techniques/lint-registry.md` (rules table), `skills/mcp-research/SKILL.md` (first 60 lines), `skills/self-audit-knowledge/SKILL.md` (first 30 lines). Not read: the seven troubleshoot phase files, the seven documentation templates, planning-technique notes 00-10, `lint-candidates.md`, the remaining test scripts. No draft depends on an unread file.

## The understanding problems found

1. **The gate's failure paths are prose only.** What happens on a missed canary, a second miss, an empty evidence directory, or a demoted verdict is spread across `the-design-gate.md`, `GUIDE.md`, and the 1005-line `stage-2-design.md`. A reader reconstructs the retry limit, the "second miss forbids revision" rule, and the exit-code semantics from three places. Drafts V3a and V3b.
2. **Nothing tells a first-time installer what will and will not appear in their project.** The install page explains scopes and updates but not that installation writes nothing into the repository, that hooks only read, or which command creates which folder. Dependency status is scattered across `install.md`, `plugins/toque/README.md`, `METHODOLOGY.md`, and five command files, and the plugin README contradicts the root README on whether Node comes with Claude Code. Drafts V1 and V1b.
3. **Who decides what is split across six stage sections.** The distinction between an executable check (two Node tools), an instruction to the agent, and a named human decision is stated in prose but never laid out per stage. Draft V2, with V7 for the approval tiers.
4. **The component wiring is a bullet list.** Which entrypoints call the agents, which caller runs the gate tools, and that hooks are started by Claude Code rather than by the user is described in `GUIDE.md` and the plugin README's architecture list but never drawn. Draft V4.
5. **The one existing diagram is unreadable at documentation width.** The METHODOLOGY six-stage flowchart measures 1641px at natural size and renders at about 44% in a 760px column, putting its edge labels near 7px. Draft V11 keeps every label and changes only the direction.
6. **The six-stage table exists four times with different gate wording.** `README.md:62-69`, `plugins/toque/README.md:73-80`, `plugins/toque/GUIDE.md:122-130`, and `METHODOLOGY.md:166-173` each carry a version; the plugin README's Test row ("Runbook reviewed by a second person") names one of five manual checks as if it were the gate, and its Build row omits the impact-review confirmation. Finding R11; a prose alignment, not a new visual.
7. **In-session help contradicts the commands it describes.** `help.md:160` lists `docs/audit/` as the location of plan audits, which `quick-audit.md:16` forbids; `help.md:57` gives minute estimates no measurement supports. Finding R5.

## Opportunity register

Priority rubric from the task: High prevents setup mistakes or misunderstanding of gates, ownership, or safety; Medium substantially reduces effort on a recurring workflow; Low improves presentation. Maintenance cost is the number of source files whose change would invalidate the visual.

| ID | Page and section | Reader question | Current difficulty | Action | Format | Evidence | Priority | Maintenance cost |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| V1 | `install.md`, new `## What gets installed, and what gets written` | What does install add, and what appears in my project? | Not stated anywhere; cache versus project is implicit | Add | Table | `hooks.json`, three hook scripts, `SKILL.md:169-176`, `quick-plan.md:9-16`, `plan-export.md:352-371`, `interop.md:5` | High | Low: changes only with a new write location |
| V1b | `install.md`, `## Prerequisites` | Which dependencies are required, optional, conditional? | Two-row table; conditional tools scattered across five command files | Replace | Table | `install.md:104`, `plan-status.md:27-44`, `quick-cleanup.md:184-247`, `plan-export.md:357-369`, `stage-1-plan.md:131-151`, `METHODOLOGY.md:622-631` | High | Medium: tracks each command's fallback |
| V2 | `the-plan-workflow.md`, new `### Reads, writes, and decisions` | Which files does each stage read and create; who approves what? | Split across six stage sections; executable-versus-instruction distinction only in prose | Add | Table | The `Reads:`/`Produces:`/`Gate:` headers of all six stage files; `SKILL.md:62-76` | High | Medium: six stage headers |
| V3a | `the-design-gate.md`, `## 1.` | What happens when the auditor misses the planted defect? | Retry, second-miss stop, and blanket-rejection rule in three places | Add | Mermaid flowchart | `stage-2-design.md:530-581`, `tq-canary.js:178-361` | High | Medium: exit codes and retry count |
| V3b | `the-design-gate.md`, `## 3.` | What happens when evidence is missing or a check fails? | Exit codes, revision limit, and waiver in separate paragraphs | Add | Mermaid flowchart | `stage-2-design.md:583-648,817-988`, `tq-evidence-validate.js:327-366` | High | Medium |
| V4 | `GUIDE.md`, new `## How the pieces connect` | How do commands, skills, agents, hooks, and scripts connect? | Bullet list only | Add | Mermaid flowchart | `quick-plan.md:54-71`, `quick-audit.md:48-54`, `stage-2-design.md:420-591`, `hooks.json`, agent frontmatter | High | Medium: any new caller or callee |
| V5 | `when-to-use.md`, new `## Decide in six questions` | Small change versus larger project: which command? | Table lists commands but not the order of questions | Add | Mermaid flowchart | `when-to-use.md:13-44`, `stage-1-plan.md:25-31` | Medium | Low |
| V6 | `plan-workspace.md`, new `### Status values` | How do I read a reported status when resuming? | Values appear only inside JSON examples and stage files | Add | Mermaid state diagram | `SKILL.md:195-205,283-286`, `stage-1-plan.md:205-219`, `stage-3-build.md:191-193`, `stage-6-maintain.md:62-70` | Medium | Medium: tokens spread across five files |
| V7 | `the-plan-workflow.md`, `### Approval tiers` | What can the agent do without asking? | One dense paragraph | Replace | Table | `SKILL.md:78-85`, `stage-3-build.md:165-174`, `stage-5-deploy.md:100-104` | Medium | Low |
| V8 | `CONTRIBUTING.md`, `## Versioning` | How is a release cut and what refuses it? | Script comments only | Add | Mermaid flowchart | `.github/release.sh:42-194` | Medium | Medium |
| V9 | `CONTRIBUTING.md`, `## Testing` | What does each suite layer check? | "All layers must pass" with no list; runner header lists seven of eight | Replace item 1 | Table | `tests/run-all.sh:5-12,81,90,107-117` | Medium | Medium |
| V10 | `CONTRIBUTING.md`, `## Testing` | What runs in CI? | Only in workflow comments | Add | Table | `.github/workflows/suite.yml`, `.github/protected-artifacts.sh:15-21` | Low | Low |
| V11 | `METHODOLOGY.md`, `### The Six Stages at a Glance` | What decision moves work between stages? | Existing diagram renders at 44% width, edge labels about 7px | Improve (LR to TD, same labels) | Mermaid flowchart | `METHODOLOGY.md:153-162`; no test references the block | Low | Low |
| R1 | `README.md` | What is Toque? | None; tables and images already answer it | Retain; no visual needed | — | Read in full | — | — |
| R2 | `plugins/toque/README.md:121-122,73-80` | Same as README | Node claim contradicts root README and install page; Test and Build gate rows over-simplify | Fix prose; link to V4 from `## Architecture` | — | `README.md:117`, `install.md:16`, `stage-4-test.md:129-146`, `stage-3-build.md:8` | High (prose) | — |
| R3 | `quickstart.md` | First workflow | None; numbered steps are the right format | No visual needed; add one link to V6 | — | Read in full | — | — |
| R4 | `interop.md` table | Which files are read? | Rows are long but the format is a tested contract | Retain unchanged | — | `tests/layer1-repo.sh:1261-1345` | — | — |
| R5 | `help.md:57,160` | In-session help | Unsupported minute estimates; `docs/audit/` listed as plan-audit location | Fix prose; Mermaid not applicable in conversation output | — | `quick-audit.md:16`, `interop.md:35` | Medium (prose) | — |
| R6 | `tests/mutation/README.md` | Harness contract | None | Retain | — | Read in full | — | — |
| R7 | `plan-workspace.md` tree, JSON, four tables | Files and resume | None | Retain | — | Read in full | — | — |
| R8 | `the-plan-workflow.md` testing and assumption tables | Stage contracts | None | Retain | — | `stage-2-design.md:357-369`, `stage-3-build.md:107-127` | — | — |
| R9 | `the-design-gate.md` PNG, `README.md` PNG | Gate concept | Alt text already states "not production authorization" | Retain | — | `the-design-gate.md:8`, `README.md:34` | — | — |
| R10 | `METHODOLOGY.md` historical tables (sections 1, 2, 4, 8, 9) | Why these methods? | Labelled historical; interpretation aids for old records | Retain; do not modernize | — | `METHODOLOGY.md:28-35` scope note | — | — |
| R11 | Four six-stage tables | What each stage needs | Wording drifts; `release.sh` checks versions, not this | Align wording to `GUIDE.md:122-130`; keep README and METHODOLOGY copies, link from GUIDE and plugin README where the reader has the repository | — | `README.md:62-69`, `plugins/toque/README.md:73-80`, `GUIDE.md:122-130`, `METHODOLOGY.md:166-173` | Medium (prose) | — |

No numerical improvement percentages are assigned; nothing here was measured against readers.

## Minimum useful set

Apply these six and the rest can wait: **V1, V1b, V2, V3a, V3b, V4.** Together they answer the setup, ownership, and gate-safety questions that a first-time developer cannot currently answer without opening the stage files. Each has exactly one home; other pages link to it (see the link table at the end of the proposals).

Second tier, worth applying when a page is next edited: V5, V6, V7, V8, V9. Presentation only: V10, V11.

Prose corrections that should travel with the visuals because a diagram next to contradicting text is worse than no diagram: R2 (plugin README Node claim and gate rows), R5 (help.md), R11 (six-stage table wording).

## Pages where existing prose or visuals should remain

- `README.md`: the Without/With table, the six-stage table, and the documentation map already carry the page. The two PNGs have alt text that states the gate's limit. Nothing added.
- `documentation/quickstart.md`: linear steps with commands. A diagram would restate the numbered list.
- `documentation/plan-workspace.md`: the folder tree, the `status.json` example, and the four tables are the right formats; only the status vocabulary (V6) is missing.
- `interop.md`: the reader table is a tested contract. Leave its format alone.
- `METHODOLOGY.md`: every table stays, historical ones included; every heading and anchor stays; only the flowchart direction changes (V11).
- `tests/mutation/README.md` and `plugins/toque/commands/help.md`: tables already fit their readers.

## What this audit does not claim

Drafts describe instructions and executable checks as found in the working tree on September 4, 2026. They do not claim an agent obeys every instruction, that a passing suite proves correctness, or that a recorded release authorization proves a deployment happened. Relationships the sources leave ambiguous are withheld from the diagrams and listed in verification.md.
