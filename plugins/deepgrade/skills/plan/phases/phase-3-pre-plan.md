# Phase 3: PRE-PLAN

Phase file for `/deepgrade:plan`. Loaded by `${CLAUDE_SKILL_DIR}/SKILL.md` when the workflow enters this phase. Do not read ahead to other phase files.

## Contents

- Scope, options analysis, and scope lock
- Confidence brief (required): why, success criteria, timebox
- Confidence brief template
- Cross-plan references
- Entry prioritization and impact classification
- Source credibility and URL verification
- Conflicting evidence
- Confidence falsification (post-scope-lock)
- Anchor ids
- Gate

Question: What should be in scope?

Produce an alignment checkpoint in approach.md:

- Scope: IN list and OUT list
- Options Analysis (REQUIRED): Evaluate minimum 2 approaches before selecting:

  For each option:
  - Name and approach description
  - Pros and cons
  - Risk level (LOW/MEDIUM/HIGH)
  - Rollback complexity (LOW/MEDIUM/HIGH)

  Comparison matrix scoring each option against:
  - Implementation ease, Timeline, Strategic value, Risk profile, Rollback complexity

  Decision Rationale: WHY the selected option won, referencing specific criteria.
  Losing options: document "would revisit if" conditions.

- Approach/Pattern: which pattern and WHY (strangler fig, feature flag, migration, new build, integration)
- Top 3 Risks: each with impact level and mitigation
- Constraints: timeline, team, technology
- Dependencies: internal, external, hard blockers, soft dependencies

Present to user for confirmation. This is the SCOPE LOCK.

CONFIDENCE BRIEF (REQUIRED — written after approach.md, before gate):

WHY THIS EXISTS: Without external evidence backing, plan decisions rest on
the authoring agent's training data alone — which may be outdated, biased, or
hallucinated. Stakeholders reviewing plans cannot distinguish "this is industry
standard" from "this is what the AI made up." The confidence brief solves this
by requiring verifiable external evidence for every significant tool, method,
and pattern choice.

SUCCESS CRITERIA:
- Every HIGH-impact entry has at least one verifiable reference link
- A stakeholder unfamiliar with the plan can read confidence.md and understand
  why the chosen approach is industry-proven (not just "the AI suggested it")
- No fabricated company examples (see SOURCE CREDIBILITY below)

TIMEBOX: The confidence brief should take no longer than the approach.md itself.
- MAX ENTRIES: 10 entries per plan (prioritize by impact). If more than 10
  items are identified, defer LOW-impact items with a note: "Deferred: {item}
  (LOW impact, not blocking scope lock)"
- If entry count exceeds 10, stop and present the top 10 sorted by impact.
  User can request additional entries after scope lock.

Step breakdown (approximate effort per entry):
1. Discovery — scan approach/research/brainstorm for items (~1 min total)
2. Drafting — write "what it is" and "connection to plan" (~1 min per entry)
3. Evidence gathering — search for "who uses it" and references (~2 min per HIGH, ~1 min per MEDIUM)
4. Cross-plan search — check existing confidence.md files (~30 sec per entry)
5. Review — verify URLs for HIGH-impact entries if web tools available (~1 min per HIGH)

If the plan is under timeline pressure, skip steps 4-5 for MEDIUM and LOW
entries and mark them with "[CROSS-PLAN CHECK DEFERRED]" and "[URL VERIFICATION
DEFERRED]". HIGH-impact entries MUST always complete steps 3-5 regardless of
timeline pressure — these entries drive scope lock decisions and cannot be deferred.

After writing approach.md, generate confidence.md — a self-contained knowledge
brief that grounds every tool, method, and pattern choice in external industry
evidence. This file is stakeholder-readable: someone outside the plan should
be able to read it and understand why these choices are solid.

Scan the approach.md, research/findings.md, and brainstorm.md for:
- New dependencies/packages (NuGet, npm, pip, etc.)
- Methodologies or patterns chosen (strangler fig, expand/contract, CQRS, etc.)
- Best practices referenced (DORA metrics, chaos engineering, etc.)
- Frameworks, libraries, or tools introduced

For EACH item found, write an entry in confidence.md using this structure:

```markdown
# Confidence Brief: {Plan Name}
Created: {date} (Phase 3)
Last reinforced: {date} (Phase 5, if applicable)

> This document explains WHY the tools, methods, and patterns in this plan
> are industry-proven choices. Each entry defines what it is, who uses it
> at scale, and why it works — then briefly connects it to this plan.

---

## Dependencies & Tools

### {Package/Tool Name} {version}
**What it is:** {1-2 sentence definition — what the tool does, what problem it solves}

**Who uses it at scale:**
- **{Company 1}** — {how they use it, what scale, what outcome}
- **{Company 2}** — {how they use it, what scale, what outcome}

**Why it works:** {1 paragraph — the engineering reason this tool is effective,
what architectural property it provides, what failure mode it prevents}

**Reference:** [{title}]({url}) ← link to official docs, conference talk, or case study

**Connection to this plan:** {1-2 sentences — why we chose this specifically,
which plan goal it serves}

**Also referenced in:** [{other-plan-name}](../../{other-plan-dir}/confidence.md#{anchor}) ← only if another plan uses the same tool

---

## Methods & Patterns

### {Method/Pattern Name}
**What it is:** {1-2 sentence definition}

**Origin:** {Who created/popularized it — e.g., "Martin Fowler (2004)",
"Netflix engineering team (2011)", "Microsoft Azure Architecture Center"}

**Who uses it at scale:**
- **{Company 1}** — {context and outcome}
- **{Company 2}** — {context and outcome}

**Why it works:** {1 paragraph — the engineering principle, what it optimizes
for, what tradeoff it makes explicit}

**Reference:** [{title}]({url})

**Connection to this plan:** {1-2 sentences linking to specific plan phases or decisions}

**Also referenced in:** [{other-plan-name}](...) ← only if applicable

---

## Best Practices & Standards

### {Practice Name}
**What it is:** {1-2 sentence definition}

**Advocated by:** {Organization or thought leader — e.g., "DORA/Google",
"OWASP", "12-Factor App (Heroku)"}

**Industry evidence:**
- {Specific metric or finding — e.g., "Teams using trunk-based development
  deploy 973x more frequently (DORA State of DevOps 2023)"}

**Why it works:** {1 paragraph}

**Reference:** [{title}]({url})

**Connection to this plan:** {1-2 sentences}
```

