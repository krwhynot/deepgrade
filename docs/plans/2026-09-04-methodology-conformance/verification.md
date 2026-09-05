# Verification

## Scope and results

**Observation:** The pre-edit baseline and post-edit full repository suites both passed all eight requested layers and the existing plan consistency sweep. All runs used the pre-existing working test suite, including the user's uncommitted protected-artifact layer. These are local fixture/structure results, not live Claude Code or production evidence.

Command from repository root on Windows:

```powershell
& 'C:/Program Files/Git/bin/bash.exe' -l tests/run-all.sh
```

The first attempt without a login shell lacked Unix utilities and did not run the suite. The successful baseline and final runs used `-l`. Python's WindowsApps launcher could not start inside the sandbox; approved execution outside the sandbox was used for temporary documentation generation/checks. No dependencies were installed.

| Layer | Subject | Baseline | Final | What it establishes |
| --- | --- | --- | --- | --- |
| 1 | Config/wiring (89 core + 29 repository) | 118 passed | 118 passed | Instruction/registry/reference structure, not agent compliance |
| 2 | Informational hook simulation | 6 passed | 6 passed | Real Node handlers with synthetic host payloads |
| 3 | Fixture lint | 9 passed | 9 passed | Selected fixture detectors outside the plugin |
| 4 | Behavioral smoke | 12 passed, 0 skipped | 12 passed, 0 skipped | Structural tests and extracted shell blocks; no live agent session |
| 5 | Evidence validator | 74 passed | 74 passed | Real module and CLI positive/negative fixtures |
| 6 | Canary | 42 passed | 42 passed | Real injection/detection and recheck fixtures |
| 7 | Release preflight | 8 passed | 8 passed | Maintainer checks on scratch clones, not deployment |
| 8 | Protected artifacts | 20 passed | 20 passed | Maintainer CI script with synthetic committed violations, outside shipped package |
| Sweep | 2026-07-20-plugin-hardening-v5 | PASS | PASS | Existing historical plan consistency script |

All eight layers returned zero failures. Counts are assertions reported by the scripts, not test files or agent trials. The manual `tests/layer7-runtime-proof.sh` is a different surface from suite Layer 7 and was not run; host notice visibility remains unverified. The mutation harness that requires a pristine worktree was not run against the dirty checkout.

## Documentation checks

The temporary standard-library checker compares headings/anchors and formulas with the pre-edit snapshot, resolves local Markdown references, verifies implementation references against `git ls-tree v11.0.1`, checks test paths, and compares every initial file hash except METHODOLOGY.md. Quoted historical links in the claims register are rendered literally so they are not mistaken for current implementation links.

Detailed measured results are appended below after the final run. Markdown anchors use GitHub-style heading slugs and duplicate suffixes, excluding fenced examples. This checks this repository's actual headings; it is not a full CommonMark parser or browser-rendering test.

External links in the final methodology were reopened after the draft change. The source audit records titles, organizations/authors, adjacent-claim support, foundational dates and access limits. NASA's display URL resolved to the official canonical page after a direct-canonical retrieval failed intermittently. No unreachable source was declared dead on that basis. Three original own-repository URLs had browser cache failures; they are recorded as unverified remote links, not independent industry authorities.

## Negative controls

All mutations used strings or a new OS-temporary directory, never a tracked source or historical artifact. Scratch files were removed after the controls.

| Control | Observed result | Interpretation |
| --- | --- | --- |
| Replace an implementation link with a nonexistent validator filename in a text copy | Local-link check rejects it | Removed implementation evidence does not pass the audit link check |
| Rename section 7 in a text copy | Boundary check rejects it | Guard's named section boundary is meaningful |
| Add a retired codebase-scanner path to an inventory copy | Active-surface check rejects it | Retired scanner not counted as active |
| Present lint-registry.md as an executable script | Script-surface classifier rejects it | Prompted lint is not executable enforcement |
| Give LINT-03 a real pinned quote consisting only of `}` | Validator keeps MET | Citation integrity does not establish relevance |
| Supply just that one criterion to the CLI | Exit 0 | Validator does not check expected criterion completeness |
| Change the cited file after pinning | UNMET and EVIDENCE-STALE; CLI exit 1 | Real hash staleness check rejects altered evidence |
| Supply N_A without justification | N_A retained | Applicability justification is outside executable validation |

The last four controls import/run the shipped validator, not a mirrored implementation. A minimal reproduction from the repository root is below; run as a temporary `.cjs` file with Node:

