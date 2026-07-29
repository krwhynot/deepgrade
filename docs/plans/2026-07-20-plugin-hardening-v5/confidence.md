# Confidence Brief: Plugin Hardening v5

Created: 2026-07-20 (Phase 3)
Last reinforced: — (pending Phase 5)

> This document explains WHY the tools, methods, and patterns in this plan are industry-proven
> choices. Each entry defines what it is, who uses it at scale, and why it works — then connects
> it to this plan.

**Source discipline applied to this brief.** Every URL below was **fetched and confirmed reachable**
during Phase 2/3 research. Tier A = official vendor documentation or the pattern's primary source.
Tier B = corroborating first-party repository or public issue tracker. Tier C = local inspection or
engineering inference with no fetchable primary source, always marked
**[UNVERIFIED — no primary source]**. No tier has been upgraded, and **no company example appears
that was not stated by a fetched source** — where no verified adopter could be confirmed, the entry
says so rather than inventing one.

Note on canonical host: `docs.claude.com/en/docs/claude-code/*` now **301-redirects** to
`code.claude.com/docs/en/*`. Content was fetched from the redirect targets. Entries cite the
canonical host.

---

## Dependencies & Tools

### `hooks/hooks.json` with exec-form invocation {#hooks-json-exec-form}

**What it is:** The documented default location for a Claude Code plugin's event handlers — a JSON
file at the plugin root — combined with *exec form* (`"command": "bash"`, `"args": [...]`), which
passes each argument without shell tokenization instead of embedding one giant `bash -c '…'` string.

**Who uses it at scale:** Anthropic's own first-party plugins ship hooks from `hooks/` at plugin
root (claude-code repository, Tier B), and `claude plugin init --template hooks` scaffolds exactly
this layout. *No third-party adopter was independently verified — the evidence here is vendor
documentation and first-party usage, not a case study.*

**Why it works:** It collapses two divergent implementations into one testable set of files. Exec
form additionally removes three failure modes at once: it does not require the executable bit (all
eight of this plugin's scripts are committed mode `100644` and would otherwise ship
non-executable), it is the documented recommendation for any hook referencing a path placeholder,
and it pins the interpreter — decisive because `shell` **defaults to `powershell` on Windows when
Git Bash isn't installed**, where every existing `bash -c '…'` string fails outright.

