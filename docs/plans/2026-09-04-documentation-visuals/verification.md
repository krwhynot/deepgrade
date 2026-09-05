# Verification

Everything below distinguishes what was run from what was read. "Run" means a command or browser render executed in this session on September 4, 2026; "read" means the source was inspected and the claim inferred from its text.

## Rendering checks (run)

**Method.** `preview.html` embeds the Mermaid source of every draft (extracted from `visual-proposals.md` by a script, so the preview cannot drift from the proposal text) plus the existing METHODOLOGY flowchart. It was served from `127.0.0.1:8765` and opened in Chrome through the browser extension. Mermaid 11 was loaded from `cdn.jsdelivr.net/npm/mermaid@11`, initialized with `securityLevel: "strict"`. Each diagram was parsed with `mermaid.parse` and rendered with `mermaid.render` in five modes: 760px light, 760px dark, 380px light, 380px dark, and 760px light with `htmlLabels: true`. The page reports the SVG's natural `viewBox` width, the scale after `max-width: 100%` fitting, and the smallest label font size multiplied by that scale ("effective font").

**Parse and render:** 8 of 8 diagrams parsed and rendered without error in every mode, including with SVG text labels (`htmlLabels: false`) and HTML labels. `<br/>` line breaks rendered in both label modes; no other HTML, `click`, `style`, or `classDef` is used.

| # | Diagram | Natural size (px) | Scale at 760px | Effective smallest font at 760px | At 380px | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | V3a canary flow | 904 x 636 | 0.79 | 12.7px | 5.9px | Readable at 760; needs zoom on a phone |
| 2 | V3b evidence and PASS flow | 928 x 693 | 0.77 | 12.3px | 5.8px | Readable at 760; needs zoom on a phone |
| 3 | V4 component map (LR) | 983 x 513 | 0.73 | 11.7px | 5.5px | Borderline at 760; needs zoom on a phone |
| 4 | V5 decision flow | 721 x 1104 | 0.99 | 15.9px | 7.5px | Readable at 760 |
| 5 | V6 status state diagram | 592 x 660 | 1.03 | 16.4px | 9.1px | Readable at 760 |
| 6 | V8 release flow | 701 x 1060 | 1.02 | 16.3px | 7.7px | Readable at 760 |
| 7 | V11 six stages, top-down | 374 x 759 | 1.04 | 16.7px | 14.4px | Readable at both widths |
| 8 | Existing METHODOLOGY six stages, left-to-right | 1641 x 101 | 0.44 | 7.0px | 3.3px | Not readable at either width; basis for V11 |

Iterations that shaped the final drafts, all measured the same way: the first V4 with five subgraphs measured 3165px wide (Mermaid places subgraphs side by side); the first V5 with four fan-out questions measured 1637px, the six-question chain without invisible links 1258px (a staircase), and the final chain with `T ~~~ C ~~~ X ~~~ P ~~~ I ~~~ QP` 721px. V3b lost 144px by replacing a diamond with a rectangle and merging two NOT PASS branches into one decision node.

Light and dark themes both rendered; screenshots in `previews/`: `v3-gate-760-light.jpg` (V3a and the top of V3b), `v4-v5-760-dark.jpg` (V4 and the top of V5 in Mermaid's dark theme), `v5-380-light.jpg` (V5 and the top of V6 at 380px).

**Contrast (run, Mermaid's own themes, not GitHub's):** measured from computed styles of the first diagram.

| Theme | Node text on node fill | Edge label text on its background | Edge lines on page | Node border on page |
| --- | --- | --- | --- | --- |
| default (light) | 10.8:1 | 10.3:1 | 12.6:1 | 3.8:1 |
| dark | 10.2:1 | 4.4:1 | 12.6:1 | 11.8:1 |

All text passes WCAG 1.4.3 (4.5:1) except dark-theme edge labels at 4.4:1, a Mermaid dark-theme default rather than anything in the drafts. GitHub substitutes its own theme when it renders, so this figure is an observation, not a finding against the drafts. Non-text contrast (1.4.11, 3:1) passes in both themes. Status is carried by label text (`exit 0`, `STOP`, `PASS`) in every diagram, so colour is never the only cue.

**Not verified:**

- GitHub's live rendering. No branch was pushed and no GitHub page was rendered. GitHub's documentation page on diagrams was opened in the browser and says only that Mermaid renders in Markdown files inside a ```` ```mermaid ```` fence and that the current Mermaid version can be checked with an `info` diagram; it states no limitation on labels, links, or size. GitHub's Mermaid version, its `htmlLabels` setting, and its scale-to-width behaviour are therefore assumed from the local render, not confirmed.
- Invisible links (`~~~`) in V5 require Mermaid 10.2 or later. If GitHub's version is older the last line fails; the proposal says what to delete in that case.
- Screen-reader behaviour of Mermaid SVGs. The text explanation under each draft is the accessible fallback.
- 380px readability: every diagram except V11 falls below 10px effective font at 380px. That is inherent to scaled SVG; the adjacent text explanation is the phone-width fallback.

## Table and link checks (run)

- The six Markdown tables in `visual-proposals.md` have a consistent column count in every row (script over each ```` ```markdown ```` block: 3, 4, 5, 3, 4, and 4 columns; 0 malformed).
- Anchors referenced by the drafts and the link table exist in the working tree (GitHub slug rule applied to headings): `GUIDE.md#the-3-hooks`, `GUIDE.md#evidence-flags`, `GUIDE.md#the-7-document-templates`, `plan-workspace.md#staleness`, `plan-workspace.md#migrating-a-pre-800-plan`, `METHODOLOGY.md#the-six-stages-at-a-glance`, `METHODOLOGY.md#relationship-to-the-ai-native-sdlc-playbook`, `the-design-gate.md#what-this-does-not-prove`, `the-design-gate.md#human-review-and-the-solo-waiver`. Two anchors are new and exist only once their drafts land: `plan-workspace.md#status-values` (V6) and `GUIDE.md#how-the-pieces-connect` (V4).
- Command syntax in the drafts matches the entrypoint list at `plugins/toque/skills/plan/SKILL.md:323-328` and the argument hints in each command file.