CROSS-PLAN REFERENCES:
Before writing each entry, search existing plan folders for confidence.md files:
```bash
find docs/plans/ -name "confidence.md" -exec grep -l "{tool-or-pattern-name}" {} \;
```
If found in another plan, add an "Also referenced in" link. The entry in THIS
file must still be self-contained (full context) — the link is supplemental,
not a replacement for content. A reader should never need to open another
plan's confidence.md to understand this one.

ENTRY PRIORITIZATION:
- HIGH-impact items (core dependencies, primary pattern): full entry with reference link REQUIRED
- MEDIUM-impact items (supporting tools, secondary patterns): full entry, reference link optional
- LOW-impact items (dev tooling, standard practices): shorter entry, no reference link required

Impact classification criteria (rationale REQUIRED for each classification):
- HIGH: item is on the critical path, a wrong choice causes plan failure or rework
  (e.g., primary database, core framework, architectural pattern)
  Rationale example: "HIGH — Markdig is the sole markdown rendering engine; if it
  can't handle our edge cases, the entire doc pipeline fails"
- MEDIUM: item supports the plan but alternatives exist with low switching cost
  (e.g., utility libraries, secondary patterns, testing tools)
  Rationale example: "MEDIUM — YamlDotNet parses config; could swap to SharpYaml
  with ~2 days of work if needed"
- LOW: item is standard practice or dev tooling with no plan-specific risk
  (e.g., linters, formatters, common build tools)

Each entry must include a one-line rationale justifying its impact level.
This prevents gaming: downgrading a critical dependency to MEDIUM to avoid
source verification requirements is visible and reviewable.

SOURCE CREDIBILITY (required for HIGH-impact entries):
Every "Who uses it at scale" and "Industry evidence" claim must be backed by
a verifiable source. Do NOT fabricate company examples.

Source tiers:
- TIER A (preferred): Official docs, conference talks with video/slides,
  published case studies, peer-reviewed papers, DORA/ThoughtWorks reports
- TIER B (acceptable): Reputable blog posts (company engineering blogs),
  GitHub repos with usage evidence, Stack Overflow answers with high votes
- TIER C (flag): Training data recall without a specific URL — mark these as
  "[UNVERIFIED — common knowledge, no primary source found]" so the reader
  knows the claim needs manual verification

HIGH-impact entries MUST have at least one TIER A or TIER B source.
If no verifiable source can be found for a HIGH-impact claim, flag it:
"[SOURCE NEEDED — this claim requires manual verification before scope lock]"

URL VERIFICATION: When ref_read_url, web_search_exa, WebSearch, or WebFetch
tools are available, verify that reference URLs for HIGH-impact entries are
reachable before writing them.
- Prefer ref_read_url for documentation URLs (returns clean markdown, trajectory-aware)
- Use web_search_exa for general web URLs (semantic matching)
- Fall back to WebFetch if MCP tools are not available
If a URL is dead or redirects to unrelated content, downgrade to TIER C and
flag as "[LINK DEAD — needs replacement source]".

CONFLICTING EVIDENCE: If two sources disagree on a claim (e.g., one recommends
a tool, another warns against it), document both perspectives:
"[CONFLICTING] Source A says X. Source B says Y. This plan assumes X because
{rationale}." Let the stakeholder see the tension rather than hiding it.

CONFIDENCE FALSIFICATION (post-scope-lock):
If a confidence entry is later found to be wrong (e.g., a tool doesn't support
a claimed feature, a company example was fabricated, a pattern doesn't apply):
1. Create a Change Record (CR-{N}) documenting what was wrong and the impact
2. Mark the confidence.md entry with: "**FALSIFIED ({date}):** {what was wrong}"
3. Mark downstream artifacts that relied on this claim as WARNING in status.json
4. If the falsified claim was HIGH-impact, trigger a scope review (return to Phase 3)
5. If Build phase is in progress, freeze any tickets that depend on the falsified
   claim until the scope review completes

ANCHOR IDS:
Each entry heading must include a kebab-case anchor for cross-plan linking:
`### YamlDotNet 16.3.0 {#yamldotnet-16}` so other plans can link directly.
When searching for cross-plan references, search for both the tool/pattern
name AND common aliases (e.g., "YAML" for "YamlDotNet", "strangler" for
"strangler fig pattern").

GATE: User confirmation REQUIRED.
"Does this scope look right? [confirm / adjust / back to research]"

On "adjust" -> iterate on the approach.
On "back to research" -> return to Phase 2 (mark research stale if scope changed).

Update status.json, manifest.md.