```javascript
const fs = require('node:fs'), os = require('node:os'), path = require('node:path');
const assert = require('node:assert/strict');
const { spawnSync } = require('node:child_process');
const script = path.resolve('plugins/toque/scripts/tq-evidence-validate.js');
const { validateRecord, hashContent } = require(script);
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'toque-doc-control-'));
try {
  const text = '# Fixture\n}\n';
  fs.writeFileSync(path.join(dir, 'fixture.md'), text);
  const record = {
    criterion_id: 'LINT-03', verdict: 'MET',
    evidence: [{ artifact: 'fixture.md', line_start: 2, line_end: 2,
      exact_quote: '}', sha256: hashContent(text) }]
  };
  assert.equal(validateRecord(record, dir).verdict, 'MET');
  fs.mkdirSync(path.join(dir, 'evidence'));
  fs.writeFileSync(path.join(dir, 'evidence/one.json'), JSON.stringify(record));
  assert.equal(spawnSync(process.execPath, [script, path.join(dir, 'evidence'), dir]).status, 0);
  fs.appendFileSync(path.join(dir, 'fixture.md'), 'changed\n');
  assert.ok(validateRecord(record, dir).flags.includes('EVIDENCE-STALE'));
  assert.equal(spawnSync(process.execPath, [script, path.join(dir, 'evidence'), dir]).status, 1);
  assert.equal(validateRecord({criterion_id:'LINT-03', verdict:'N_A'}, dir).verdict, 'N_A');
} finally {
  assert.ok(path.resolve(dir).startsWith(path.resolve(os.tmpdir()) + path.sep));
  fs.rmSync(dir, { recursive: true, force: true });
}
```

## Semantic review and preservation

The complete methodology rewrite was reviewed against the pre-edit working document, not just HEAD, so pre-existing introductory/workflow changes were preserved. All original headings and section numbers remain. Historical formulas and the canonical lint table retain their definitions. Numeric readiness effectiveness claims and unsupported authorizations were withdrawn; named stages remain Plan, Design, Build, Test, Deploy and Maintain.

Searches covered enforce/enforces/enforced, guarantee, prevent, prove/proof, always and never. Retained strong wording is either an explicit workflow instruction, a precisely bounded validator rule, a historical heading retained for compatibility, or a denial of an unsupported guarantee. Each such phrase must be read with its paragraph's scope. Section 9 explicitly distinguishes retired assessment from its new active incident subsection.

The reverse register covers meaningful active methods and labels four presentation/packaging details as excluded. Conditional tools, inputs and template reads are not treated as automatically executed. All reference paths exist; script fixtures do not claim full workflow correctness. No assertion of industry standard, source originality, outcome improvement or safety certification was inferred from plugin prose.

Existing historical plans and all shipped code/instructions remained byte-identical in the initial-versus-final hash comparison. Root README.md changed during the audit outside this task's edit targets; it was re-read and left untouched. This exception means a blanket statement that every unrelated file remained unchanged would be false. No commit, push, deployment, or plugin behavior change was made by this task.

## Final measured checks

The documentation checker reported **22 passing assertions and one preservation exception**. The exception was retained as a failed blanket equality assertion, not silently excluded to obtain a green report.

| Check | Result |
| --- | --- |
| Original headings preserved in order | PASS — 108 original, 113 final; five added subsections |
| Original anchors and numbered sections | PASS — all retained; sections 1–12 unchanged |
| Canonical lint table | PASS — 20 unchanged rule rows |
| Historical weighted composites | PASS — both original formulas retained |
| Design conjunction and version distinction | PASS |
| Local links and anchors in all nine changed/created documents | PASS — zero broken targets |
| Direct package references | PASS — 31 unique linked files exist in published v11.0.1 tree |
| Test references | PASS — seven direct tests exist |
| Method implementation and verification references | PASS — every meaningful method has active evidence and a test reference with scope/gap qualifications |
| Final external-source inventory | PASS — 29 unique sources accounted for and reopened |
| Four structural negative controls | PASS — removed reference, section boundary, retired-component and prompt/executable distinctions detected |
| Five real-validator assertions | PASS — relevance/completeness/N_A limits and stale-source rejection reproduced |
| Package and historical-plan byte preservation | PASS |
| Every unrelated baseline file byte-identical | EXCEPTION — README.md changed during the audit outside this task's edit targets; left untouched |
| Required audit folder shape | PASS — exactly eight requested artifacts |

The broader link sweep of root documentation and shipped Markdown found one template placeholder, `[... ]({url})`, in documentation/SKILL.md. It is an output-template variable, not a literal broken documentation target. No real broken local target was identified in that wider sweep. The changed-document check excludes fenced examples and renders baseline quoted links literally; it does not suppress broken active references.

After the final small source/invocation wording correction, the config/wiring layer was rerun separately. This supplements the completed eight-layer run; no executable or test changed between them. A final `git diff --check -- METHODOLOGY.md` also passed. Temporary mutations never touched tracked files and the validator scratch directory was removed.