## Factual checks

**Run against the shipped scripts** (temporary directory, nothing tracked was touched):

| Control | Observed | Draft it supports |
| --- | --- | --- |
| `tq-canary.js detected` with every applicable criterion UNMET | Prints "This is a miss, not a detection", exit 1 | V3a: blanket rejection is a miss |
| `detected` with the planted criterion in the UNMET set and another criterion MET | "canary FOUND", exit 0 | V3a: exit 0 branch |
| `detected` with the planted criterion absent | "canary MISSED", exit 1 | V3a: exit 1 branch |
| `tq-evidence-validate.js` on an empty evidence directory | "an empty evidence directory is not a pass", exit 2 | V3b: exit 2 branch |
| `tq-evidence-validate.js` on a missing directory | "has not been completed", exit 2 | V3b: exit 2 branch |
| `tq-canary.js inject` on a spec no class can mark | Lists the five classes tried, exit 2 | V3a: "no class applies" branch |

**Read** (line references in each draft's Evidence list): stage headers for V2; hook scripts for V1 and V4; command files for V1b, V4, V5; `release.sh` for V8; `run-all.sh` and `suite.yml` for V9 and V10; stage-2 Part C for V3a and V3b. Every node, edge, and table cell in the proposals cites a working-tree location. Relationship labels use only reads, writes, invokes, runs, validates, and the human-decision wording from the stage files.

**Suite** (run after the audit folder was written): `bash tests/run-all.sh 1` result is recorded at the end of this file.

## Unresolved contradictions and withheld relationships

Nothing below was changed; each item is a decision for the owner or a gap in the sources.

| ID | Sources in conflict | Effect on the drafts |
| --- | --- | --- |
| C1 | `plugins/toque/README.md:121-122` says Node is "the same runtime Claude Code itself needs, so if Claude Code runs, this does too"; `README.md:117`, `documentation/install.md:16`, and `METHODOLOGY.md:625-626` say the two are separate and Node must be checked | V1b follows the three-page majority and the conformance record; R2 asks for the plugin README to be corrected |
| C2 | `plugins/toque/README.md:78` gives the Test gate as "Runbook reviewed by a second person"; `stage-4-test.md:140-144` requires every Tier 1 check and every Tier 2 check, of which runbook review is one of five | V2 follows the stage file; R2 |
| C3 | `plugins/toque/commands/help.md:160` lists `docs/audit/` under "Plan audits"; `commands/quick-audit.md:15-16` says not to create `docs/audit/plan-audit.md`; `interop.md:35` says nothing writes it | V1 states `docs/audit/` is never written; R5 |
| C4 | `help.md:57` gives 30-60 and 5-10 minute estimates; no measurement exists in the repository | Not drawn; R5 |
| C5 | `help.md:41` and `quick-audit.md:59-62` present a PASS/NOT PASS result from quick-audit; `the-design-gate.md:108` and `GUIDE.md:64-65` say the shortcut does not run the full Stage 2 sequence (conformance decision D1) | V5 labels quick-plan "not the full gate" and routes "need this gate" readers to `/toque:plan`; V4 shows quick-audit invoking only the auditor |
| C6 | `commands/quick-cleanup.md:146` writes `intent.md`, but its completion report at line 440 still lists `brainstorm.md`; the 11.0.1 changelog describes this as fixed | V1 names `intent.md`; the stale line is a command-file defect outside this audit |
| C7 | `tests/run-all.sh:5-12` documents seven layers and line 81 accepts only `[1-7]`, while line 90 runs eight by default | V9 documents eight and prints the caveat |
| C8 | `agents/plan-auditor.md:199` says "5 subagents", line 201 says "Deploy 4 specialist reviewers" | Not drawn; already recorded by the conformance audit |
| C9 | `stage-5-deploy.md:126` has the human perform the release, while Step D (lines 130-137) marks Deploy complete and prints "Released" once authorization is recorded (conformance D4) | V2's Deploy row describes the instruction, not the status; V6 does not claim `complete` on Deploy proves a deployment |
| C10 | `stage-2-design.md:530` runs the canary "BEFORE the auditor is spawned"; the revision loop at lines 843-849 requires a fresh auditor but does not say whether a new canary is injected on re-audit | V3b's loop edge returns to evidence validation and is labelled "re-audit"; re-injection is withheld |
| C11 | `stage-2-design.md:804` appends to `docs/planning-techniques/lint-candidates.md`, a path that resolves inside the user's project, while the file ships inside the plugin at `plugins/toque/docs/planning-techniques/`; `GUIDE.md:252` lists it as a project output | Omitted from V1's write-location table because which tree receives the append is ambiguous |
| C12 | Four six-stage tables with different gate wording (`README.md:62-69`, `plugins/toque/README.md:73-80`, `GUIDE.md:122-130`, `METHODOLOGY.md:166-173`); `.github/release.sh` checks version strings in these files but not their content | R11 recommends aligning to the GUIDE wording; no draft duplicates the table a fifth time |

Withheld from every diagram: hook message visibility in the host (the scripts emit JSON; whether Claude Code shows it is a host behaviour the conformance audit also left unverified), agent compliance with any instruction, and any claim that a passing suite proves the workflow correct.

## Limitations

- The audience is a developer encountering Toque for the first time, but no such reader was observed. Priorities are argued from the reader questions in the task and the documentation skill, not measured.
- The audit reads the working tree with uncommitted edits. Line numbers will shift when those edits are committed or revised; each draft's Evidence list names headings as well as lines where the section is long.
- The seven troubleshoot phase files and the seven documentation templates were not read. No draft depends on them; V4's statement that troubleshoot and documentation call no agent rests on `skills/troubleshoot/SKILL.md` (whole file) and `skills/documentation/SKILL.md` (whole file), not on the phase or template files.

## Suite result (run)

`bash tests/run-all.sh 1` from the repository root, after this folder was written: Layer 1 passed with 118 assertions and 0 failures (89 core plus 29 repository, including PH5-052's 12-flag check and INTEROP-1/2), the plan consistency sweep for `2026-07-20-plugin-hardening-v5` passed, and the runner reported `ALL PASSED`. Only layer 1 was run; it is the layer that sweeps documentation and `docs/plans/`, so it is the one this folder could affect. The full eight-layer run was not repeated because no executable, fixture, or shipped file changed.

`git status` after the audit shows the same 18 modified tracked files and the same pre-existing untracked paths as at the start, plus this one new folder. `git diff --stat` on tracked files is unchanged (18 files, 1662 insertions, 2936 deletions).

## Application (run, September 5, 2026)

Applied at the owner's request: V1, V1b, V2, V3a, V3b, V4, and R2. Edits touched `documentation/install.md`, `documentation/the-plan-workflow.md`, `documentation/the-design-gate.md`, `plugins/toque/GUIDE.md`, and `plugins/toque/README.md` only; line numbers quoted elsewhere in this folder refer to the pre-application text.

- The three applied Mermaid blocks were extracted from the pages and compared with the proposals: byte-identical.
- `git diff --check`: clean.
- `bash tests/run-all.sh` (all eight layers): 118, 6, 9, 12, 74, 42, 8, and 20 assertions passed with zero failures; the plan consistency sweep passed; `ALL PASSED`.
- In `plugins/toque/README.md`, the Node paragraph now says a native Claude Code installation does not establish Node is available (C1 closed); the Build and Test gate rows now match `stage-3-build.md:8` and `stage-4-test.md:140-144` (C2 closed); the Architecture section links to the GUIDE map.
- The `install.md` `## Optional inputs` section was reduced to one sentence pointing at the new prerequisites table, as V1b proposed. No commit was made.