**Reference:** [Claude Code plugins reference](https://code.claude.com/docs/en/plugins-reference) ·
[Hooks reference](https://code.claude.com/docs/en/hooks) ·
[Create plugins guide](https://code.claude.com/docs/en/plugins) (all Tier A, fetched) ·
[anthropics/claude-code plugins README](https://github.com/anthropics/claude-code/blob/main/plugins/README.md) (Tier B)

**Impact: HIGH** — this is the central structural move of the plan (F06/F23, Wave 4). A wrong choice
here means the plugin's entire safety-guard layer either stays orphaned or silently stops loading.

**Connection to this plan:** Decision §3.1. The docs also supply the plan's single most important
migration constraint: with both a `hooks/` folder **and** a manifest `hooks` key present, v2.1.140+
**silently ignores the folder**, warning only in `claude plugin list`. This is why the migration must
be atomic in one commit rather than staged. **Updated v7:** since v4 the *preferred* exec-form
interpreter is `node`, not `bash` (§3.1.0 lane N — the vendor-documented cross-platform pattern:
`"command": "node"` with a bundled script path); the exec-form rationale above carries over unchanged,
and the bash form remains lane B's fallback, selected by gate G0.

---

### `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` path anchoring {#plugin-root-skill-dir}

**What it is:** Placeholder variables that resolve to the plugin's installation directory and to a
skill's own subdirectory. They substitute anywhere in skill and agent content, not just in hook
commands.

**Who uses it at scale:** Documented as the mechanism for "scripts, binaries, and config files
bundled with the plugin." Within this repo, `commands/doc.md:16` is the sole existing correct usage.
*No external adopter verified.*

**Why it works:** A marketplace install copies the plugin into a cache directory, so any bare
relative path resolves against the *user's project*, not the plugin. Anchoring is the only way
bundled content reliably loads after install. `${CLAUDE_SKILL_DIR}` is preferred inside skills
because it survives relocation, whereas `${CLAUDE_PLUGIN_ROOT}/skills/plan/…` breaks if the skill
moves.

**Reference:** [Plugins reference — path substitution](https://code.claude.com/docs/en/plugins-reference) ·
[Skills reference](https://code.claude.com/docs/en/skills) (Tier A, fetched)

**Impact: HIGH** — F16 is exactly this defect: `plan.md:609`, `plan.md:1334`, `codex-challenge.md:25`,
`plan-auditor.md:137` and `plan-scaffolder.md:178` reference bundled frameworks by bare relative
path, so those documents **never load for any installed user**. F12's new phase files would reproduce
the bug if authored the same way.

**Connection to this plan:** Constrains both F16 (Wave 6) and F12 (Wave 7). The docs additionally warn
`${CLAUDE_PLUGIN_ROOT}` changes on update and must not hold state — which is why hook state stays in
temp, not under the plugin root.

---

### `git diff --no-index --exit-code` as a drift gate {#git-diff-drift-gate}

**What it is:** Git's diff command run outside a repository index, comparing two arbitrary paths and
returning a **non-zero exit code when they differ** — turning a content comparison into a pass/fail
CI assertion.

**Who uses it at scale:** A standard Git porcelain behavior; `--exit-code` is documented as making
diff "exit with 1 if there were differences and 0 means no differences," explicitly for scripting.
*No specific organizational adopter verified.*

**Why it works:** It converts a maintenance promise ("remember to sync these files") into an
enforced invariant. Drift stops being something a human must notice and becomes something the test
suite refuses to let pass — which matters because manual sync here has already failed measurably.

**Reference:** [git-diff documentation](https://git-scm.com/docs/git-diff) (Tier A, fetched)

**Impact: MEDIUM** — supports the chosen de-duplication shape, but alternatives exist (a checksum
manifest, or a simple `cmp` loop) at low switching cost.

**Connection to this plan:** Decision §3.3 — the base mechanism behind `tests/layer6-drift-check.sh`
*(renumbered from layer5 in v4; Layer 5 is the codex-challenge suite)*, which enforces that the
standalone bundle is genuinely generated output. Evidence it is needed: **all 9 of 9 technique files
have drifted — 300 differing lines by the pinned `--numstat` measure** *(the 296 figure recorded at
research time is superseded; the delta is itself evidence of unversioned-source drift, R11)*. Since
v5–v7 the gate is more than byte comparison: a blank-line-segmented source inventory, a disposition
ledger with full transform accounting, and semantic checks (§3.3).

---

## Methods & Patterns

### Strangler Fig Application {#strangler-fig}

**What it is:** Incrementally replacing a system by building new components alongside the old ones
and progressively shifting functionality, rather than replacing everything at once. Named for the
strangler fig vine, which grows around its host tree and gradually supplants it.

**Origin:** Martin Fowler, originally ~2003 (article maintained through 2024).

**Who uses it at scale:** Fowler's article documents the pattern as an established response to the
repeated failure of wholesale rewrites, noting such projects have "gone down in flames most of the
time." *The fetched source discusses the pattern generally rather than naming specific companies, so
no adopter is claimed here.*

**Why it works:** It distributes risk across many small replacements instead of concentrating it in
one large one — "since these components are small, there isn't so much risk involved when we
introduce the new software" — while the system stays continuously working and delivering value
throughout. That property is what makes each step independently revertible.

**Reference:** [StranglerFigApplication — Martin Fowler](https://martinfowler.com/bliki/StranglerFigApplication.html)
(Tier A, fetched and verified 2026-07-20)

**Impact: HIGH** — this is the plan's selected execution pattern (§4) and the basis on which Option A
beat Option B in the options analysis.

**Connection to this plan:** Every subsystem is replaced behind a stable interface with the
user-facing surface unchanged: `hooks/hooks.json` supersedes the inline block, `skills/plan/`
supersedes `commands/plan.md` with `/deepgrade:plan` preserved, generated technique files supersede
hand-maintained duplicates. **One adaptation is explicit:** the classic pattern assumes a trustworthy
test suite, and this one covers 2 of 33 target defects — so test additions are folded into each
wave's definition of done rather than trailing it.

---

### Progressive disclosure for agent instructions {#progressive-disclosure}

**What it is:** Structuring instruction content in layers — lightweight metadata always present, a
core body loaded when relevant, and detailed reference files read only when needed — rather than
front-loading everything.

**Origin:** Anthropic, as the core design principle of Agent Skills; described as "a well-organized
manual that starts with a table of contents, then specific chapters, and finally a detailed
appendix."

**Who uses it at scale:** Anthropic's Agent Skills architecture is built on it, and the open Agent
Skills standard codifies the same three-tier layout. *No external adopter independently verified.*

**Why it works:** Here the argument is **correctness, not tidiness**, and this is the single most
decisive fact research produced: skill content enters the conversation once and is never re-read,
and after auto-compaction Claude Code re-attaches only **the first 5,000 tokens of each skill**. A
monolithic 16–19K-token workflow therefore has its later phases *silently discarded mid-session*,
with no error — in precisely the long sessions a 9-phase workflow generates.

**Reference:** [Skills reference — compaction budget](https://code.claude.com/docs/en/skills) ·
[Agent Skills best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) ·
[Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
(all Tier A, fetched)

**Impact: HIGH** — converts F12 from a style finding into a correctness defect, which is what moved it
into scope as a full epic rather than a deferred nicety.

**Connection to this plan:** Decision §3.2 and Wave 7. Also supplies the authoring constraints the new
phase files must obey: under 500 lines, references exactly one level deep (a second hop risks silent
`head -100` partial reads), forward slashes only, and a table of contents on any reference file over
100 lines.

---

### Skills as the successor to slash commands {#skills-over-commands}

**What it is:** The consolidation of Claude Code's two extension formats. A file at
`commands/deploy.md` and a skill at `skills/deploy/SKILL.md` both produce `/deploy` and "work the
same way"; `skills/` is the documented format for new plugins.

**Origin:** Anthropic, documented in the plugin authoring guide and skills reference.

**Who uses it at scale:** The migration is vendor-directed rather than community-observed — the
authoring guide instructs "**Use `skills/` for new plugins**." *No adopter survey verified.*

**Why it works:** Skills carry progressive disclosure, bundled resources, and
`disable-model-invocation`, none of which a flat command file supports, while preserving identical
invocation. Migration is therefore capability-additive at zero user-facing cost.

**Reference:** [Create plugins — directory table](https://code.claude.com/docs/en/plugins) ·
[Skills reference](https://code.claude.com/docs/en/skills) (Tier A, fetched). Corroborated by the
redirect itself: the former slash-commands reference page now **301s to the skills page**.

**Impact: HIGH** — it is why F12's split carries no migration cost for users, which is what made the
option viable against the brainstorm's stated worry about changing how the flagship workflow is
invoked.

**Connection to this plan:** Decision §3.2. `skills/plan/SKILL.md` in a plugin named `deepgrade`
yields `/deepgrade:plan` — byte-identical to today. The plan does **not** migrate the other 16
commands; that stays in the deferred backlog.

---

### MCP tool identifier resolution {#mcp-tool-identifiers}

**What it is:** The `mcp__<server>__<tool>` naming scheme, used as one identifier across permission
rules, `allowed-tools`, subagent `tools`, and hook matchers.

**Origin:** Anthropic, MCP integration in Claude Code.

**Who uses it at scale:** Observed live in this environment across three separately configured
servers. *That is local inspection, not a verified external adopter.*

**Why it works — and why it constrains this plan:** The **server segment is chosen by the installing
user**, so an identifier is not portable across installations. Three distinct prefix shapes for the
same logical tools were observed here (`mcp__claude_ai_Ref_MCP__…`, `mcp__exa__…`,
`mcp__perplexity__…`) — the audit's own preferred fix (`mcp__Ref__…`) fails on the author's machine.
Subagent `tools:` is a hard allowlist that tolerates partial non-resolution *silently*, while
`allowed-tools:` is a one-turn permission grant that "does not restrict which tools are available" —
so unresolvable entries there are inert no-ops.

**Reference:** [MCP in Claude Code](https://code.claude.com/docs/en/mcp) ·
[Sub-agents reference](https://code.claude.com/docs/en/sub-agents) (Tier A, fetched) ·
[claude-code issue #13605](https://github.com/anthropics/claude-code/issues/13605) (Tier B — subagent
MCP inheritance; closed, **fixing release could not be confirmed**)

**Impact: HIGH** — governs F21/F32 and gates all of Wave 2.

**Connection to this plan:** Decision §3.4 — hardcoding is rejected outright as *strictly worse than
omitting* (it buys nothing in an allowlist while manufacturing false confidence). Note
`claude plugin validate` **passes despite unresolvable bare names**, so this class needs a custom grep
guard; CI will never catch it.

**Also referenced in:** [2026-04-03-mcp-research-integration](../2026-04-03-mcp-research-integration/confidence.md#graceful-degradation)
— that plan adopted prose-conditional graceful degradation for MCP research. **This plan deliberately
diverges for the two agent allowlists**, choosing determinism over inheritance whose behavior could
not be verified (U3). The graceful-degradation prose in `skills/mcp-research/` is retained.

---

## Best Practices & Standards

### Semantic Versioning — MAJOR for behavioral incompatibility {#semver-major}

**What it is:** MAJOR.MINOR.PATCH, where MAJOR increments "when you make incompatible API changes."

**Advocated by:** The Semantic Versioning specification (semver.org).

**Industry evidence:** The specification states MAJOR "MUST be incremented if any backward
incompatible changes are introduced to the public API" — and *public API* covers expected behavior,
not merely function signatures. A behavioral change that breaks compatibility requires MAJOR even
with no signature change.

**Why it works:** It gives consumers a single reliable signal for "this release can break you,"
separating risk-bearing upgrades from routine ones.

**Reference:** [Semantic Versioning 2.0.0](https://semver.org/) (Tier A, fetched and verified
2026-07-20)

**Impact: HIGH** — determines the release identity and, through the cache-key mechanism below,
whether this work reaches users at all.

**Connection to this plan:** Decision §3.6. The MAJOR trigger is **not** file relocation — hooks
moving and `plan.md` becoming a skill have no invocation surface. It is **hook semantics changing in
both directions** *(restated in v7 to match the locked owner decision)*: with a real parser the
blocking guards newly deny on malformed payloads; without one they become formally **inactive** (allow
+ loud report) where the old grep fallback pretended to enforce — F24 ships as PARTIAL, publicly
recorded (§3.1.6). Both are backward-incompatible behavior changes. F22 (deny→ask) and F25 (permit
`--force-with-lease`) are loosenings and do not force MAJOR on their own.

**Operationally decisive companion fact (Tier A,
[plugins reference](https://code.claude.com/docs/en/plugins-reference) /
[marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)):** the version *is* the cache
key — "pushing new commits without bumping it has no effect" — and third-party marketplaces have
auto-update **off by default**. Without the bump, this hardening reaches **zero existing users**,
silently.

---

### Agent Skills open standard — bundled directory conventions {#agent-skills-standard}

**What it is:** The open standard behind Agent Skills, defining `scripts/`, `references/`, and
`assets/` as **optional** directories, permitting "any additional files or directories," and
requiring references one level deep with SKILL.md under 500 lines.

**Advocated by:** Originally developed by Anthropic, released as an open standard (agentskills.io).

**Industry evidence:** Claude Code skills explicitly follow the standard; its own supporting-file
examples use flat `reference.md` / `examples.md` plus `scripts/` rather than `references/`.

**Why it works:** A shared layout lets tooling and agents locate bundled material predictably,
while marking the directories optional avoids forcing ceremony on small skills.

**Reference:** [Agent Skills specification](https://agentskills.io/specification) ·
[agentskills.io](https://agentskills.io) · [Claude Code skills](https://code.claude.com/docs/en/skills)
(Tier A, fetched)

**Impact: MEDIUM** — informs structure but no plan decision depends on it; the switching cost of
renaming a directory later is near zero.

**Connection to this plan:** This is the evidence for a **negative** decision — the `resources/` →
`references/`/`assets/` rename was **excluded from scope** (§1 OUT). The directories are optional,
Claude Code's own examples use flat names, and no functional behavior changes. Recording the
reasoning prevents a future audit from re-raising it as an oversight.

---

### Fail-closed defaults for security guards {#fail-closed-guards}

**What it is:** When a security control cannot evaluate its input reliably, it denies rather than
permits.

**Advocated by:** Long-standing general security engineering practice (fail-safe defaults).

**Industry evidence:** **[UNVERIFIED — no primary source]** No authoritative source was fetched for
this entry. It is stated as engineering inference and general practice, not as a cited standard. The
*plan-specific* evidence, by contrast, is directly verified: the grep+sed fallback extractor was run
against a quoted payload during research and **confirmed to fail open**.

**Why it works:** A guard that fails open is worse than no guard, because it advertises protection it
does not deliver — precisely the "false confidence" failure mode this entire plan exists to remove.

**Reference:** *(none — see the [UNVERIFIED] marker above)*

**Impact: MEDIUM** — a bounded implementation decision within F24, not a plan-defining choice. Rated
MEDIUM deliberately so that no unverified claim carries HIGH weight; the concrete failure it
addresses is verified independently of this principle.

**Connection to this plan:** Risk R1 and Wave 4a. **The locked contract (owner decision, round 4) is
narrower than the bare principle** — fail-closed applies only where a real parser (node/jq) evaluated
the input: the three blocking guards then deny on malformed payloads. **A guard that cannot parse does
not enforce at all** — it allows and reports itself as loudly as its lane permits (lanes B/I: static JSON
`systemMessage` per event + the single bash SessionStart warning; lane N: on a node-less host neither guards nor
check can spawn, so the vendor's hook-error notice is the signal — the §3.1.6 lane-qualified contract), because
v3's literal application of this principle ("deny when jq is absent") was a denial-of-service, and v4's raw-payload
compromise was field-blind in both directions. F24 is
therefore PARTIAL by design, recorded in the release notes (§3.1.6). The four informational hooks
stay fail-open. Together with the malformed-payload denials, this is what justifies MAJOR (§3.6).

---

## Deferred entries

Kept under the 10-entry timebox; LOW impact, not blocking scope lock:

- **`.gitattributes` / `text eol=lf`** — accepted into scope (§1) as a one-line mitigation. The
  official Claude Code docs are **silent on line endings**, so any entry would be
  **[UNVERIFIED — no primary source]** Tier C. The concrete local evidence is verified:
  `core.autocrlf=true` with no `.gitattributes`.
- **`shellcheck`** — not in accepted scope, and **not installed** on this host.
- **Options-analysis / evaluator-optimizer methodology** — already documented in
  `docs/planning-techniques/`; not a new choice introduced by this plan.
