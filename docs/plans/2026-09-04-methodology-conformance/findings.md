# Findings and correction decisions

## Outcome and epistemic status

**Observation:** METHODOLOGY.md now distinguishes active instruction, narrow executable checks, conditional inputs, compatibility and retired products. It is not a certification that Toque follows every instruction or current industry practice without gaps. **Result: documentation corrected; overall conformance remains qualified, not an unconditional PASS**, because conflicting shipped instructions and runtime verification gaps remain.

**Repository evidence** is the package inventory, invocation paths and tests in the companion registers. **External evidence** is independently credited in source-audit.md. **Inference** is bounded to those observations. **Recommendations** below are future policy/behavior work and were not applied. **Applied corrections** changed only METHODOLOGY.md; these new audit records are not plugin behavior.

## Pre-edit correction plan and disposition

This plan was presented in the conversation before the methodology rewrite; evidence-supported documentation changes continued automatically. No product-policy choice was silently implemented.

1. **Stale claims:** remove current scanner, scoring, governance, guard, context-budget and CI-generator claims; retain historical grade/formula definitions. Correct the one-page Design checkpoint and critical-test waiver. Applied.
2. **Partial claims:** narrow enforced/guaranteed/proven language; distinguish prompted lint, test structure, canary criterion detection and exact citation checks from semantic correctness. Applied.
3. **Retired material:** label sections 1/2/4/9 and mixed historical paragraphs in 5/6/8/10/11; distinguish active characterization planning from removed generator. Applied without changing old plans.
4. **Missing active methods:** add meaningful reverse findings to existing numbered sections: testing methods, source intake, recovery, compatibility, export, document chains, knowledge capture, troubleshooting/incident feedback and ownership. Applied; see method-level rows.
5. **Citations:** remove Cortex homepage tier claim, correct practitioner titles and official-plugin overclaims, retire deprecated GitLab authority and secondary universal thresholds. Applied.
6. **Primary foundations:** add original/official TDD, BDD, test tools, ADR, provenance, traceability, SRE incident guidance, NIST, DORA metric guide and precise host documentation. Applied, with access and adaptation limits.
7. **Industry gaps:** explicitly distinguish batch test-first from canonical TDD, source integrity from truth, prompted independence from security isolation, and local thresholds from standards. Applied wording; implementation gaps remain.
8. **Conflicts requiring decisions:** record the policy conflicts below rather than choosing an unsupported interpretation or modifying behavior.
9. **Guards:** preserve every existing heading/anchor, numbers 1–12, canonical lint text, gate formula and historical weights; run all eight current suite layers, consistency sweep and separate link/anchor/negative controls. No test edits.

## High-impact observations and applied corrections

| ID | Observation and repository evidence | Applied documentation correction | Residual inference / recommendation |
| --- | --- | --- | --- |
| F01 | Scope said analysis retired, while sections 1/2/4/9 and mixed sections used present tense. Marketplace ships only plugins/toque. | Historical labels throughout; no active grade/scan/autonomy claim. | Old numerical definitions are interpretation aids, not validated measurements. |
| F02 | Stage 2 orchestrates canary and evidence tools; quick-plan/quick-audit do not invoke the full sequence. | Shortcut results explicitly do not establish Design gate PASS. | Owner should choose shortcut semantics or separately authorize implementation work. |
| F03 | Validator checks MET citations, not relevance, complete criterion set, N_A justification or execution. | Enumerate exactly what passes/fails and advisory exit-code behavior. | A valid irrelevant quote or omitted criterion can survive; retain human semantic review limitations. |
| F04 | Canary detects criterion membership; blanket check needs applicable set; classes use syntactic mutations. | Do not claim general auditor accuracy, secrecy or proof of specific-defect recognition. | Assumption-inject adds an unverified row without independently proving HIGH impact; evaluate fixture suitability in real judge trials. |
| F05 | Stage 4 has hard automated/manual gate without critical-test waiver. | Remove waiver claim. | Full agent-run test acceptance remains unverified. |
| F06 | Stage 5 forbids production release but marks Deploy complete and prints Released after authorization. | Authorization/status no longer presented as proof of actual deployment. | Separate completion semantics need owner decision. |
| F07 | Hook registry has three informational events, no PreToolUse blocker. | Project permissions and CI are separately owned; retired guard capabilities clearly historical. | No shipped enforcement of all stage/approval rules. |
| F08 | DORA guide has five metrics; Toque only records local timestamps/incidents. | Correct current definitions and withdraw collector/performance-band claims. | No deployed metrics or outcome evaluation was tested. |
| F09 | Root-cause workflow also offers high-KB-match fix reuse before its phases. | Distinguish past similarity from verified cause; retain containment exception. | Decide whether reuse requires current causal verification. |
| F10 | Local protected-artifact script/suite changes existed before audit, outside package. | Do not treat maintainer CI as consumer plugin immutability. | Preserve all user changes; tests exercise scratch clones, not live consumer gates. |

## Unresolved decisions requiring human ownership

| Decision | Conflicting active evidence | Why not resolved in this documentation task |
| --- | --- | --- |
| D1: shortcut gate contract | commands/quick-plan.md says same gate; quick-plan/quick-audit omit Stage 2 canary/validator orchestration. | Choosing full parity versus explicitly lighter public semantics changes product policy. Methodology states observed limits. |
| D2: test-author ownership | lint-registry.md LINT-18 requires a separate writer; testing-selection guide permits same-agent TDD. | Mandatory separate ownership versus deliberate exception affects review policy. No instruction changed. |
| D3: external input writes | documentation/references/brd-template.md Step 2 requests baseline confidence update; Step 3 and interop require read-only consumption. | Removing or authorizing writes changes the safety boundary. Methodology discloses conflict, never guarantees read-only enforcement. |
| D4: release completion meaning | stage-5-deploy.md Step D stores complete/Released after named authorization, while production execution belongs to a human. | Defining authorization versus observed release state affects lifecycle metrics and handoff. |
| D5: immutable records versus living state | plan skill/technique blanket immutability; Build changes plan.md in the same commit; Maintain updates bookkeeping. | Exact protected paths and legitimate mutations require owner policy; current exceptions are documented. |
| D6: historical-match fix reuse | troubleshoot KB HIGH-match asks whether to reuse prior fix before four phases; Iron Law requires cause first. | Decide whether this is another explicit exception or must await current causal evidence. |

Lower-impact instruction ambiguities are recorded, not escalated as blocking questions: auditor introduction says four while explicitly enumerating five; parallel strategy overlaps 2+ and 3+ thresholds; self-audit examples mix A/B and allow HIGH inference contrary to the skill; old baseline reference says only regressions while active gate requires all applicable criteria. Methodology quotes the concrete active paths and flags these limits. An eligible human-review waiver can skip semantic review; this is existing policy, not a new exception introduced here.

## Traceability and verification gaps

All 78 meaningful active methods have active file references; four additional surface items are excluded implementation details. Historical methods are deliberately not assigned fictitious active implementations. Test links identify structure or synthetic behavior; most prompted end-to-end methods lack live agent compliance tests. Script-level citation/canary/hook fixtures exist and run. Tests do not establish host hook delivery, semantic quality, real production actions, optional external availability, effective redaction, calibrated uncertainty, causal attribution or user identity.

External sources support related foundations where claimed. Exact Toque schemas, gate conjunction, canary design, impact taxonomy, KB weights and review thresholds remain explicitly local choices with no claimed industry-standard origin. Feathers is credited through publisher metadata; inaccessible full text was not represented as reviewed.
