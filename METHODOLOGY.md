# Toque Methodology

## The Engineering Methods Behind the Grade

Version 11.0.0 | Research-backed. Battle-tested. Stack-agnostic.

> **Scope note (11.0.0).** This document describes the methods behind two
> products that used to ship together. Only one of them ships from this
> repository now.
>
> - **Toque** (what this repository ships): sections 3, 5, 6, 7, 8, 10, 11.
> - **Codebase analysis** — the report card model, the grade categories, the
>   52-check readiness scan (60 with the conditional Database category) and
>   operational readiness, in sections 1, 2, 4 and
>   9. Those commands were removed in 11.0.0. The sections are kept because the
>   methods are the reasoning several Toque sections build on, but nothing here
>   implements them, and this repository does not say what does.
>
> The sections are not renumbered. Numbering is referenced from specs, plan
> records and a test guard that derives section 7's bounds from its heading, and
> renumbering to tidy a table of contents would invalidate every one of those
> citations to save a reader one line of explanation.

---

## 1. The Report Card Model

### Why Grades Beat Checklists

Most code quality tools give you a binary verdict: pass or fail. That is like grading a student's entire semester with a single thumbs-up or thumbs-down. It tells you nothing about where they excel, where they struggle, or what to work on next.

Toque uses letter grades instead. A codebase gets a grade from A+ to F, just like a school report card. The insight is simple: humans already know how to interpret grades. A "B-" means "you're passing, but there is real room for improvement." An "F" means "stop and fix the fundamentals before doing anything else."

This idea draws from two key sources:

- [Matt Pocock: "Your codebase is NOT ready for AI"](https://www.aihero.dev/how-to-make-codebases-ai-agents-love~npyke) - Pocock identifies 8 principles that make a codebase "AI-lovable," arguing that most teams overestimate their readiness for AI-assisted development.
- [Mark Mishaev: AI Harness Scorecard](https://github.com/markmishaev76/ai-harness-scorecard) - Mishaev's scorecard runs 31 deterministic checks across 5 categories, proving that AI readiness can be measured with numbers rather than opinions.

### The Grading Scale

Toque maps a percentage score (0-100) to a letter grade using the standard academic scale. Each grade carries a specific meaning for AI-assisted development readiness.

```text
                    THE TOQUE SCALE
  ┌─────────────────────────────────────────────────────────┐
  │                                                         │
  │  A+  97-100%  ████████████████████████████████████  EXC │
  │  A   93-96%   ███████████████████████████████████   EXC │
  │  A-  90-92%   ██████████████████████████████████    VG  │
  │  B+  87-89%   ████████████████████████████████      GD  │
  │  B   83-86%   ██████████████████████████████        GD  │
  │  B-  80-82%   ████████████████████████████     ◄── MIN  │
  │  C+  77-79%   ██████████████████████████            BT  │
  │  C   73-76%   ████████████████████████              MED │
  │  C-  70-72%   ██████████████████████                PR  │
  │  D+  67-69%   ████████████████████                  VP  │
  │  D   63-66%   ██████████████████                    FL  │
  │  F    0-62%   ██████████████                        NR  │
  │                                                         │
  │  EXC = Exceptional    GD  = Good         MED = Mediocre │
  │  VG  = Very Good      BT  = Below Target PR  = Poor     │
  │  MIN = Minimum viable VP  = Very Poor    FL  = Failing  │
  │  NR  = Not Ready                                        │
  └─────────────────────────────────────────────────────────┘
```

#### Read the Grade in Four Bands

| Band | Meaning | Best Use of AI |
| :--- | :------ | :------------- |
| **A-range** | The system is organized enough for low-friction autonomy. | Delegate bounded tickets with light review. |
| **B-range** | The system is workable, but risk still needs active human judgment. | Use AI for implementation with normal review discipline. |
| **C-range** | The AI can understand more than it can safely change. | Lean on discovery, tracing, and planning before edits. |
| **D/F-range** | Missing foundations make automation amplify confusion. | Fix docs, tests, and structure before delegation. |

> Visual cue: the chart is not just a score ladder. The B- line is the point where AI shifts from productive collaborator to expensive guesser.

### What Each Grade Means in Practice

| Grade | Score | Readiness Level | What It Means |
| :-----: | :-----: | :---------------- | :-------------- |
| **A+** | 97-100% | Exceptional | AI agents can work autonomously. Context files, tests, docs, and guardrails are all in place. Hand an AI a ticket and walk away. |
| **A** | 93-96% | Excellent | Minor gaps only. An AI agent will occasionally need clarification, but it can navigate the codebase, understand conventions, and make safe changes. |
| **A-** | 90-92% | Very Good | A few improvements needed. The codebase is well-structured but may lack full guardrail coverage or have slightly stale documentation. |
| **B+** | 87-89% | Good | Some gaps to address. AI-assisted development works but hits friction points. Worth investing a sprint to close the gaps. |
| **B** | 83-86% | Above Average | Several improvements needed. The AI can help, but a human needs to double-check more often than you would like. |
| **B-** | 80-82% | Adequate | **Minimum for effective AI-assisted development.** Below this line, the AI spends more time guessing than building. |
| **C** | 73-76% | Mediocre | Many improvements needed. The AI can read the code, but it cannot reliably navigate dependencies or understand business rules. |
| **F** | 0-62% | Not Ready | The codebase is not ready for AI-assisted development. Missing documentation, no guardrails, unclear structure. Fix the foundation first. |

The B- threshold is the most important number in the table. It represents the minimum viable score for productive AI collaboration. Below B-, AI tools generate more confusion than value because they lack the context to make good decisions.

The AI-readiness scan measured a codebase across 8 scoring categories (52 checks), plus a ninth conditional Database category that adds 8 more, computed a weighted percentage, and mapped it to this scale. Toque no longer implements it — see the scope note above. The result is a single letter grade that tells you exactly where you stand.

---

## 2. The Three Grade Categories

### Past, Present, Future

Every codebase exists in three time orientations simultaneously. What was built (past), what condition it is in (present), and whether it can safely evolve (future). Toque organizes its entire assessment around these three questions, and the order is not arbitrary. You cannot assess risk without knowing what exists, and you cannot plan safe changes without understanding risk.

```mermaid
graph LR
    subgraph "PAST"
        C1["Category 1<br/><b>Documentation<br/>as the Foundation</b>"]
    end
    subgraph "PRESENT"
        C2["Category 2<br/><b>Phased Delivery<br/>Over Big-Bang Releases</b>"]
    end
    subgraph "FUTURE"
        C3["Category 3<br/><b>Operational<br/>Readiness</b>"]
    end

    C1 -- "What exists<br/>feeds into" --> C2
    C2 -- "What's risky<br/>feeds into" --> C3

    Q1["What do we have?"] -.-> C1
    Q2["What shape is it in?"] -.-> C2
    Q3["Can we safely change it?"] -.-> C3

    style C1 fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style C2 fill:#F39C12,stroke:#E67E22,color:#fff
    style C3 fill:#2ECC71,stroke:#27AE60,color:#fff
    style Q1 fill:#D6EAF8,stroke:#4A90D9,color:#2C3E50
    style Q2 fill:#FEF5E7,stroke:#F39C12,color:#2C3E50
    style Q3 fill:#D5F5E3,stroke:#2ECC71,color:#2C3E50
```

| # | Category | Question | Time | Core Method |
| :-: | :--------- | :--------- | :----- | :------------ |
| 1 | Documentation as the Foundation | What do we have? | Past | Archaeological dig |
| 2 | Phased Delivery Over Big-Bang Releases | What shape is it in? | Present | Risk classification |
| 3 | Operational Readiness | Can we safely change it? | Future | Production readiness review |

### Category 1: Documentation as the Foundation (Past)

Before AI can help with a codebase, the codebase must be documented. This sounds obvious, but 67% of legacy systems lack reliable documentation (per Replay.build research). That is not a minor gap. It is a structural failure that makes every downstream activity harder.

Category 1 treats documentation as an archaeological dig. The goal is to answer "what do we have?" by producing three artifacts: a feature inventory (what the system does), a dependency map (how the pieces connect), and business rule documentation (why the code behaves the way it does). These are prerequisites for AI-assisted development, not nice-to-haves. Without them, an AI agent is navigating blind.

The method is straightforward. Toque's the codebase audit command deploys specialized scanner agents to find features, trace dependencies, and catalog business rules embedded in code. The output is a structured report that serves as the AI's map of the codebase.

### Category 2: Phased Delivery Over Big-Bang Releases (Present)

Once you know what you have, the next question is "what shape is it in?" Category 2 classifies every module by risk level, because not all code is equally dangerous to change.

Risk in Toque is calculated as **business criticality x dependency exposure**, not just lines of code. A 50-line payment processing function with 25 callers (fan-in > 20) is far more dangerous than a 5,000-line reporting utility that runs in isolation. Modules with fan-in above 20 are flagged as danger zones. Modules with fan-out above 40 are flagged as fragile to external changes.

The delivery method follows from the risk classification. Safe modules get modified first, then medium-risk, then high-risk. Each phase has entry criteria (what must be true before starting), exit criteria (what must be true before moving on), and regression testing requirements. This phased approach replaces big-bang releases with incremental, verifiable progress.

Technical debt is classified into three buckets: **CRITICAL** (must fix before proceeding), **MANAGED** (documented and consciously accepted), and **DEFERRED** (low risk, address when convenient). The classification itself is the insight. Most teams treat all debt the same, which means critical debt gets the same attention as trivial debt. Sorting it makes the work plannable.

### Category 3: Operational Readiness (Future)

Category 3 asks the forward-looking question: can we safely change this codebase? Having documentation (Category 1) and risk assessment (Category 2) is necessary but not sufficient. You also need active safety nets to catch problems as they happen.

This category is modeled on [Google SRE's Production Readiness Review](https://sre.google/sre-book/launching/), the industry standard since 2016. Google's key insight is that production systems need explicit readiness criteria, not just "it works on my machine." Toque adapts this framework for AI-assisted development contexts.

Category 3 produces four deliverables:

```text
  ┌──────────────────────────────────────────────────────────────┐
  │                  OPERATIONAL READINESS                       │
  │                  (Category 3 Deliverables)                   │
  ├──────────────────────────────────────────────────────────────┤
  │                                                              │
  │  3A. GUARDRAIL COVERAGE                                      │
  │  ┌──────────────────────────────────────────────────────┐    │
  │  │ Are automated safety nets installed?                  │    │
  │  │ Pre-commit hooks, CI gates, permission rules for     │    │
  │  │ force push, migration edits, database deploys        │    │
  │  └──────────────────────────────────────────────────────┘    │
  │                                                              │
  │  3B. CONTEXT CURRENCY                                        │
  │  ┌──────────────────────────────────────────────────────┐    │
  │  │ Are docs and baselines fresh or stale?                │    │
  │  │ CLAUDE.md age, audit baseline age, spec freshness,   │    │
  │  │ dependency map currency                               │    │
  │  └──────────────────────────────────────────────────────┘    │
  │                                                              │
  │  3C. TEST SAFETY NET                                         │
  │  ┌──────────────────────────────────────────────────────┐    │
  │  │ Is test coverage adequate for high-risk modules?      │    │
  │  │ Characterization tests for legacy code, integration   │    │
  │  │ tests for cross-cutting paths, regression suites      │    │
  │  └──────────────────────────────────────────────────────┘    │
  │                                                              │
  │  3D. CHANGE READINESS SCORE                                  │
  │  ┌──────────────────────────────────────────────────────┐    │
  │  │ Composite rating: GREEN / YELLOW / ORANGE / RED       │    │
  │  │ GREEN  = Safe to change with AI assistance            │    │
  │  │ YELLOW = Proceed with caution, known gaps             │    │
  │  │ ORANGE = Fix gaps before making changes               │    │
  │  │ RED    = Stop. Foundation work required first.         │    │
  │  └──────────────────────────────────────────────────────┘    │
  │                                                              │
  └──────────────────────────────────────────────────────────────┘
```

### Sources for the Three-Category Framework

- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) - Introduces the concept of combining Context Engineering, Architectural Constraints, and Entropy Management into a unified framework for AI-assisted development.
- [Google SRE Book, Chapter 32: Production Readiness Review](https://sre.google/sre-book/launching/) - Defines the industry-standard checklist for determining whether a system is ready for production traffic, including monitoring, incident response, and capacity planning.
- [Cortex: Production Readiness Checklist](https://www.cortex.io/) - Organizes readiness into tiered levels (Bronze, Silver, Gold) across security, reliability, and observability, making it possible to measure incremental progress.
- [GitLab: Production Readiness Review](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/) - GitLab's internal standard requires "enough documentation, observability, and reliability for production scale" before any service goes live.

The three categories form a dependency chain. You cannot skip ahead. A codebase without documentation (Category 1) cannot have accurate risk classification (Category 2), and a codebase without risk classification cannot have meaningful operational readiness criteria (Category 3). Toque enforces this ordering by requiring earlier categories as inputs to later ones.

---

## 3. The Six-Stage Planning Method

### Design Before Code

The `/toque:plan` command implements a six-stage workflow that takes any starting input (a vague idea, a folder of vendor docs, a Jira ticket, a production incident) and leaves a committed artifact behind at each stage. The chain of artifacts is the audit trail: who asked, what was produced, who approved. The method is inspired by two sources:

- [Anthropic: feature-dev plugin](https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev) - Anthropic's own guided workflow uses 7 phases (Discovery through Execute), demonstrating that AI-assisted development benefits from structured phases with explicit transitions rather than open-ended conversation.
- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) - OpenAI's "design-before-code culture" principle argues that the most expensive bugs are the ones introduced before a single line of code is written.

Every stage answers exactly one question, reads the artifact the stage before it committed, and commits its own. Every stage ends at a gate, and a gate without a recorded human name is not passed. Skipping a stage does not save time. It moves the cost to a later stage where it is more expensive to fix.

> **Before 8.0.0** the same workflow ran as nine phases. Plans started under the old shape still resume: `/toque:plan` and `/toque:plan-status` map the old phase names onto stages — brainstorm + research to plan; pre_plan + plan + audit to design; build + impact_review to build; test to test; handoff to deploy — and the old artifacts keep their old names rather than being rewritten.

### The Six Stages at a Glance

```mermaid
flowchart TB
    S1["1. PLAN<br/><i>What is wanted, why,<br/>under which constraints?</i>"]
    S2["2. DESIGN<br/><i>What exactly will be built,<br/>and does the spec hold up?</i>"]
    S3["3. BUILD<br/><i>How is it implemented, and<br/>what did the change touch?</i>"]
    S4["4. TEST<br/><i>Does it work<br/>safely?</i>"]
    S5["5. DEPLOY<br/><i>Does the diff match the plan,<br/>and who authorizes release?</i>"]
    S6["6. MAINTAIN<br/><i>What did production<br/>teach us?</i>"]

    G1{{"Gate: Product owner<br/>sets Status: Accepted"}}
    G2{{"Gate: Design gate PASS<br/>+ human review"}}
    G3{{"Gate: plan.md approved,<br/>impact review confirmed"}}
    G4{{"Gate: Hard readiness<br/>(automated + manual)"}}
    G5{{"Gate: Named human<br/>authorizes release"}}

    S1 --> G1 --> S2
    S2 --> G2 --> S3
    S3 --> G3 --> S4
    S4 --> G4 --> S5
    S5 --> G5 --> S6

    %% Parallel research tracks in Plan
    S1a["Track A:<br/>Codebase Scan"]
    S1b["Track B:<br/>Source Doc Cleanup"]
    S1c["Track C:<br/>Best Practices"]
    S1 -.-> S1a & S1b & S1c

    %% Build parallelism
    S3a["Batch 1:<br/>Independent tickets<br/>(parallel)"]
    S3b["Batch 2:<br/>Dependent tickets<br/>(after Batch 1)"]
    S3 -.-> S3a --> S3b

    %% The loop closes
    S6 -. "new intent.md" .-> S1

    style S1 fill:#E8F0FE,stroke:#4A90D9,color:#2C3E50
    style S2 fill:#F4ECF7,stroke:#9B59B6,color:#2C3E50
    style S3 fill:#D5F5E3,stroke:#2ECC71,color:#2C3E50
    style S4 fill:#FDEDEC,stroke:#E74C3C,color:#2C3E50
    style S5 fill:#FEF5E7,stroke:#F39C12,color:#2C3E50
    style S6 fill:#EAECEE,stroke:#7F8C8D,color:#2C3E50

    style G1 fill:#fff,stroke:#4A90D9,color:#2C3E50
    style G2 fill:#fff,stroke:#9B59B6,color:#2C3E50
    style G3 fill:#fff,stroke:#2ECC71,color:#2C3E50
    style G4 fill:#fff,stroke:#E74C3C,color:#2C3E50
    style G5 fill:#fff,stroke:#F39C12,color:#2C3E50

    style S1a fill:#D6EAF8,stroke:#4A90D9,color:#2C3E50
    style S1b fill:#D6EAF8,stroke:#4A90D9,color:#2C3E50
    style S1c fill:#D6EAF8,stroke:#4A90D9,color:#2C3E50
    style S3a fill:#D5F5E3,stroke:#2ECC71,color:#2C3E50
    style S3b fill:#D5F5E3,stroke:#2ECC71,color:#2C3E50
```

#### What Each Stage Commits

| # | Stage | Question | Reads | Commits | Gate |
| :-: | ------- | ---------- | ------- | --------- | ------ |
| 1 | **Plan** | What is wanted, why, under which constraints? | idea, docs, ticket, incident | `intent.md`, `research/findings.md` | A named product owner sets `intent.md` Status to Accepted |
| 2 | **Design** | What exactly will be built, and does the spec hold up? | `intent.md` | `spec.md`, `audit.md`, `evidence/` | Design gate PASS, then human review, then `spec.md` Status: Approved |
| 3 | **Build** | How is it implemented, and what did the change touch? | `spec.md` | `plan.md`, code, `changes/CR-*.md`, `impact-review.md` | `plan.md` approved before any code; impact review confirmed |
| 4 | **Test** | Does it work safely? | code, `plan.md` | `test-plan.md`, results | Automated tier passes and the manual tier is confirmed by a human |
| 5 | **Deploy** | Does the diff match the plan, and who authorizes release? | diff, `plan.md`, `intent.md` | `review.md` | Diff-versus-plan acknowledged; a named human authorizes release |
| 6 | **Maintain** | What did production teach us? | incidents, metrics | a new `intent.md` | None. On-call triage, never auto-accepted |

The agent does the generating, verifying, and mechanical work. Humans keep the judgment calls. Stage 6 is the steady state; it never "completes".

#### Read the Six Stages in Three Movements

| Movement | Stages | Mental Model | Why It Matters |
| :--- | :----- | :----------- | :------------- |
| **Frame** | 1-2 | Establish what is wanted, then what will be built and whether the spec survives checking. | Prevents teams from solving the wrong problem, and from building against a spec nobody stress-tested. |
| **Deliver** | 3-4 | Build in batches, scan for ripple effects, then prove it works. | Keeps progress incremental instead of big-bang, and makes completion evidence-based instead of intuitive. |
| **Release and Learn** | 5-6 | Compare the diff to the plan, hand release to a named human, feed production back in. | Catches drift before it ships, and closes the loop instead of ending at deploy. |

> Visual cue: the flowchart is detailed on purpose, but the three movement labels are the memory anchors a reader should retain.

### Stage 1: Plan

**Question:** What is wanted, why, and under which constraints?
**Commits:** `intent.md`, `research/findings.md`
**Gate:** A named product owner sets `intent.md` Status to Accepted

Every plan starts with a problem statement, not a solution. If the input is vague ("we need to fix payments"), the intent interview asks structured questions one at a time, in plain language: What is the problem? Who is affected? Why now? What does success look like? The originator may be a non-engineer, so the interview does not ask for file paths, architecture, or technology choices. Those belong to Design.

The output is an `intent.md` file with the problem, the proposed outcome, the affected users and systems, constraints, out-of-scope items, and open questions. Skipping this stage means building a solution to the wrong problem. That is the most expensive mistake in software engineering, and it compounds through every subsequent stage.

Research runs three parallel tracks alongside the interview:

| Track | What It Does | Tools Used |
| :------ | :------------- | :----------- |
| **Codebase Scan** | Finds all related code in the current project | Grep, Glob, Read |
| **Source Doc Cleanup** | Cleans and structures any provided documents | Read, Write |
| **Best Practices** | Searches for how others solved similar problems | Ref (ref_search_documentation, ref_read_url), Exa (web_search_exa, get_code_context_exa), Perplexity (perplexity_ask), WebSearch, WebFetch |

The three tracks are independent, so Toque runs them as parallel subagents. This is not just a performance optimization. Parallel execution prevents the sequential bias where findings from one track color the interpretation of the next.

Research has no gate of its own. It feeds the Constraints and Open questions sections of `intent.md`, and acceptance by a named product owner is the only exit from the stage. There is a dedicated intent-only mode (`/toque:plan intent {name}`) that runs this stage and stops, so a non-engineer can originate a plan without committing anyone to building it.

### Stage 2: Design

**Question:** What should be in scope, how will we execute it, and what is weak or missing?
**Commits:** `spec.md`, `audit.md`, `evidence/`
**Gate:** Design gate PASS + human review, then `spec.md` Status: Approved

Design is the stage that merges what used to be three phases: pre-plan, plan, and audit. Its single artifact is `spec.md`, written in two passes around a mid-stage scope lock, then audited.

**Part A: scope and design.** Part A produces a one-page alignment checkpoint. One page. Not ten. The discipline of compression forces clarity. The checkpoint contains five elements:

1. **Scope:** IN list and OUT list. If it is not on the IN list, it is not in scope. Period.
2. **Approach/Pattern:** Which architectural pattern (strangler fig, feature flag, migration, new build) and why.
3. **Top 3 Risks:** Each with impact level and mitigation strategy.
4. **Constraints:** Timeline, team size, technology limitations.
5. **Dependencies:** Internal, external, hard blockers, soft dependencies.

The user must explicitly confirm this checkpoint. This is the scope lock. Everything after it operates within the boundaries set here. If scope needs to change later, the stage re-enters Part A and re-locks.

**Part B: verification plan and delivery.** Part B completes `spec.md` with the verification plan (including which testing methodology applies to each deliverable) and the delivery section (sequencing, rollback, what ships when). Detail level scales with risk. High-risk work gets exact file paths, function names, grep patterns, and test requirements. Low-risk work gets goals, scope, and success criteria. Over-specifying low-risk work wastes time. Under-specifying high-risk work causes failures.

**Part C: the design gate.** The audit is a stress test, run by an isolated `plan-auditor` instance that is never told what passing costs. It runs four kinds of check against `spec.md`:

1. **Criterion verdicts:** every applicable criterion gets `MET`, `UNMET`, or `N_A`, each with the evidence it rests on. There is no total, no points field, and no band.
2. **Devil's Advocate:** challenges every assumption. "If this fails in production, what is the most likely reason?"
3. **Codebase Verification:** confirms that file paths, function names, and line numbers referenced in the spec actually exist in the codebase.
4. **Gap Verification:** four structured outputs (Coverage Matrix, Assumption Register, Scenario Matrix, Cross-Cutting Concern Sweep) plus infrastructure verification and the Phase 5 lint rules (see [lint-registry.md](plugins/toque/docs/planning-techniques/lint-registry.md), which owns the set and its size). LINT-11 and LINT-12 run at Phase 7 instead.

A planted canary defect is injected into a copy of the spec before the audit runs, so a lazy audit can be detected rather than trusted. The gate is an expression, not a threshold:

```text
  CANARY_OK   = the criterion the planted defect violates came back UNMET
  EVIDENCE_OK = the evidence validator flagged nothing
  VERIFIED    = every applicable criterion is MET or N_A after validation
  INFRA_OK    = no infrastructure gaps

  PASS = CANARY_OK AND EVIDENCE_OK AND VERIFIED AND INFRA_OK
```

Every term is re-derivable by someone who has the plan folder and did not run the audit. There is no weighted sum, so a strong showing on seven criteria cannot offset a failure on the eighth. If the gate does not pass, an evaluator-optimizer loop revises only the failing sections and re-audits with a **fresh** auditor instance (up to 2 iterations); the revision feedback carries defects and locations, never how near the spec came to passing. After the loop, a human review checkpoint prompts for reviewer sign-off before Build (waivable in solo mode). A spec does not "usably pass with known gaps" — either every applicable criterion is satisfied and evidenced, or the specific ones that are not get named.

### Stage 3: Build

**Question:** How is it implemented, and what else does the change affect?
**Commits:** `plan.md`, code, `changes/CR-*.md`, `impact-review.md`
**Gate:** `plan.md` approved before any code; impact review confirmed to close the stage

Nothing is implemented without an approved `plan.md`. The spec says WHAT and WHY; `plan.md` says exactly WHICH FILES, in WHAT ORDER, and HOW WE WILL KNOW, written for an engineer who never saw the conversation. A hard assumption verification gate (LINT-08) runs before implementation: no HIGH-impact assumption may be unverified unless explicitly waived with documented risk acceptance.

Before writing any code, Toque analyzes the ticket dependency graph from `plan.md` and batches independent tickets for parallel execution.

```mermaid
flowchart LR
    subgraph B1["Batch 1: parallel"]
        A["Ticket A<br/>no deps"]
        B["Ticket B<br/>no deps"]
        C["Ticket C<br/>no deps"]
    end

    subgraph B2["Batch 2: after Batch 1"]
        D["Ticket D<br/>needs A"]
        E["Ticket E<br/>needs C"]
    end

    subgraph B3["Batch 3: after Batch 2"]
        F["Ticket F<br/>needs D + E"]
    end

    A --> D
    C --> E
    D --> F
    E --> F
```

Document actions (updating status, answering questions about the plan) require no approval. Codebase actions (generating code, running tests, creating branches) require explicit per-action approval. This distinction is important: the planning tool should never surprise you by modifying code without asking. When implementation departs from `plan.md`, `plan.md` is updated in the same commit and the departure becomes an immutable change record under `changes/`.

The stage exits through an **impact review**, the check most teams skip and the one that catches the bugs unit tests miss. It scans seven dimensions:

| # | Dimension | What It Catches |
| :-: | :---------- | :---------------- |
| 1 | **Integration Edges** | Callers of changed functions that were not updated |
| 2 | **Cross-Layer Effects** | Schema changes that break queries, API changes that break consumers, UI state changes that affect other screens |
| 3 | **Scale/Performance** | Queries inside loops, N+1 patterns, unbounded memory operations |
| 4 | **Transition-State Behavior** | What happens when old and new code run simultaneously during rollout |
| 5 | **Test Delta** | Tests that existed before but were not updated, new behavior without tests |
| 6 | **String Path References** | Stale file paths in mock statements, config files, and documentation after file moves |
| 7 | **Backward Traceability** | Delivered work that no longer traces back to a requirement in the spec |

The insight is that code changes ripple. A function that "just" changes a return type can break callers in five other modules. Toque runs three parallel subagents over these dimensions — integration and cross-layer, scale and transition-state, test delta and string paths and traceability — then synthesizes the findings and flags HIGH severity issues to resolve before testing.

If scope changes are discovered during build, the plan returns to Design and the scope lock must be re-confirmed. This backward flow is not a failure. It is the system working as designed.

### Stage 4: Test

**Question:** Does it work safely?
**Commits:** `test-plan.md`, results
**Gate:** Hard readiness gate — automated tier passes, manual tier confirmed by a human

`test-plan.md` records a per-deliverable test matrix, the edge cases the plan context prompts, characterization test candidates for changed code, and the testing methodology assigned back in Design (an expand/contract migration, for instance, carries its own checklist). Every criterion is categorized as AUTOMATED or MANUAL, and the two tiers are gated differently: the automated tier must pass, and the manual tier must be confirmed by a human who says so by name.

Before proceeding to Deploy, all of these must be true:

- All critical path tests pass (or are explicitly waived with a documented reason)
- No open P0/P1 defects against this plan
- Characterization baseline captured for any refactored code
- The design gate is recorded as PASS with gap-checked = YES
- Rollback plan has been validated

If any condition fails, the plan stays in Test. There is no override. This is deliberate. A test gate that can be bypassed is not a gate, it is a suggestion.

### Stage 5: Deploy

**Question:** Does the diff match the plan, and who authorizes release?
**Commits:** `review.md`
**Gate:** A named human authorizes release. The skill never runs a deploy command.

Deploy opens with the drift control: a **fresh** subagent, not the one that did the Build, compares `git diff --name-only` against the files `plan.md` said would change and against the constraints `intent.md` recorded. It is run by a new instance on purpose, so the comparison is not biased by memory of why each file changed. Its job is to report, not to judge.

`review.md` collects the diff-versus-plan result, the constraint check, the findings, the release checklist, and the authorization line. That last line is the hard rule of the whole workflow: Toque prepares the release and then stops. A named human authorizes it, and a gate without a recorded name is not passed.

### Stage 6: Maintain

**Question:** What did production teach us?
**Commits:** a new `intent.md` when the trigger rule fires
**Gate:** None. This stage never completes; it is the steady state.

After release the plan folder is the record of what was intended, specified, planned, built, tested, and authorized. Nothing in it is rewritten; new facts go in new files. Incidents against the release are handled by `/toque:troubleshoot --plan {name}`, which writes its log under the plan's `troubleshooting/` folder and links it from the manifest.

When a logged incident is SEV1 or SEV2, or is a recurrence of a known pattern, Stage 6 proposes a new `intent.md` pre-filled from the incident: the root cause becomes the problem, the recommended fix becomes the proposed outcome, the incident scope becomes the affected users and systems. That intent enters Stage 1 and goes through the same acceptance gate as the original. This is what closes the loop between running software and the planning workflow.

### What Skipping Costs You

Every stage exists because skipping it has a known cost:

| Stage Skipped | Typical Consequence |
| :------------ | :------------------ |
| 1. Plan | Build the wrong thing, and rediscover known constraints mid-build |
| 2. Design | Scope creep, ad-hoc execution, missed dependencies, gaps found in production |
| 3. Build | You cannot skip this one |
| 4. Test | Unvalidated changes shipped to users |
| 5. Deploy | Drift between what was planned and what shipped, released by nobody in particular |
| 6. Maintain | Incidents teach nothing, and the same defect comes back as a surprise |

The cost of a skipped stage increases exponentially with distance from the skip. A problem missed in Plan (Stage 1) that surfaces during Test (Stage 4) costs roughly 100x more to fix than catching it at the start. This is not a Toque-specific observation. It is the well-documented cost-of-change curve applied to AI-assisted development workflows.

---

## 4. The AI Readiness Scan (52 Checks, 60 with Database)

### Why 9 Categories, and Why These 9

Most AI readiness advice boils down to "write better docs." That is not wrong, but it is not actionable. Toque replaces that vague guidance with 52 deterministic checks organized into 8 categories — 60 checks across 9 categories when the conditional Database category applies — each measuring a specific dimension of how well an AI agent can read, navigate, and safely modify your codebase.

The 9 categories were not chosen arbitrarily. They emerged from synthesizing five independent research frameworks that each approached the same question from a different angle.

- [Matt Pocock: 8 Principles](https://www.aihero.dev/how-to-make-codebases-ai-agents-love~npyke) found that treating AI "like a constantly arriving new starter" reveals exactly which onboarding signals are missing.
- [Derick Chen: 5 Enterprise Code Smells](https://www.buildwithdc.co/posts/your-code-base-isnt-ready-for-ai/) identified five enterprise code smells that block AI effectiveness: poor structure, distributed logic, unexplained acronyms, missing comments, and documentation living far from code.
- [Shaharia Azam: AI Integration Framework](https://shaharia.com/blog/ai-integration-framework/) proposed a three-layer framework combining quality gates, AI-navigable context, and frictionless workflow into a single readiness model.
- [SuperGok: Agent Readiness Framework](https://supergok.com/agent-readiness-framework/) developed an 8-axis, 5-level maturity model that treats agent readiness as a measurable spectrum rather than a binary state.
- [Basti Ortiz: "Coding Agents as First-Class Consideration"](https://dev.to/somedood/coding-agents-as-a-first-class-consideration-in-project-structures-2a6b) demonstrated that the 40% context window rule and vertical slicing directly determine whether an agent succeeds or fails.

When you overlay these five frameworks, the same themes keep surfacing: identity, context, structure, navigation, conventions, verification, memory, efficiency, and data. Those are the 9 categories.

### The 9 Categories at a Glance

```text
 ┌─────────────────────────────────────────────────────────────────────────┐
 │                     AI READINESS SCAN: 9 CATEGORIES                    │
 ├─────────────────────────────────────────────────────────────────────────┤
 │                                                                        │
 │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │
 │  │ 1. Manifest   │  │ 2. Context   │  │ 3. Structure │                 │
 │  │    Detection  │  │    Files     │  │              │                 │
 │  │    4 checks   │  │   10 checks  │  │   8 checks   │                 │
 │  │  "Who am I?"  │  │ "What do I   │  │ "Can I find  │                 │
 │  │              │  │   know?"     │  │  my way?"    │                 │
 │  └──────────────┘  └──────────────┘  └──────────────┘                 │
 │                                                                        │
 │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │
 │  │ 4. Entry     │  │ 5. Conven-   │  │ 6. Feedback  │                 │
 │  │    Points    │  │    tions     │  │    Loops     │                 │
 │  │   5 checks   │  │   7 checks   │  │   6 checks   │                 │
 │  │ "Where does  │  │ "What are    │  │ "Can I check │                 │
 │  │  it start?"  │  │  the rules?" │  │  my work?"   │                 │
 │  └──────────────┘  └──────────────┘  └──────────────┘                 │
 │                                                                        │
 │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                 │
 │  │ 7. Baseline  │  │ 8. Context   │  │ 9. Database  │                 │
 │  │              │  │    Budget    │  │  (optional)  │                 │
 │  │   4 checks   │  │   8 checks   │  │   8 checks   │                 │
 │  │ "Is there a  │  │ "Am I within │  │ "Can I see   │                 │
 │  │  before?"    │  │  budget?"    │  │  the data?"  │                 │
 │  └──────────────┘  └──────────────┘  └──────────────┘                 │
 │                                                                        │
 └─────────────────────────────────────────────────────────────────────────┘
```

### What Each Category Measures

| # | Category | Checks | What It Measures | Weight (no DB) | Weight (with DB) | Max Pts | Key Source |
| :-: | ---------- | :------: | ------------------ | :--------------: | :----------------: | :-------: | ------------ |
| 1 | **Manifest Detection** | 1.1--1.4 | Can the agent identify the project? Language, framework, dependencies, and purpose. | 15% | 14% | 9 | [Pocock](https://www.aihero.dev/how-to-make-codebases-ai-agents-love~npyke): onboarding signals |
| 2 | **Context Files** | 2.1--2.10 | Does CLAUDE.md exist? Is it well-structured? Does it have commands, conventions, and stack info? | 20% | 18% | 20 | [Chen](https://www.buildwithdc.co/posts/your-code-base-isnt-ready-for-ai/): documentation distance |
| 3 | **Structure** | 3.1--3.8 | Directory naming, co-location, nesting depth, monolith files, module boundaries, token cost per module. | 18% | 17% | 16 | [Ortiz](https://dev.to/somedood/coding-agents-as-a-first-class-consideration-in-project-structures-2a6b): vertical slicing + 40% rule |
| 4 | **Entry Points** | 4.1--4.5 | Can the agent trace where execution begins? Are routes centralized? Are slash commands and agents defined? | 10% | 9% | 11 | [Azam](https://shaharia.com/blog/ai-integration-framework/): frictionless workflow |
| 5 | **Conventions** | 5.1--5.7 | Linter/formatter configs, type safety, pattern consistency, do-not-touch zones, MCP configuration. | 12% | 11% | 13 | [Chen](https://www.buildwithdc.co/posts/your-code-base-isnt-ready-for-ai/): unexplained patterns |
| 6 | **Feedback Loops** | 6.1--6.6 | Tests exist, test runner configured, CI/CD present, pre-commit hooks, Claude Code hooks, test command validation. | 8% | 7% | 11 | [SuperGok](https://supergok.com/agent-readiness-framework/): verification axis |
| 7 | **Baseline** | B.1--B.4 | Machine-readable state files, previous audit results, progress tracking, structured data outputs. | 5% | 5% | 5 | [Azam](https://shaharia.com/blog/ai-integration-framework/): quality gates |
| 8 | **Context Budget** | 8.1--8.8 | Total persistent token overhead, instruction density, rules scoping, progressive disclosure, anti-patterns. | 12% | 11% | 13 | [Ortiz](https://dev.to/somedood/coding-agents-as-a-first-class-consideration-in-project-structures-2a6b): 40% context window rule |
| 9 | **Database** | 9.1--9.8 | Schema-as-code, typed models, migrations, data access layer, MCP connection, seed data, schema docs. | N/A | 8% | 14 | [SuperGok](https://supergok.com/agent-readiness-framework/): data readiness axis |

### Why Context Files Get the Highest Weight

Context Files (Category 2) carries the highest weight at 20% because this is the single category that determines whether the agent even knows what project it is looking at. Without CLAUDE.md, an agent arrives with zero project-specific knowledge. It cannot tell a Next.js marketing site from a Django REST API.

Structure (Category 3) comes second at 18% because even with perfect documentation, an agent that cannot navigate the directory tree will waste its context window searching for things.

Context Budget (Category 8) at 12% reflects a discovery that emerged during development: codebases can have too much AI context. Overloaded CLAUDE.md files and unscoped rules degrade performance just as badly as missing documentation. This category was added in v0.2.0 after observing real projects where bloated context files caused instruction-following failures.

### The Conditional Category

Category 9 (Database) only runs if the codebase actually uses a database. The scanner checks for ORM configs, migration directories, database packages in manifests, connection strings in `.env` files, and SQL files. If none are found, the category returns `not_applicable` and the non-database weight set applies.

This matters because not every project has a database. A CLI tool, a static site generator, or a pure computation library should not be penalized for lacking schema documentation. When the database category is excluded, its 8% weight is redistributed across the remaining categories.

```mermaid
graph TD
    START["Start Scan"] --> PRE{"Database<br/>detected?"}
    PRE -->|Yes| DB["Run all 9 categories<br/>Use DB weight set"]
    PRE -->|No| NODB["Run 8 categories<br/>Use non-DB weight set"]
    DB --> CALC["Calculate weighted composite"]
    NODB --> CALC
    CALC --> GRADE["Assign letter grade<br/>A+ (97-100) to F (0-62)"]

    style START fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style PRE fill:#F39C12,stroke:#E67E22,color:#fff
    style DB fill:#2ECC71,stroke:#27AE60,color:#fff
    style NODB fill:#E74C3C,stroke:#C0392B,color:#fff
    style CALC fill:#9B59B6,stroke:#8E44AD,color:#fff
    style GRADE fill:#1ABC9C,stroke:#16A085,color:#fff
```

### How the Composite Grade Works

Each category produces a percentage: `points_earned / max_points * 100`. The composite score is a weighted average of those percentages using the appropriate weight set. The grade maps to fixed ranges:

```text
  A+  97-100     B+  87-89     C+  77-79     D+  67-69
  A   93-96      B   83-86     C   73-76     D   63-66
  A-  90-92      B-  80-82     C-  70-72     F   0-62
```

The formula with database:

```text
  final = (manifest_pct * 0.14) + (context_pct * 0.18) + (structure_pct * 0.17)
        + (entry_pct * 0.09) + (convention_pct * 0.11) + (feedback_pct * 0.07)
        + (baseline_pct * 0.05) + (budget_pct * 0.11) + (database_pct * 0.08)
```

The formula without database:

```text
  final = (manifest_pct * 0.15) + (context_pct * 0.20) + (structure_pct * 0.18)
        + (entry_pct * 0.10) + (convention_pct * 0.12) + (feedback_pct * 0.08)
        + (baseline_pct * 0.05) + (budget_pct * 0.12)
```

A codebase needs a B- (80%) or above, plus all hard gates passing, to qualify for the Phase 2 deep audit.

### The Gate System: Hard vs. Soft

Not all checks are equal. Eight of the 52 always-on checks serve as gates, split into two tiers that control access to the Phase 2 codebase audit.

```text
 HARD GATES (4)                           SOFT GATES (4)
 Must pass or Phase 2 is blocked          Score penalty + warning only
 ┌────────────────────────────────┐       ┌────────────────────────────────┐
 │ 1.1  Primary manifest exists   │       │ 2.5  CLAUDE.md exists          │
 │ 2.1  Context file exists       │       │ 2.9  CLAUDE.md has commands    │
 │ 4.1  Entry point identifiable  │       │ 3.6  No monolith files >5000   │
 │ 6.1  Test files exist          │       │ 5.6  Do-not-touch zones marked │
 └────────────────────────────────┘       └────────────────────────────────┘
       │                                         │
       ▼                                         ▼
  FAIL any ──► Phase 2 BLOCKED            FAIL any ──► Phase 2 runs with
  entirely. Fix these first.               MEDIUM confidence on affected
                                           modules. Warnings in report.
```

The hard gates represent absolute minimums. Without a manifest (1.1), the agent cannot detect the technology stack. Without a context file (2.1), the agent lacks any project-specific knowledge. Without an entry point (4.1), the feature scanner has no starting location. Without tests (6.1), risk assessment becomes unreliable because there is no way to verify that analysis conclusions are correct.

Phase 2 eligibility follows three paths:

- **ELIGIBLE:** Score >= 80 AND all 4 hard gates pass.
- **ELIGIBLE WITH WARNINGS:** Score >= 70 AND all hard gates pass, but one or more soft gates fail. Phase 2 runs with MEDIUM confidence on affected modules.
- **NOT ELIGIBLE:** Score < 70 OR any hard gate fails.

### Why Gate 3.6 Is Soft

Gate 3.6 (no monolith files over 5,000 lines) might look like it should be a hard gate. After all, monolith files are a serious structural problem. But making it a hard gate creates a circular dependency.

Here is the problem: monolith files are the exact reason you need the Phase 2 audit. The audit produces the refactoring roadmap, identifying which functions to extract, in what order, with what risk. If the audit is blocked until the monolith is already refactored, you have to refactor without a roadmap. That is backwards.

Instead, modules inside monolith files receive MEDIUM confidence in the Phase 2 report, while modules outside receive HIGH confidence. The roadmap gets built. The refactoring happens with guidance rather than guesswork. After refactoring, the next readiness scan shows gate 3.6 passing, the monolith modules get upgraded to HIGH confidence, and the system moves forward.

### Deterministic Scoring

Every check uses explicit bash commands with fixed thresholds. There is no room for agent interpretation. If Check 3.3 (nesting depth) runs `find` and gets a max depth of 8 and an average of 3.2, the score is determined by comparing against fixed cutoffs: max <= 7 AND avg < 4.0 = 2 points, max <= 10 AND avg < 5.0 = 1 point, else 0 points. The agent does not get to decide whether 8 levels of nesting "feels okay."

This determinism is the difference between a grade you can trust and a grade that changes depending on which model runs the scan. Run it twice, get the same number. The scoring rules are baked into each scanner agent as fixed conditional logic, not as guidelines for interpretation.

---

## 5. Context Engineering

### The Most Important Insight

Here is the single most important insight in this entire methodology: from an AI agent's perspective, anything not in-context does not exist. Your codebase could have pristine architecture, 95% test coverage, and beautifully written docs. None of that matters if it never reaches the agent's context window.

Context engineering is the discipline of controlling what enters the agent's context window, in what order, and at what cost. It matters more than code quality for AI-assisted development because the agent's behavior is determined entirely by what it can see during a given session.

### The Context Window Budget

Claude Code operates within a 200,000-token context window. That sounds enormous until you see how much is already spoken for before you type your first message.

```text
 ┌──────────────────────────────────────────────────────────────┐
 │               200,000 TOKEN CONTEXT WINDOW                   │
 ├──────────────────────────────────────────────────────────────┤
 │                                                              │
 │  ┌────────────────────────────────┐                         │
 │  │ System Prompt (~18,000 tokens) │  <-- Claude Code's own  │
 │  │ Tool definitions, safety rules │      instructions        │
 │  │ ~50 built-in instructions      │                         │
 │  └────────────────────────────────┘                         │
 │                                                              │
 │  ┌────────────────────────────────┐                         │
 │  │ Autocompact Buffer (~33,000)   │  <-- Reserved for       │
 │  │ Conversation summary after     │      memory across       │
 │  │ compaction events              │      compactions          │
 │  └────────────────────────────────┘                         │
 │                                                              │
 │  ┌────────────────────────────────┐                         │
 │  │ CLAUDE.md + Rules + Memory     │  <-- YOUR persistent    │
 │  │ (~2,500 - 10,000 tokens)       │      context. THIS is   │
 │  │                                │      what you control.   │
 │  └────────────────────────────────┘                         │
 │                                                              │
 │  ┌────────────────────────────────────────────────────────┐ │
 │  │                                                        │ │
 │  │            REMAINING: Actual Work                      │ │
 │  │            (~139,000 - 147,000 tokens)                 │ │
 │  │                                                        │ │
 │  │  File reads, code generation, tool calls,              │ │
 │  │  conversation history, grep results...                 │ │
 │  │                                                        │ │
 │  └────────────────────────────────────────────────────────┘ │
 │                                                              │
 └──────────────────────────────────────────────────────────────┘
```

The system prompt consumes roughly 15,000 to 20,000 tokens just to give Claude its core instructions, tool definitions, and safety guardrails. The autocompact buffer reserves about 33,000 tokens so that when the conversation grows too long and gets compacted, a summary of what happened survives into the next segment. These are fixed costs you cannot reduce.

That leaves your persistent context as the variable you control: CLAUDE.md, unscoped rules files, auto-memory (CLAUDE.local.md), MCP server tool descriptions, and skill catalogs. This is where bloat kills performance.

### The Instruction Budget

[Tembo: "How to Write a Great CLAUDE.md"](https://www.tembo.io/blog/how-to-write-a-great-claude-md) surfaced a critical constraint: "Even the best frontier models can only reliably follow around 200 distinct instructions." This finding comes from IFScale research by Distyl AI (2025), which benchmarked frontier models on instruction-following at scale and found reliable compliance in the 150 to 200 instruction range.

Claude Code's system prompt already uses about 50 of those instructions. That leaves 100 to 150 instructions for everything you add: CLAUDE.md, unscoped rules, and auto-memory combined.

[Allahabadi.dev: "7 CLAUDE.md Mistakes"](https://allahabadi.dev/blogs/ai/7-claude-md-mistakes-developers-make/) reports that Boris Cherny, the creator of Claude Code, keeps his own team's CLAUDE.md at approximately 2,500 tokens (about 100 lines). That is not minimalism for its own sake. It is precision engineering for the instruction budget.

Toque's context budget scanner (Checks 8.1-8.8) enforces these thresholds:

```text
  Target:  CLAUDE.md under 60 instructions
  Target:  Total persistent instructions under 80
  Warning: Over 120 total instructions (budget approaching ceiling)
  Danger:  Over 150 total instructions (competing with system prompt)
```

```mermaid
graph LR
    subgraph "Instruction Budget (~150-200 total)"
        SYS["System Prompt<br/>~50 instructions<br/>(fixed, non-negotiable)"]
        CLAUDE_I["CLAUDE.md<br/>Target: under 60"]
        RULES_I["Unscoped Rules<br/>Target: under 15"]
        MEM["Auto Memory<br/>Target: under 5"]
    end

    SYS --> CLAUDE_I --> RULES_I --> MEM
    MEM -->|"What remains"| WORK["Available for<br/>in-session directives"]

    style SYS fill:#E74C3C,stroke:#C0392B,color:#fff
    style CLAUDE_I fill:#F39C12,stroke:#E67E22,color:#fff
    style RULES_I fill:#F39C12,stroke:#E67E22,color:#fff
    style MEM fill:#F39C12,stroke:#E67E22,color:#fff
    style WORK fill:#2ECC71,stroke:#27AE60,color:#fff
```

### Nine Anti-Patterns That Waste Context

Toque's context budget scanner (Check 8.8) detects 9 specific anti-patterns that waste persistent context tokens. Each one has a direct mechanism of harm.

| ID | Anti-Pattern | What It Looks Like | Why It Hurts |
| ---- | ------------- | ------------------- | ------------- |
| AP1 | Embedded code blocks over 10 lines | Full function implementations inside CLAUDE.md | Burns tokens on code that belongs in source files. The agent reads source files anyway when it needs them. |
| AP2 | README content duplicated in CLAUDE.md | Copy-pasted project descriptions, setup instructions | Same information loaded twice. README is not auto-loaded, so if it is also in CLAUDE.md, you are paying double for one copy the agent never sees independently. |
| AP3 | Full file contents pasted into CLAUDE.md | Entire config files or type definitions embedded as instructions | Massive token waste. Point to the file instead. Claude can read it on demand with the Read tool. |
| AP4 | Duplicate instructions across CLAUDE.md and rules | Same "ALWAYS use X" appearing in both locations | Redundant instructions compete for attention and create ambiguity about which copy is authoritative. |
| AP5 | Orphan rules (scope patterns matching no files) | A rule scoped to `src/api/**/*.ts` when no such directory exists | Dead rules still consume context when scope pattern evaluation fails open. They add noise without value. |
| AP6 | README used as CLAUDE.md | Imperative AI instructions (ALWAYS, NEVER, MUST) living in README.md with no CLAUDE.md present | [HumanLayer: "Writing a Good CLAUDE.md"](https://www.humanlayer.dev/blog/writing-a-good-claude-md) documents that README.md is NOT auto-loaded by Claude Code. Those instructions are invisible to the agent. |
| AP7 | Linter-enforceable rules in CLAUDE.md | "Always use 2-space indentation," "Use single quotes," "Add trailing commas" | [HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md) puts it plainly: "Never send an LLM to do a linter's job." Linter configs enforce deterministically. CLAUDE.md instructions enforce probabilistically. The linter wins every time. |
| AP8 | Expensive @imports | `@docs/full-api-reference.md` loading a 5,000-line file at session start | @imports load at launch, not lazily. Every imported file adds to startup context cost regardless of whether the session needs that content. |
| AP9 | Unscoped domain rules | A rule about `.tsx` component patterns without `globs:` frontmatter | Unscoped rules load every session. A rule about React components loads when you are editing Python scripts, wasting budget on irrelevant instructions. |

### Progressive Disclosure: The Solution

The fix for context bloat is not deleting instructions. It is restructuring them using progressive disclosure: CLAUDE.md stays small and points to detailed docs that Claude reads only when working in specific areas. Scoped rules (via `paths:` or `globs:` frontmatter in Claude Code) only load when Claude touches matching files.

```mermaid
graph TD
    LAUNCH["Session Start"] --> ALWAYS["Always Loaded<br/>(minimize this)"]
    ALWAYS --> CM["CLAUDE.md<br/>(~60 instructions, ~2.5K tokens)"]
    ALWAYS --> UR["Unscoped Rules<br/>(universal policies only)"]
    ALWAYS --> MEM["CLAUDE.local.md<br/>(auto-memory)"]

    CM -->|"Points to"| DETAIL["Detailed Docs<br/>(read on demand)"]
    DETAIL --> D1["docs/architecture.md"]
    DETAIL --> D2["docs/database-schema.md"]
    DETAIL --> D3["docs/api-conventions.md"]

    LAUNCH --> TRIGGERED["Loaded on Demand<br/>(scope this)"]
    TRIGGERED --> SR["Scoped Rules<br/>(globs: or paths: frontmatter)"]
    TRIGGERED --> CHILD["Child CLAUDE.md<br/>(in subdirectories)"]
    TRIGGERED --> SKILL["Skills<br/>(invoked by commands)"]

    SR -->|"Only when touching<br/>matching files"| FILES["src/api/**/*.ts<br/>src/components/**/*.tsx"]

    style LAUNCH fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style ALWAYS fill:#E74C3C,stroke:#C0392B,color:#fff
    style CM fill:#F39C12,stroke:#E67E22,color:#fff
    style UR fill:#F39C12,stroke:#E67E22,color:#fff
    style MEM fill:#F39C12,stroke:#E67E22,color:#fff
    style TRIGGERED fill:#2ECC71,stroke:#27AE60,color:#fff
    style SR fill:#27AE60,stroke:#1E8449,color:#fff
    style CHILD fill:#27AE60,stroke:#1E8449,color:#fff
    style SKILL fill:#27AE60,stroke:#1E8449,color:#fff
    style DETAIL fill:#D5F5E3,stroke:#2ECC71,color:#2C3E50
    style D1 fill:#EAF2F8,stroke:#4A90D9,color:#2C3E50
    style D2 fill:#EAF2F8,stroke:#4A90D9,color:#2C3E50
    style D3 fill:#EAF2F8,stroke:#4A90D9,color:#2C3E50
    style FILES fill:#EAF2F8,stroke:#4A90D9,color:#2C3E50
```

Child CLAUDE.md files in subdirectories are lazy-loaded, meaning Claude only reads them when it reads or writes files in that subdirectory. They act like on-demand skills for subdirectory-specific conventions. For monorepos, child CLAUDE.md files are the right tool. For single-package projects, scoped rules files in `.claude/rules/` with `paths:` frontmatter are usually the better fit.

### The Three-Tier Context Model

[Steven Poitras: Three-Tier Context System](https://agenticthinking.ai/blog/three-tier-context/) proposed a layered context architecture that maps well to how Toque thinks about context levels. [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) makes a similar distinction between static context (docs, AGENTS.md) and dynamic context (CI status, directory mapping), showing that the tier model is converging across the industry.

Toque synthesizes these into a practical model:

```text
 TIER 1: ALWAYS LOADED (minimize this)
 ├── CLAUDE.md (core instructions, under 60 directives)
 ├── Unscoped .claude/rules/ files (universal policies)
 └── CLAUDE.local.md (auto-memory from previous sessions)

 TIER 2: CONDITIONALLY LOADED (scope this)
 ├── Scoped rules (globs: / paths: frontmatter)
 ├── Child CLAUDE.md (subdirectory-specific, lazy-loaded)
 └── Skill content (loaded when commands invoke them)

 TIER 3: ON-DEMAND (point to this)
 ├── docs/architecture.md (Claude reads when relevant)
 ├── docs/schema.md (Claude reads when touching database code)
 ├── docs/api-conventions.md (Claude reads when working in API layer)
 └── Previous audit reports (Claude reads for historical context)
```

The principle is simple: the less you load by default, the more room the agent has for the actual work. A CLAUDE.md that tries to be comprehensive is a CLAUDE.md that competes with the code Claude is trying to read.

### Why Bloat Kills Performance

The mechanism is not mysterious. Every token of persistent context consumes attention that could go toward understanding the code the developer actually asked about. When CLAUDE.md is 500 lines of instructions, the agent is processing 500 lines of "how to behave" before it even looks at the file you asked it to modify.

[HumanLayer: "Writing a Good CLAUDE.md"](https://www.humanlayer.dev/blog/writing-a-good-claude-md) points out that Claude Code wraps CLAUDE.md content with a caveat that it "may or may not be relevant" to the current task. The agent is already treating your persistent context as potentially disposable. Write it accordingly: high-signal, low-volume, and structured so the most important instructions come first.

The worst case is not too little context. It is too much irrelevant context. A lean CLAUDE.md with 40 precise instructions outperforms a bloated one with 200 instructions that the agent partially ignores because it cannot reliably track them all. Toque's Context Budget category (Category 8) exists specifically to catch this failure mode before it degrades your AI-assisted development experience.

---

## 6. Defense-in-Depth Safety

### Why One Guard Is Not Enough

A single safety mechanism has a single failure mode. If your only protection against accidental data loss is a pre-commit hook, and that hook has a bug, your protection is zero. Defense-in-depth solves this by stacking multiple independent layers so that a failure in any one layer is caught by the next.

This is not a new idea. It comes from military strategy and was adopted by information security decades ago. Toque applies the same principle to AI-assisted development: an AI agent should not be able to do something destructive even if one safety mechanism fails.

### The Three Layers

Toque implements safety in three concentric layers. Each layer operates independently. Each layer catches a different class of mistake. The outermost layer is fully automatic. The innermost layer requires a human.

```text
 ┌─────────────────────────────────────────────────────────────────────┐
 │                                                                     │
 │  LAYER 1: PERMISSION RULES (automatic, deterministic)              │
 │  ┌───────────────────────────────────────────────────────────────┐  │
 │  │                                                               │  │
 │  │  LAYER 2: CI/CD PIPELINE (automatic, environment-gated)      │  │
 │  │  ┌─────────────────────────────────────────────────────────┐  │  │
 │  │  │                                                         │  │  │
 │  │  │  LAYER 3: PLAN WORKFLOW (human-in-the-loop)            │  │  │
 │  │  │                                                         │  │  │
 │  │  │  Phase 5: Audit + evaluator-optimizer loop + review     │  │  │
 │  │  │  Phase 7: Impact Review checks cross-cutting concerns  │  │  │
 │  │  │  Phase 6: Assumption gate + Phase 8: Test gate         │  │  │
 │  │  │                                                         │  │  │
 │  │  └─────────────────────────────────────────────────────────┘  │  │
 │  │                                                               │  │
 │  │  PR validates against dev branch                              │  │
 │  │  Manual gate for production deploy                            │  │
 │  │  Advisory mode for first 2 weeks, then blocking               │  │
 │  │                                                               │  │
 │  └───────────────────────────────────────────────────────────────┘  │
 │                                                                     │
 │  settings.json deny: force push, direct DB deploy                  │
 │  settings.json ask:  hard reset, migration edits, git push         │
 │  (the toque-guard hook plugin that filled this layer           │
 │   from 5.0.0 to 8.x was retired in 9.0.0; history below)           │
 │                                                                     │
 └─────────────────────────────────────────────────────────────────────┘
```

The beauty of this arrangement is redundancy. An AI agent that somehow bypasses the permission rules (Layer 1) still hits the CI pipeline (Layer 2). A change that clears CI still goes through human review in the plan workflow (Layer 3). No single failure is catastrophic.

### Layer 1: Permission Rules

Layer 1 is whatever stops a dangerous tool call before it runs, with no human attention and no judgment call by the model. Since 9.0.0 Toque fills this layer with Claude Code's own permission rules rather than with a plugin. A `deny` entry refuses the command outright; an `ask` entry turns it into a confirmation prompt. They live in the project's or the user's `settings.json`, need no runtime, and cannot disagree with a project's own choices the way a second enforcement layer can.

The recommended baseline, which a project adjusts to its stack:

```json
{
  "permissions": {
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f *)",
      "Bash(supabase db push*)",
      "Bash(prisma migrate deploy*)",
      "Bash(dotnet ef database update*)",
      "Bash(flyway migrate*)",
      "Bash(rails db:migrate*)"
    ],
    "ask": [
      "Bash(git push*)",
      "Bash(git reset --hard*)",
      "Edit(supabase/migrations/**)",
      "Edit(prisma/migrations/**)",
      "Edit(db/migrate/**)"
    ]
  }
}
```

`--force-with-lease` is not matched by the deny rules above and stays allowed, which is the correct behavior: it is the safe form. `--dry-run` and `--local` variants of the deploy commands need their own `allow` entries if a project uses them, because a deny rule wins over a wildcard allow.

**Why the plugin was retired.** From 5.0.0 through 8.x this layer shipped as `toque-guard`: five Node hooks (force-push and hard-reset guard, migration guard, DB deploy guard, change and test trackers, session summary). The guards worked and were tested to a corpus of falsifying cases, but three things argued against keeping them. Permission rules had reached parity for every blocking behavior, with zero runtime dependency and no hook-error failure mode. Projects that already carried their own `ask` rules for the same paths ended up with two layers disagreeing, and the block always won silently over the project's deliberate choice. And the trackers, the part permission rules cannot replace, were nudges that the planning plugin's own stage gates and the audit plugin's staleness checks already cover. The historical description follows for the record; the fail-closed principle it established still governs any blocking hook that is ever added back.

#### Historical: the toque-guard hooks (5.0.0 to 8.x)

The hooks were declared in the plugin's `hooks/hooks.json` and executed as Node scripts under its `scripts/`, one file per handler.

```mermaid
graph TD
    ACTION["Claude wants to<br/>run a tool"] --> PRE{"PreToolUse<br/>hook fires"}

    PRE -->|"Write or Edit"| MIG{"Migration<br/>guard"}
    MIG -->|"Existing migration file"| BLOCK1["BLOCKED<br/>exit 2"]
    MIG -->|"Not a migration"| ALLOW1["Allowed"]

    PRE -->|"Bash"| GIT{"Git guard +<br/>DB deploy guard"}
    GIT -->|"git push --force"| BLOCK2["BLOCKED"]
    GIT -->|"git reset --hard"| BLOCK3["BLOCKED"]
    GIT -->|"supabase db push<br/>(no --dry-run)"| BLOCK4["BLOCKED"]
    GIT -->|"Normal command"| ALLOW2["Allowed"]

    ALLOW1 --> POST{"PostToolUse<br/>hook fires"}
    ALLOW2 --> POST

    POST -->|"Write or Edit"| TRACK1["Change tracker<br/>increments count"]
    POST -->|"Bash (test/build)"| TRACK2["Test/build tracker<br/>writes timestamp"]

    STOP["Session ends"] --> SUMMARY["Stop hook reports<br/>files changed +<br/>test warning if needed"]

    style ACTION fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style BLOCK1 fill:#E74C3C,stroke:#C0392B,color:#fff
    style BLOCK2 fill:#E74C3C,stroke:#C0392B,color:#fff
    style BLOCK3 fill:#E74C3C,stroke:#C0392B,color:#fff
    style BLOCK4 fill:#E74C3C,stroke:#C0392B,color:#fff
    style ALLOW1 fill:#2ECC71,stroke:#27AE60,color:#fff
    style ALLOW2 fill:#2ECC71,stroke:#27AE60,color:#fff
    style TRACK1 fill:#F39C12,stroke:#E67E22,color:#fff
    style TRACK2 fill:#F39C12,stroke:#E67E22,color:#fff
    style SUMMARY fill:#9B59B6,stroke:#8E44AD,color:#fff
```

Seven hooks ran as part of Layer 1:

**Force push guard** (`scripts/tq-git-guard.js`, PreToolUse:Bash). Blocks `git push --force` and the bare `-f` form. Force pushes rewrite shared history and can destroy other people's work. Use `--force-with-lease` if you truly need it — the guard genuinely does not block that, which was untrue before v5.0.0: the old pattern matched `--force` inside `--force-with-lease`, so the safe form was denied and the short form was not.

**Hard reset guard** (`scripts/tq-git-guard.js`, PreToolUse:Bash). Prompts for confirmation on `git reset --hard` rather than blocking it. A hard reset permanently discards all uncommitted changes, but it is also a legitimate operation, so the guard asks instead of refusing. Before v5.0.0 it denied outright, and the explanation was written to a channel that is never displayed.

**Migration guard** (`scripts/tq-migration-guard.js`, PreToolUse:Write|Edit). Blocks edits to existing migration files. Modifying an applied migration can corrupt databases. The correct action is always to create a new migration. New migration files are allowed; only edits to existing ones trigger the guard.

**DB deploy guard** ([`plugin.json` PreToolUse:Bash](plugins/toque/.claude-plugin/plugin.json)). Blocks direct database deploy commands (`supabase db push`, `prisma migrate deploy`, `dotnet ef database update`, `flyway migrate`, `rails db:migrate`) unless the command includes `--dry-run`, `--local`, `RAILS_ENV=test`, or `RAILS_ENV=development`. As [Supabase: Managing Environments](https://supabase.com/docs/deployment/managing-environments) puts it: "Use a CI/CD pipeline rather than deploying from your local machine."

**Change tracker** ([`plugin.json` PostToolUse:Write|Edit](plugins/toque/.claude-plugin/plugin.json)). Counts file changes per session by incrementing a counter in `/tmp/tq-baseline-{session}`. When the count crosses a configurable threshold (default: 15), it suggests running a delta scan. This is a nudge, not a blocker.

**Test/build tracker** ([`plugin.json` PostToolUse:Bash](plugins/toque/.claude-plugin/plugin.json)). Silently records timestamps when test or build commands run. Recognizes test and build commands across Node (jest, vitest, npm test), Python (pytest), .NET (dotnet test/build), Rust (cargo test/build/check), and Go (go test/vet). The Stop hook and Git Guard read these timestamps to know whether tests ran.

**Session summary** ([`plugin.json` Stop](plugins/toque/.claude-plugin/plugin.json)). Reports the total file change count when a session ends. If files were changed but no tests ran (and the project has tests), it warns you. This is always informational; Stop hooks must use exit 0 to avoid infinite re-trigger loops.

### The Fail-Closed Principle

This principle outlived the plugin that first embodied it. Permission rules are fail-closed by construction: a `deny` needs no parser, so there is no malformed input that could let a command through. Any blocking hook added in future is held to the same standard.

Guards (migration, force push, hard reset, DB deploy) were fail-closed: if the hook cannot parse its input, it blocks the action. It is better to incorrectly block a safe action than to incorrectly allow a dangerous one.

Trackers (change counter, test/build tracker) are fail-open: if the hook cannot parse its input, it silently does nothing. Missing a count is harmless. Blocking legitimate work because a counter failed is not.

```text
  ┌─────────────────────────────────────────────────┐
  │              FAIL-CLOSED vs FAIL-OPEN            │
  ├──────────────────────┬──────────────────────────┤
  │    GUARDS            │    TRACKERS              │
  │    (fail-closed)     │    (fail-open)           │
  ├──────────────────────┼──────────────────────────┤
  │ Force push guard     │ Change counter           │
  │ Hard reset guard     │ Test tracker             │
  │ Migration guard      │ Build tracker            │
  │ DB deploy guard      │ Session summary          │
  ├──────────────────────┼──────────────────────────┤
  │ If in doubt: BLOCK   │ If in doubt: ALLOW       │
  │ exit 2               │ exit 0                   │
  │ Protects data        │ Protects workflow         │
  └──────────────────────┴──────────────────────────┘
```

### Layer 2: CI/CD Pipeline

Layer 2 catches problems at the pull request level, after code leaves the developer's machine. The recommended setup validates PRs against a dev branch, with a manual gate for production deploys.

For teams adopting Toque on an existing codebase, the CI pipeline runs in advisory mode for the first two weeks: it reports findings but does not block merges. After two weeks, it switches to blocking mode. This ramp-up period prevents the "new tool blocks everything on Day 1" frustration that kills adoption.

The pipeline is generated by the CI gate generator, which produces GitHub Actions workflows, pre-commit configs, and supporting scripts based on your actual audit findings. It does not generate a generic template. It generates gates specific to what your scan discovered.

### Layer 3: Plan Workflow

Layer 3 is where a human stays in the loop. The [`/toque:plan`](plugins/toque/skills/plan/SKILL.md) command's six-stage workflow carries four safety-critical checkpoints:

**Stage 2 (Design gate)** audits the spec across the 8 review dimensions and returns a per-criterion verdict — MET, UNMET, or N_A — with the evidence each rests on. There is no total and no band. The gate passes only when every applicable criterion is MET or N_A, the evidence validator flags nothing, the planted canary defect was caught, and infrastructure verification reports no gaps. The audit runs the registry's Phase 5 lint rules (LINT-11/12 run at Phase 7), 4 gap verification matrices (coverage, assumptions, scenarios, cross-cutting), infrastructure verification (LINT-15/16), and a devil's advocate challenge. If any applicable criterion is unmet, an evaluator-optimizer loop revises the failing sections and re-audits with a fresh auditor instance (up to 2 iterations). A human review checkpoint follows before Build entry.

**Stage 3 (Build)** has a hard assumption verification gate (LINT-08). No HIGH-impact assumption can be unverified unless explicitly waived with documented risk acceptance. This prevents building on unverified foundations.

**Stage 3 exit (Impact Review)** checks seven cross-cutting dimensions: integration edges, cross-layer effects, scale/performance, transition-state behavior, test delta, string path references, and backward traceability. Three parallel subagents scan these dimensions independently. This is the check that catches the bugs unit tests miss: callers that were not updated, queries inside loops, stale file paths in mock statements.

**Stage 4 (Test)** has a hard readiness gate. All critical path tests must pass, no open P0/P1 defects, characterization baselines captured for refactored code, the design gate recorded as PASS with gap-checked = YES, and rollback plan validated. If any condition fails, the plan stays in Test. There is no override.

### The Single-Dependency Principle

The three plan-context hooks that remain in `toque`, and the two design-gate tools beside them, declare exactly one dependency: **Node.js 18 or later**, which Claude Code itself already requires. There is no `jq`, no POSIX utility chain, and no fallback ladder.

That is a deliberate reversal of the earlier zero-dependency design, and it is worth being precise about why. The old hooks avoided dependencies by parsing JSON with `grep` and `sed`. That is not a parser, and the difference is not academic — it produced a guard that could not distinguish a command from text mentioning one, so it blocked a read-only `grep` whose search pattern named a deployment, and blocked commit messages that merely referred to a force push. Availability was traded for correctness in a security control, which is the wrong trade.

Node gives real `JSON.parse`, so a named field can be extracted rather than guessed at. The cost is honest and stated: on a host without Node the guards cannot spawn at all, which Claude Code reports as a hook error. Absent and loud, never silently degraded.

```text
  ┌──────────────────────────────────┐
  │ Hook receives JSON from stdin    │
  └──────────────┬───────────────────┘
                 │
         ┌───────▼────────┐
         │  Is jq          │
         │  installed?     │
         └───┬─────────┬───┘
             │ YES     │ NO
             v         v
  ┌──────────────┐  ┌─────────────────┐
  │ Parse with   │  │ Parse with      │
  │ jq -r       │  │ grep + sed      │
  │ ".field"     │  │ pattern match   │
  └──────┬───────┘  └────────┬────────┘
         │                   │
         └───────┬───────────┘
                 │
         ┌───────▼────────┐
         │ Execute guard   │
         │ or tracker      │
         │ logic           │
         └────────────────┘
```

`jq` is no longer consulted, and the SessionStart warning about it is gone. Nothing falls back to pattern matching, because the fallback was the defect.

The concern that motivated the old design still stands: a security guard that fails to install is worse than no guard, because it creates a false sense of safety. v5.0.0 answers it differently. Rather than degrade quietly to a weaker parser, a host that cannot run the guards produces a visible hook error on every guarded event. You are told the safety layer is absent instead of being left to assume it is working.

Since v5.0.0 every hook is a Node script launched in exec form (`node ${CLAUDE_PLUGIN_ROOT}/scripts/tq-*.js`), so there is no shell PATH preamble and no `jq` dependency. The v4.x hooks were bash one-liners that prepended `$LOCALAPPDATA/Microsoft/WinGet/Links` to PATH so a winget-installed `jq` could be found under Git Bash; that preamble also broke under Git Bash because the Windows path contains a colon.

### Security Guards Must Never Fail-Open

This principle deserves its own heading because it is the one design decision that cannot be compromised. The retired migration guard, force push guard, hard reset guard, and DB deploy guard all used exit code 2 (block) as their default path, and the permission rules that replaced them cannot fail open at all. If parsing fails, if the input is garbled, if the session ID is missing, the guard blocks.

[Shaharia Azam: AI Integration Framework](https://shaharia.com/blog/ai-integration-framework/) calls this the "zero-trust mindset": treat every AI contribution as if it came from a brand-new junior developer. You would not give a junior developer unsupervised force-push access. You should not give it to an AI agent either.

[NxCode: Harness Engineering Guide](https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026) crystallizes it further: "The model is commodity. The harness is moat." The AI model will be replaced. The safety harness around it is the durable competitive advantage. A plugin without guardrails is a liability. A plugin with layered, fail-closed, zero-dependency guardrails is infrastructure.

---

## 7. The Plan Audit

### Why Plans Need Auditing Too

If you have ever watched a project go sideways, you know the problem usually was not the code. It was the plan. Or more precisely, the holes in the plan that nobody noticed until they became production incidents.

Toque's plan audit applies the same scrutiny to technical plans, migration specs, and refactoring proposals. Instead of a binary "looks good" or "needs work," you get a per-criterion verdict with the evidence behind it, structured gap detection, and findings you can act on. There is no score: a plan either has the thing or it does not, and the audit shows you where it says so. The methodology is implemented in the [plan-auditor agent](plugins/toque/agents/plan-auditor.md).

### The 8 Review Dimensions

The dimensions are lenses for finding gaps and locating evidence, not things to be rated. They are ordered by when they matter in a plan's lifecycle: WHY first, then HOW, then WHAT-IF.

```text
  THE 8 REVIEW DIMENSIONS

  ┌────────────────────────────────────────────────────────────────────┐
  │                                                                    │
  │  WHY are we doing this?                                            │
  │  ┌──────────────────────────────────────────────────────────┐      │
  │  │  1. Problem Definition   Is the WHY clear?   │      │
  │  └──────────────────────────────────────────────────────────┘      │
  │                                                                    │
  │  HOW will we do it?                                                │
  │  ┌──────────────────────────────────────────────────────────┐      │
  │  │  2. Architecture & Design   Is the HOW sound?   │      │
  │  │  3. Phasing & Sequencing   Is the ORDER right? │      │
  │  └──────────────────────────────────────────────────────────┘      │
  │                                                                    │
  │  WHAT IF something goes wrong?                                     │
  │  ┌──────────────────────────────────────────────────────────┐      │
  │  │  4. Risk Assessment   What could go WRONG? │      │
  │  │  5. Rollback & Safety   Can we UNDO this?   │      │
  │  └──────────────────────────────────────────────────────────┘      │
  │                                                                    │
  │  WHO, WHEN, and HOW do we prove it?                                │
  │  ┌──────────────────────────────────────────────────────────┐      │
  │  │  6. Timeline & Effort   How LONG and MUCH?  │      │
  │  │  7. Testing & Validation   How do we PROVE it? │      │
  │  │  8. Team & Resources   WHO does this?      │      │
  │  └──────────────────────────────────────────────────────────┘      │
  │                                                                    │
  └────────────────────────────────────────────────────────────────────┘
```

| Dimension | What It Measures | Falls short | Meets the bar |
| :---------- | :----------------- | :----------------- | :----------------- |
| 1. Problem Definition | Is the WHY clear? Problem stated, business impact quantified, success criteria defined | "We should refactor payments" | Problem quantified, current state documented with evidence, measurable success criteria |
| 2. Architecture & Design | Is the HOW sound? Architecture diagrammed, tech choices justified, interfaces defined | Vague hand-waving about "new service" | Component diagram, interface contracts, existing codebase patterns followed |
| 3. Phasing & Sequencing | Is the ORDER right? Phases go low-to-high risk, each delivers value independently | All-or-nothing single phase | Low-risk phases first, each phase delivers value, stop-after-any-phase option |
| 4. Risk Assessment | What could go WRONG? Risks with likelihood/impact, mitigations defined | "There are some risks" | Top risks with likelihood/impact matrix, contingency plans, highest-risk phase called out |
| 5. Rollback & Safety | Can we UNDO this? Rollback per phase, feature flags, blast radius documented | No rollback mentioned | Per-phase rollback, feature flag, shadow mode, blast radius quantified |
| 6. Timeline & Effort | How LONG and how MUCH? Evidence-based estimates, critical path, 20-30% buffer | "Should take a few weeks" | Per-phase estimates with evidence basis, critical path identified, buffer included |
| 7. Testing & Validation | How do we PROVE it works? Test strategy per phase, characterization tests, acceptance criteria | "We will test it" | Test strategy per phase, characterization tests before refactoring, acceptance criteria per deliverable |
| 8. Team & Resources | WHO does this? Team identified, skills documented, key person risk addressed | No team mentioned | Team named, skills documented, key person risk mitigated, single accountable owner |

### The Evidence Requirement

Every finding from the plan audit must carry a confidence tier. This prevents the auditor from generating plausible-sounding gaps that do not actually exist in the plan. The confidence system works the same way as the codebase audit confidence tiers.

| Tier | Meaning | Example |
| :----- | :-------- | :-------- |
| **HIGH** | Direct quote or reference from plan text or codebase | "Section 3.2 states rollback via feature flag" |
| **MEDIUM** | Indirect evidence (pattern match, naming convention) | "Plan mentions 'incremental rollout' but no specific mechanism" |
| **LOW** | Agent judgment without direct evidence | "No timeline section found [VERIFY WITH AUTHOR]" |

Unverified findings (no evidence at all) are excluded from scoring entirely. They appear in a separate section tagged `[UNVERIFIED]`. This prevents the audit from inflating its gap count with speculative concerns.

### The 4 Structured Gap Checks

A dimension review catches qualitative gaps ("the risk section is thin"). But a plan can clear every dimension and still have structural holes the dimension model misses. That is why the audit runs 4 additional structured checks, implemented by the Gap Verifier subagent in the [plan-auditor](plugins/toque/agents/plan-auditor.md).

```mermaid
graph TD
    PLAN["Plan Document"] --> CV["A. Coverage Matrix"]
    PLAN --> AR["B. Assumption Register"]
    PLAN --> SM["C. Scenario Matrix"]
    PLAN --> CC["D. Cross-Cutting<br/>Concern Sweep"]

    CV --> LINT["Binary<br/>Lint Rules"]
    AR --> LINT
    SM --> LINT
    CC --> LINT

    LINT --> VERDICT{"All pass?"}
    VERDICT -->|Yes| GAPPED["Gap-Checked: YES"]
    VERDICT -->|No| NOTGAPPED["Gap-Checked: NO<br/>List failures"]

    style PLAN fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style CV fill:#F39C12,stroke:#E67E22,color:#fff
    style AR fill:#F39C12,stroke:#E67E22,color:#fff
    style SM fill:#F39C12,stroke:#E67E22,color:#fff
    style CC fill:#F39C12,stroke:#E67E22,color:#fff
    style LINT fill:#9B59B6,stroke:#8E44AD,color:#fff
    style VERDICT fill:#fff,stroke:#2C3E50,color:#2C3E50
    style GAPPED fill:#2ECC71,stroke:#27AE60,color:#fff
    style NOTGAPPED fill:#E74C3C,stroke:#C0392B,color:#fff
```

**A. Coverage Matrix** traces every goal, risk, dependency, and non-goal to its implementation in the plan. If a goal from Stage 1's intent.md has no corresponding ticket or stage, the matrix exposes it. If a risk has no mitigation, same thing.

**B. Assumption Register** catalogs every assumption the plan makes, then asks two questions: what happens if this assumption is false, and how will we verify it before we find out the hard way? Unverified HIGH-impact assumptions are treated as gaps.

**C. Scenario Matrix** checks 8 mandatory scenarios against the plan:

| # | Scenario | What It Catches |
| :-: | :--------- | :---------------- |
| 1 | Happy path | Does the plan describe the normal flow? |
| 2 | Failure path | What happens when things break? |
| 3 | Partial rollout (mixed state) | Old and new code running simultaneously |
| 4 | Backward compatibility | Will existing clients break? |
| 5 | Scale/volume edge | What happens at 10x traffic? |
| 6 | Auth/permission edge | What if the user lacks permissions? |
| 7 | Config/environment difference | Does it work in staging AND production? |
| 8 | Rollback path | Can we actually undo each phase? |

**D. Cross-Cutting Concern Sweep** checks 12 concerns that tend to fall through the cracks because they span multiple domains: API contract, UI behavior, auth/authz, config, CORS/network, data model/query limits, pagination, caching, observability, migration/backward compat, rollout/rollback, and tests.

### The Lint Rules

On top of the 4 matrices, a set of binary pass/fail rules run as automated checks — most during Phase 5 Audit, two during Phase 7 Impact Review. These are the plan equivalent of a linter. Either the rule passes or it does not.

[lint-registry.md](plugins/toque/docs/planning-techniques/lint-registry.md) is the canonical registry, and since PH5-001 it is the *only* place rule text and rule counts are written. The table below reproduces the registry's wording verbatim and `tests/layer1-config-wiring.sh` fails the suite if a word of it drifts. It states no total for the same reason: this page, the registry, `commands/plan.md` and `agents/plan-auditor.md` were each carrying a different figure, and the only way to stop that recurring is for exactly one file to be allowed to say it.

| Rule | Description | Phase |
| :----- | :------------ | :---- |
| LINT-01 | Every goal has at least one mapped ticket | 5 |
| LINT-02 | Every HIGH risk has a mitigation | 5 |
| LINT-03 | Every deployment phase has a rollback plan | 5 |
| LINT-04 | Every external dependency has an owner | 5 |
| LINT-05 | Every new endpoint/API has a contract or test entry | 5 |
| LINT-06 | Backward compatibility claimed but no mixed-state scenario | 5 |
| LINT-07 | Every new behavior has a test or test delta | 5 |
| LINT-08 | No unverified HIGH-impact assumption exists | 5 (hard gate) |
| LINT-09 | No unaddressed cross-cutting concern for in-scope features | 5 |
| LINT-10 | Every phase has go/no-go criteria | 5 |
| LINT-11 | Every code change maps to a plan ticket | 7 (Full only) |
| LINT-12 | Every plan ticket maps to at least one code change (or deferred) | 7 (Full only) |
| LINT-13 | Approach has options analysis with min 2 alternatives evaluated | 5 |
| LINT-14 | No regressions from previous baseline | 5 |
| LINT-15 | All "Tested" claims have verified test infrastructure | 5 |
| LINT-16 | All "Monitored" claims have verified monitoring infrastructure | 5 |
| LINT-17 | Every deliverable in Phase 4 spec must have a testing methodology assigned | 4 / 5 |
| LINT-18 | AI-generated code deliverables must specify a separate test writer | 4 / 5 |
| LINT-19 | Confidence brief exists with no unresolved HIGH-impact markers | 5 |
| LINT-20 | Confidence brief has all 3 sections and each entry has required fields | 5 |

A plan is "gap-checked" only when every applicable lint rule passes, the Coverage Matrix has zero gaps, no unverified HIGH-impact assumptions remain, the Scenario Matrix has zero gaps, the Cross-Cutting Sweep has zero gaps, and infrastructure verification has zero INFRA-GAPs. That is a high bar. Most first-draft plans fail it. That is the point. The evaluator-optimizer loop auto-revises to close gaps before presenting results.

### The 5 Parallel Subagents

The plan audit does not run as a single agent reviewing all 8 dimensions. A single agent reviewing everything gravitates toward the first type of issue it finds (anchoring bias). Instead, the [plan-auditor](plugins/toque/agents/plan-auditor.md) deploys 5 specialist subagents in parallel.

```mermaid
graph TD
    ORCH["Orchestrator<br/>(reads plan, runs pre-checks)"] --> A1["Architecture<br/>Reviewer<br/><i>Opus</i>"]
    ORCH --> A2["Risk<br/>Reviewer<br/><i>Opus</i>"]
    ORCH --> A3["Execution<br/>Reviewer<br/><i>Sonnet</i>"]
    ORCH --> A4["Quality<br/>Reviewer<br/><i>Sonnet</i>"]
    ORCH --> A5["Gap<br/>Verifier<br/><i>Opus</i>"]

    A1 -->|"Dims 1, 2, 3"| VERIFY["Verification Pass<br/>(false positive<br/>prevention)"]
    A2 -->|"Dims 4, 5"| VERIFY
    A3 -->|"Dims 6, 8"| VERIFY
    A4 -->|"Dim 7"| VERIFY
    A5 -->|"4 gap artifacts<br/>+ lint rules"| VERIFY

    VERIFY --> REPORT["Final Audit<br/>Report"]

    style ORCH fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style A1 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style A2 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style A3 fill:#1ABC9C,stroke:#16A085,color:#fff
    style A4 fill:#1ABC9C,stroke:#16A085,color:#fff
    style A5 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style VERIFY fill:#F39C12,stroke:#E67E22,color:#fff
    style REPORT fill:#2ECC71,stroke:#27AE60,color:#fff
```

| Subagent | Model | Dimensions | Focus |
| :--------- | :------ | :----------- | :------ |
| Architecture Reviewer | Opus | 1, 2, 3 | Is the design sound? Does it follow existing patterns? |
| Risk Reviewer | Opus | 4, 5 | What could go wrong? Can we undo it? |
| Execution Reviewer | Sonnet | 6, 8 | Is the timeline realistic? Who does the work? |
| Quality Reviewer | Sonnet | 7 | How do we prove this works? |
| Gap Verifier | Opus | None (produces artifacts) | Structural gap detection via 4 matrices + lint |

Architecture and Risk use Opus because those dimensions require deep reasoning about tradeoffs and failure scenarios. Execution and Quality use Sonnet because those are more mechanical assessments (does a timeline exist? are tests mentioned?). This balances quality with cost.

The Gap Verifier is separate from the dimension reviewers because structural gap detection (traceability, scenarios, assumptions) uses a fundamentally different methodology than dimension review. A plan can come back clean on every dimension and still have 5 gaps in the Coverage Matrix.

### The Verification Pass

After all 5 subagents complete, the orchestrator runs a verification pass to prevent false positives. The process is straightforward: for each candidate gap, re-read the entire plan searching for related keywords. The plan author may have addressed a concern in a section that the specialist did not focus on.

If the gap is found elsewhere, it gets dropped with a note: "Addressed in [section]." If it is genuinely absent, it is confirmed with a confidence tier. The audit report includes verification statistics: "X candidate gaps, Y confirmed, Z dropped (W% false positive prevention rate)."

The verification pass also cross-references between specialists. If the Risk Reviewer found a concern but the Architecture Reviewer returned that dimension clean, the contradiction gets investigated. These cross-checks catch the edge cases that individual specialists miss.

### Plan Audit Sources

- [DORA State of DevOps Report](https://dora.dev/) - The four key metrics (deployment frequency, lead time, change failure rate, recovery time) inform what a "production-ready" plan looks like. Plans that address all four metrics score higher on dimensions 4-7.
- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) - The principle that architectural constraints should be enforced mechanically, not by suggestion. The lint rules implement this principle for plans.

---

## 8. LLM Self-Audit (Epistemic Transparency)

### Why AI Auditors Must Audit Themselves

LLM-generated analysis has specific failure modes that human analysis does not. A human auditor who is unsure says "I think" or "I'm not sure." An LLM produces the same confident prose whether it grep-confirmed a file count or hallucinated a pattern from a directory name. The confidence signal is flat. This creates a dangerous asymmetry: the most dangerous findings (high-confidence hallucinations) are the hardest to distinguish from the most reliable findings (tool-verified facts).

Toque's self-audit framework addresses this by requiring every finding to carry an explicit evidence basis that communicates *how* the claim was derived, not just *what* the claim says. The framework is implemented in the [self-audit-knowledge skill](plugins/toque/skills/self-audit-knowledge/SKILL.md) and integrated into all Phase 2 scanner agents, the Phase 3 synthesis, and the report generator.

### The Three Verification Tiers

Every finding in a Toque audit carries a verification tier that classifies the evidence type behind the claim.

```text
  CLAIM VERIFICATION TIERS

  ┌─────────────────────────────────────────────────────────────────────┐
  │                                                                     │
  │  TIER A (Tool-Verified)                                            │
  │  ┌───────────────────────────────────────────────────────────────┐  │
  │  │  Claims confirmed by deterministic tool output.              │  │
  │  │  Glob matches, grep results, wc -l counts, manifest parsing. │  │
  │  │  Near-zero hallucination risk.                               │  │
  │  │  Always HIGH confidence unless truncated.                    │  │
  │  └───────────────────────────────────────────────────────────────┘  │
  │                                                                     │
  │  TIER B (Code-Reading)                                             │
  │  ┌───────────────────────────────────────────────────────────────┐  │
  │  │  Claims about runtime behavior, control flow, side effects   │  │
  │  │  derived from reading source files via the Read tool.        │  │
  │  │  Moderate hallucination risk. Confidence depends on          │  │
  │  │  full-file vs. partial read.                                 │  │
  │  └───────────────────────────────────────────────────────────────┘  │
  │                                                                     │
  │  TIER C (Pattern Inference)                                        │
  │  ┌───────────────────────────────────────────────────────────────┐  │
  │  │  Claims assembled from naming conventions, directory          │  │
  │  │  structure, file adjacency, or LLM reasoning.                │  │
  │  │  Highest hallucination risk.                                 │  │
  │  │  Always MEDIUM or LOW confidence.                            │  │
  │  └───────────────────────────────────────────────────────────────┘  │
  │                                                                     │
  └─────────────────────────────────────────────────────────────────────┘
```

The tier is orthogonal to the confidence level. Confidence measures certainty. The tier measures evidence type. A finding can be HIGH confidence and Tier A (a grep confirmed 14 payment files exist) or HIGH confidence and Tier C (the agent inferred a pattern but is quite sure about it). The second combination — HIGH confidence + Tier C — is the most dangerous in the system, because it looks authoritative but is based on inference. Toque flags these as SUSPECT and auto-adds them to the Phase 3 spot-check list.

### Evidence Basis Format

Findings use the format `{Tier}-{Confidence}: {one-line verification method}` in the Evidence Basis column of scanner output tables. Examples:

- `A-HIGH: glob matched 14 files with payment patterns`
- `B-MEDIUM: read primary handler, did not trace all call sites`
- `C-LOW: inferred from directory name "payments/" without reading contents`

This format communicates three things in one line: how the claim was derived, how certain the agent is, and what verification method was used. An engineer reading the report can immediately distinguish between findings they can trust and findings they should spot-check.

### Failure Mode Flags

Four inline tags mark known LLM failure patterns on individual findings:

| Flag | What It Means | Action Required |
| :--- | :------------ | :-------------- |
| `[ENUMERATION-MAY-BE-INCOMPLETE]` | A list or count may have been truncated by tool output limits | Verify counts manually |
| `[INFERRED-FROM-NAMING]` | Conclusion drawn from naming patterns, not from reading the code | Spot-check 2-3 items against actual code |
| `[SIDE-EFFECTS-NOT-TRACED]` | Primary behavior documented, but downstream cascades may be missing | Review call sites for the affected module |
| `[DEAD-CODE-UNCERTAIN]` | Cannot confirm whether a code path is actually reachable | Check with dead code analysis tools |

The `[SIDE-EFFECTS-NOT-TRACED]` flag addresses the most common LLM failure mode in codebase analysis: documenting the primary action of a function while omitting its cascading effects. A setter that updates a price field may also trigger a recalculation in a downstream observer, invalidate a cache, and update a UI state. The LLM reads the setter and reports "updates price." The three downstream effects are invisible unless the agent traces every call site. This flag makes that gap explicit.

### Category-Based Cascade Risk

Cascade risk classifies what happens if a finding is wrong. The classification is **category-based, not count-based**. This is a deliberate design decision. Numeric fan-out thresholds (e.g., "more than 5 dependents = high cascade") are unreliable because a setter touching 3 files can break an entire payment flow, while a utility with 10 dependents may be purely cosmetic.

```text
  CASCADE RISK CLASSIFICATION

  ┌─────────────────────────────────────────────────────────────┐
  │                                                             │
  │  CASCADE (always, regardless of fan-out count)              │
  │  ├── Touches auth/security paths                            │
  │  ├── Touches payment flows                                  │
  │  ├── Touches required-mod / state mutation flows            │
  │  └── Another scanner consumed this finding as input         │
  │                                                             │
  │  COVERAGE                                                   │
  │  └── Scope/completeness claim; if wrong, silent gaps        │
  │                                                             │
  │  CONTAINED                                                  │
  │  └── Self-contained finding; if wrong, affects only itself  │
  │                                                             │
  └─────────────────────────────────────────────────────────────┘
```

The cascade risk line only appears in the report for non-CONTAINED findings. This follows the "exception-only annotations" design principle: containment is the default, and only elevated risk gets called out. A `[SEVERITY-OVERRIDE]` flag may force CASCADE on any finding where the orchestrator determines the domain warrants it.

### Phase 3 Cross-Validation

The Phase 3 synthesis in the codebase-audit command uses the self-audit framework to systematically validate findings across agents. The process follows 7 steps:

1. **Read all outputs** from the 5 Phase 1/2 agents
2. **Cross-reference matrix** — for every module mentioned by 2+ scanners, check alignment and verify side-effect documentation
3. **Contradiction detection** — when scanners disagree, re-read source files and mark findings `[CROSS-VALIDATED]` or `[CROSS-VALIDATION FAILED]`
4. **Spot-check HIGH-confidence findings** — select 3-5 at random, re-run tools or re-read files to confirm, downgrade Tier C + HIGH to MEDIUM with `[TAG INFLATION DETECTED]`
5. **Cascade risk assessment** — apply category-based rules to every finding
6. **Coverage failure check** — look for truncated enumerations, context limit hits, and unexamined directories
7. **Draft synthesis** — compile self-audit statistics for the report generator

### Tier-Aware Confidence Decay

Findings decay at different rates depending on their verification tier, because inferred patterns become inaccurate sooner than tool-verified facts as code changes. The governance-knowledge skill defines the tier-aware decay schedule:

| Tier | FRESH | AGING | STALE | EXPIRED |
| :--- | :---- | :---- | :---- | :------ |
| A (Tool-Verified) | 0-30 days | 31-60 days | 61-90 days | 91+ days |
| B (Code-Reading) | 0-20 days | 21-45 days | 46-75 days | 76+ days |
| C (Pattern Inference) | 0-15 days | 16-30 days | 31-60 days | 61+ days |

A Tier C finding from 20 days ago is already AGING, while a Tier A finding from the same date is still FRESH. This reflects the reality that a grep-verified file count stays accurate longer than an inference about code behavior.

### The Self-Audit Summary

The Toque report replaces the traditional Confidence Summary with a Self-Audit Summary that includes four sections:

1. **Evidence Basis Distribution** — counts of Tier A/B/C findings with their confidence spread
2. **Failure Mode Flags** — counts of each flag type with required actions
3. **Cross-Validation Results** — table of modules where scanners disagreed, with resolutions
4. **What to Verify** — consolidated list of items requiring human review

If more than 30% of findings are Tier C, the overall report confidence is downgraded one level. If any HIGH-confidence finding fails spot-checking, all findings from that scanner are reviewed. These thresholds are defined in the [self-audit-knowledge skill](plugins/toque/skills/self-audit-knowledge/SKILL.md) as the single source of truth.

### Self-Audit in Plan Auditing

The self-audit framework extends to plan auditing via the [plan-auditor](plugins/toque/agents/plan-auditor.md) and [plan-scaffolder](plugins/toque/agents/plan-scaffolder.md). Plan audits use Tier A/B/C labels alongside confidence levels and add three plan-specific failure mode flags: `[PLAN-GAP-INFERRED]` (gap detected by keyword absence), `[SCOPE-ASSUMED]` (auditor assumed scope beyond explicit plan text), and `[CODEBASE-CLAIM-NOT-VERIFIED]` (plan references code the auditor could not verify).

---

## 9. Operational Readiness (Google SRE PRR)

### From Code Review to Production Readiness

Code quality is necessary but not sufficient. A codebase can have clean architecture, good test coverage, and thorough documentation, and still be a nightmare to change safely. The missing piece is operational readiness: the guardrails, maintenance systems, and monitoring that make change safe in practice.

Toque's Category 3 adapts [Google's Production Readiness Review](https://sre.google/sre-book/launching/) for codebase-level assessment. Google's PRR was designed for services going into production. Toque's version asks the same fundamental question at the codebase level: "Can we safely change this?"

The answer breaks down into 4 sub-categories. Each one addresses a different failure mode.

### The 4 Sub-Categories

```mermaid
graph TD
    subgraph "Category 3: Operational Readiness"
        A["3A. Guardrail Coverage<br/><i>Are automated safety<br/>nets installed?</i>"]
        B["3B. Context Currency<br/><i>Are docs and baselines<br/>fresh or stale?</i>"]
        C["3C. Test Safety Net<br/><i>Is test coverage adequate<br/>for high-risk modules?</i>"]
        D["3D. Change Readiness<br/>Score<br/><i>Composite rating</i>"]
    end

    A -->|"feeds into"| D
    B -->|"feeds into"| D
    C -->|"feeds into"| D

    D --> GREEN["GREEN<br/>Safe to change"]
    D --> YELLOW["YELLOW<br/>Extra review needed"]
    D --> ORANGE["ORANGE<br/>Plan + rollback required"]
    D --> RED["RED<br/>Full audit first"]

    style A fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style B fill:#F39C12,stroke:#E67E22,color:#fff
    style C fill:#9B59B6,stroke:#8E44AD,color:#fff
    style D fill:#1ABC9C,stroke:#16A085,color:#fff
    style GREEN fill:#2ECC71,stroke:#27AE60,color:#fff
    style YELLOW fill:#F1C40F,stroke:#F39C12,color:#2C3E50
    style ORANGE fill:#E67E22,stroke:#D35400,color:#fff
    style RED fill:#E74C3C,stroke:#C0392B,color:#fff
```

### 3A. Guardrail Coverage

Guardrails are automated checks that run without anyone remembering to invoke them. They are the difference between "we have a process" and "the process enforces itself."

Toque checks for three layers of guardrails, generated by the gate-generator agent and orchestrated by the the CI gate generator command:

| Layer | What It Does | Implementation |
| :------ | :------------- | :--------------- |
| **Permission rules** | Refuse or confirm dangerous operations | `deny`/`ask` entries in `settings.json` for force push, migration edits, DB deploys |
| **CI quality gates** | Check every PR automatically | PR risk scoring, audit staleness check |
| **Pre-commit hooks** | Catch issues before commit | Risk zone checker for HIGH-risk modules |

A codebase with all three layers has defense in depth. A codebase with none has "we will be careful" as its safety strategy. The audit rates guardrail coverage based on which layers are present and how many HIGH-risk modules from the risk assessment are covered by automated checks.

### 3B. Context Currency

Findings decay. An audit report from 6 months ago might describe a codebase that no longer exists. Context currency measures how fresh your documentation, audit baselines, and findings are.

The delta-scanner agent implements confidence decay using a simple time-based model:

```text
  CONFIDENCE DECAY MODEL

  Day 0                30                60                90
   ├──────────────────┼─────────────────┼─────────────────┤
   │     FRESH        │     AGING       │     STALE       │  EXPIRED
   │  No change to    │  Downgrade one  │  Downgrade two  │  Tag with
   │  confidence      │  tier           │  tiers          │  [REQUIRES
   │                  │  (HIGH->MED)    │  (HIGH->LOW)    │  RE-SCAN]
   └──────────────────┴─────────────────┴─────────────────┘
```

A HIGH confidence finding becomes MEDIUM after 31 days, LOW after 61 days, and gets tagged `[REQUIRES RE-SCAN]` after 91 days. This is not arbitrary. It reflects the reality that codebases change continuously, and a finding about module coupling from 3 months ago may not match the current dependency graph.

Delta tracking via the delta scan provides quick re-measurement without a full re-scan. It takes 2-3 minutes and tells you what improved, what regressed, and whether a full scan is warranted. The KPI dashboard tracks 12 metrics over time with trend indicators, making progress visible across multiple scan cycles.

The 12 tracked KPIs are: readiness score, Phase 2 eligibility, monolith file count, largest monolith LOC, test file count, test file ratio, HIGH-risk module count, CRITICAL findings open, stale findings count, days since full scan, config files changed, and security files changed.

### 3C. Test Safety Net

Test coverage numbers can be misleading. 80% line coverage means nothing if the untested 20% contains your payment processing logic. Category 3C focuses specifically on whether HIGH-risk modules (identified by the Phase 2 risk assessment) have adequate test coverage.

The key technique is characterization testing, implemented by the characterization-generator agent. Characterization tests capture what the code DOES, not what it SHOULD do. The distinction matters for refactoring.

```text
  CHARACTERIZATION TESTS vs UNIT TESTS

  Unit Test:
    "Given input X, the function SHOULD return Y"
    (tests correctness against a specification)

  Characterization Test:
    "Given input X, the function CURRENTLY returns Y"
    (captures behavior before refactoring)

  After refactoring:
    Same input X should still produce Y.
    If it doesn't, the refactoring changed behavior.
```

This approach comes from Michael Feathers' "Working Effectively with Legacy Code" and is adapted for AI-assisted refactoring. Before an AI agent extracts a function from a monolith, characterization tests lock in the current behavior. After extraction, the same tests verify behavioral parity. If a test fails, the extraction changed something it should not have.

### 3D. Change Readiness Score

The Change Readiness Score is a composite rating derived from 3A, 3B, and 3C. It answers the one question that matters before any change: "Is it safe to modify this codebase right now?"

| Rating | Meaning | Action |
| :------- | :-------- | :------- |
| **GREEN** | Safe to change with standard process | Proceed normally |
| **YELLOW** | Change with extra review | Get a second pair of eyes on PRs |
| **ORANGE** | Change only with plan and rollback | Use [`/toque:quick-plan`](plugins/toque/commands/quick-plan.md) first |
| **RED** | Do not change without full audit | Run the codebase audit first |

A GREEN rating requires all three sub-categories to be healthy: guardrails are installed, context is fresh (under 30 days), and HIGH-risk modules have test coverage. Any gap downgrades the rating.

### The Baseline Maintenance System

Audits produce snapshots. Maintenance turns snapshots into a living system. The baseline maintenance system implemented by the CI gate generator operates in three layers.

```text
  THE THREE LAYERS OF BASELINE MAINTENANCE

  ┌──────────────────────────────────────────────────────────────┐
  │  LAYER 3: HARD GATES (CI)                                    │
  │  ┌────────────────────────────────────────────────────────┐  │
  │  │  GitHub Actions workflow blocks PRs when:              │  │
  │  │  - HIGH-risk module changed without test update        │  │
  │  │  - Audit baseline older than 30 days                   │  │
  │  │  Starts in ADVISORY MODE for 2 weeks.                  │  │
  │  └────────────────────────────────────────────────────────┘  │
  │                                                              │
  │  LAYER 2: SMART NUDGES (Claude Code hooks)                   │
  │  ┌────────────────────────────────────────────────────────┐  │
  │  │  Threshold-based suggestions:                          │  │
  │  │  - After N file changes: "Run codebase-delta?"         │  │
  │  │  - Config/migration file changed: "Baseline stale?"    │  │
  │  │  - HIGH-risk module touched: "Characterize first?"     │  │
  │  │  - N days since last audit: "Time to re-scan"          │  │
  │  └────────────────────────────────────────────────────────┘  │
  │                                                              │
  │  LAYER 1: PASSIVE TRACKING (always on)                       │
  │  ┌────────────────────────────────────────────────────────┐  │
  │  │  PostToolUse hook counts file changes silently.        │  │
  │  │  No interruptions. No warnings. Just counting.         │  │
  │  │  Provides data for Layer 2 thresholds.                 │  │
  │  └────────────────────────────────────────────────────────┘  │
  └──────────────────────────────────────────────────────────────┘
```

Layer 1 is invisible. The baseline-tracker script runs as a PostToolUse hook, incrementing a counter every time a file is written or edited. No output, no interruptions. It just counts.

Layer 2 uses that count to trigger contextual nudges. After 15 file changes (configurable via `TP_CHANGE_THRESHOLD`), it suggests running a delta scan. If a config file, migration file, or security-related file is changed, it suggests a targeted re-scan. These are suggestions, not blocks. You can always ignore them.

Layer 3 is optional CI enforcement. A GitHub Actions workflow checks PRs against the audit baseline. For the first 2 weeks after installation, it runs in advisory mode (warnings only). After that, the team can switch to blocking mode. The escalation is gradual by design. Teams that have never had quality gates should not start with hard blocks on day one.

### DORA Metrics Integration

Toque tracks progress against the [DORA four key metrics](https://dora.dev/), the industry standard for software delivery performance since the 2014 State of DevOps report.

| Metric | Elite | High | Medium | Low |
| :------- | :------ | :----- | :------- | :---- |
| Deployment Frequency | Multiple/day | Weekly to monthly | Monthly to biannual | Biannual+ |
| Lead Time for Changes | Under 1 hour | 1 day to 1 week | 1 to 6 months | 6+ months |
| Change Failure Rate | Under 5% | 5-10% | 10-15% | 15%+ |
| Mean Time to Recovery | Under 1 hour | Under 1 day | 1 day to 1 week | 1+ week |

The key finding from DORA research relevant to AI-assisted development: AI tools increase deployment frequency and reduce lead time (good), but change failure rate rises without quality gates (bad). Teams that adopt AI coding assistants without guardrails ship faster and break more things. Toque's Category 3 exists specifically to prevent that tradeoff.

### Operational Readiness Sources

- [Google SRE Book, Chapter 32](https://sre.google/sre-book/launching/) - The original Production Readiness Review covering system architecture, instrumentation, emergency response, capacity, change management, and performance criteria.
- [Cortex: Production Readiness](https://www.cortex.io/) - Tiered maturity model (Bronze/Silver/Gold) that inspired Toque's GREEN/YELLOW/ORANGE/RED change readiness scoring.
- [DORA State of DevOps Report](https://dora.dev/) - The four key metrics that define software delivery performance, now the industry standard for measuring team and codebase health.

---

## 10. Multi-Agent Orchestration

### Why One Agent Is Not Enough

If you have ever asked an AI to "review this entire codebase," you have probably noticed the quality drops as the conversation gets longer. The first few findings are sharp. By finding number 20, the agent is repeating itself or missing obvious issues. This is not a bug. It is a fundamental limitation of how context windows work.

Research from the Claude Code community (GitHub Issue #24256) found that "role specialization degrades after roughly 15-20 iterations." An agent that starts as a focused security reviewer gradually drifts toward general commentary. By the time it has processed 50 files, it is no longer the specialist you asked for.

Toque solves this with multi-agent orchestration: one orchestrator command spawns multiple specialist agents, each with a fresh context window and a specific, scoped objective. The agents write their outputs to the filesystem. After all agents complete, the orchestrator synthesizes and cross-references findings.

### The Fan-Out / Fan-In Pattern

Every Toque command that uses multiple agents follows the same structural pattern.

```mermaid
graph TD
    CMD["Command<br/>(orchestrator)"] --> PREP["Preparation<br/>Detect stack, read baselines,<br/>set up output directory"]

    PREP --> A1["Agent 1<br/>Fresh context<br/>Scoped objective"]
    PREP --> A2["Agent 2<br/>Fresh context<br/>Scoped objective"]
    PREP --> A3["Agent 3<br/>Fresh context<br/>Scoped objective"]
    PREP --> AN["Agent N<br/>Fresh context<br/>Scoped objective"]

    A1 -->|"writes JSON/MD<br/>to filesystem"| FS["Filesystem<br/>(docs/audit/)"]
    A2 -->|"writes JSON/MD<br/>to filesystem"| FS
    A3 -->|"writes JSON/MD<br/>to filesystem"| FS
    AN -->|"writes JSON/MD<br/>to filesystem"| FS

    FS --> SYNTH["Synthesis<br/>Read all outputs,<br/>cross-reference,<br/>resolve contradictions"]

    SYNTH --> REPORT["Final Report"]

    style CMD fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style PREP fill:#D6EAF8,stroke:#4A90D9,color:#2C3E50
    style A1 fill:#2ECC71,stroke:#27AE60,color:#fff
    style A2 fill:#2ECC71,stroke:#27AE60,color:#fff
    style A3 fill:#2ECC71,stroke:#27AE60,color:#fff
    style AN fill:#2ECC71,stroke:#27AE60,color:#fff
    style FS fill:#F39C12,stroke:#E67E22,color:#fff
    style SYNTH fill:#9B59B6,stroke:#8E44AD,color:#fff
    style REPORT fill:#1ABC9C,stroke:#16A085,color:#fff
```

The filesystem is the communication layer. Agents do not pass messages to each other through the orchestrator's context window. They write structured outputs (JSON or Markdown) to `docs/audit/`, and the orchestrator reads those files after all agents complete. This prevents context loss and makes every intermediate result inspectable.

### Agent Deployment Across Commands

Each Toque command deploys a different number of agents, tuned to the complexity of the task.

| Command | Agents | Parallelism | What They Do |
| :-------- | :------: | :------------ | :------------- |
| the AI-readiness scan | 10 | All parallel (Phase 2) | 9 scanner agents + 1 report generator, each checking a specific category of AI readiness |
| the codebase audit | 6 | 2 phases (3+2, then synthesis) | Phase 1: feature-scanner, dependency-mapper, doc-auditor (parallel). Phase 2: risk-assessor, integration-scanner (parallel). Then synthesis + report. |
| Governance commands | 4 | Per command | delta-scanner, gate-generator, security-scanner, characterization-generator each run as specialized single agents |
| [`/toque:quick-audit`](plugins/toque/commands/quick-audit.md) (plan audit) | 5 | All parallel | Architecture, risk, execution, quality reviewers + gap verifier |
| [`/toque:quick-plan`](plugins/toque/commands/quick-plan.md) (plan scaffolder) | 3 | All parallel | Codebase analyst, pattern researcher, test strategist gather evidence before the orchestrator writes the plan |
| [`/toque:troubleshoot`](plugins/toque/skills/troubleshoot/SKILL.md) | Up to 4 | Parallel (if escalated) | Code tracer, git historian, data inspector, integration checker. Only spawned when the bug spans 3+ layers. |

### Why Fresh Context Per Agent

The fresh context window is not a nice-to-have. It is the mechanism that makes specialist agents actually specialize. Here is what happens without it:

```text
  SINGLE AGENT (degraded specialization)

  ┌─────────────────────────────────────────────────────┐
  │  Start: "You are a security reviewer"               │
  │  File 1-5:   Sharp, focused findings                │
  │  File 6-15:  Still good, some repetition            │
  │  File 16-25: Drifting toward general commentary     │
  │  File 26+:   Repeating earlier findings, missing    │
  │              new patterns, role has degraded         │
  └─────────────────────────────────────────────────────┘

  MULTIPLE AGENTS (preserved specialization)

  ┌──────────────────────┐  ┌──────────────────────┐
  │  Agent 1: Security   │  │  Agent 2: Deps       │
  │  Fresh context       │  │  Fresh context        │
  │  5-10 files          │  │  5-10 files           │
  │  Sharp throughout    │  │  Sharp throughout     │
  └──────────────────────┘  └──────────────────────┘
  ┌──────────────────────┐  ┌──────────────────────┐
  │  Agent 3: Docs       │  │  Agent 4: Risk       │
  │  Fresh context       │  │  Fresh context        │
  │  5-10 files          │  │  5-10 files           │
  │  Sharp throughout    │  │  Sharp throughout     │
  └──────────────────────┘  └──────────────────────┘
```

Each agent gets a scoped objective. Not "review this codebase" but "scan all .csproj files for ProjectReference and PackageReference elements, build a project-to-project adjacency list, write to docs/audit/dependency-map.md." The specificity matters. Vague instructions produce vague results regardless of context freshness.

### Scaling Rules

Not every task benefits from multiple agents. Spawning a subagent has overhead: the context window setup, the prompt injection, the filesystem I/O. For small tasks, that overhead costs more than it saves.

The codebase-audit command documents the scaling rules:

```text
  WHEN TO USE SUBAGENTS

  1-2 independent tasks:    Just run them sequentially.
                            Subagent overhead is not worth it.

  3+ independent tasks:     Parallel subagents.
                            Time savings exceed overhead.

  5+ independent tasks:     Batch into 3-5 subagent groups.
                            Too many parallel agents can
                            overwhelm the filesystem.
```

The codebase audit scales its agent count to match codebase size. Small codebases (under 10 modules) get 2-3 subagents per phase. Medium codebases (10-30 modules) get 3-5. Large codebases (30+) get 5-8. This prevents both under-analysis (too few agents for a large codebase) and over-analysis (too many agents producing redundant findings for a small project).

### Model Selection Strategy

Toque uses two models for different types of work. The selection is not arbitrary. It maps to the cognitive demands of each task.

```mermaid
graph LR
    subgraph "Opus (Deep Reasoning)"
        O1["Architecture<br/>Review"]
        O2["Risk<br/>Assessment"]
        O3["Plan<br/>Synthesis"]
        O4["Gap<br/>Verification"]
        O5["Orchestration"]
    end

    subgraph "Sonnet (Pattern Matching)"
        S1["Evidence<br/>Gathering"]
        S2["Scanning"]
        S3["Mechanical<br/>Checks"]
        S4["Test Strategy"]
        S5["Delta<br/>Measurement"]
    end

    O1 ~~~ S1

    style O1 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style O2 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style O3 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style O4 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style O5 fill:#9B59B6,stroke:#8E44AD,color:#fff
    style S1 fill:#1ABC9C,stroke:#16A085,color:#fff
    style S2 fill:#1ABC9C,stroke:#16A085,color:#fff
    style S3 fill:#1ABC9C,stroke:#16A085,color:#fff
    style S4 fill:#1ABC9C,stroke:#16A085,color:#fff
    style S5 fill:#1ABC9C,stroke:#16A085,color:#fff
```

**Opus** handles tasks that require reasoning about tradeoffs, evaluating failure scenarios, synthesizing conflicting evidence, or making judgment calls. Architecture review ("is this design sound for THIS codebase?") needs Opus. Risk assessment ("what is the most likely failure mode?") needs Opus. Synthesis ("these 5 agent reports contradict each other on module X, which is right?") needs Opus.

**Sonnet** handles tasks that are read-heavy, pattern-matching, or mechanical. Scanning a codebase for test files is pattern matching. Counting monolith files is mechanical. Gathering evidence from a plan document is read-heavy. Sonnet does these well and costs less.

The [plan-auditor](plugins/toque/agents/plan-auditor.md) demonstrates the split clearly: Architecture and Risk reviewers use Opus (reasoning about tradeoffs and failure scenarios), while Execution and Quality reviewers use Sonnet (mechanical assessment of whether a timeline or test plan exists). The [plan-scaffolder](plugins/toque/agents/plan-scaffolder.md) uses the same split: 3 Sonnet analysts gather evidence, then an Opus orchestrator synthesizes the findings into a cohesive plan.

### The Troubleshooting Escalation Pattern

The [`/toque:troubleshoot`](plugins/toque/skills/troubleshoot/SKILL.md) command shows a different orchestration pattern: conditional escalation. Most bugs do not need multiple agents. A null reference exception in a single file is investigated perfectly well by one agent.

But some bugs span multiple layers: the UI shows the wrong data, the API returns the wrong response, the database has the wrong value, and the migration that changed the schema ran 3 commits ago. Investigating this serially means context-switching between frontend, backend, database, and git history, losing focus at each transition.

The troubleshoot command starts with a single agent for Phase 1 (Root Cause Investigation). If the bug meets escalation criteria (spans 3+ layers, 2+ competing hypotheses, or requires holding 4+ mental contexts), the orchestrator offers to switch to multi-agent mode. If the user agrees, up to 4 specialist agents (code tracer, git historian, data inspector, integration checker) investigate in parallel, and the orchestrator synthesizes their findings into a unified root cause.

This conditional escalation avoids the overhead of multi-agent mode for simple bugs while providing it for the complex cross-layer issues where it genuinely helps.

### Multi-Agent Orchestration Sources

- [Anthropic: code-review plugin](https://github.com/anthropics/claude-code/tree/main/plugins/code-review) - Uses 5 parallel Sonnet agents for different review aspects (correctness, style, performance, security, documentation), validating the specialist-per-domain pattern.
- [Anthropic: pr-review-toolkit](https://github.com/anthropics/claude-code/tree/main/plugins/pr-review-toolkit) - Uses 6 specialized agents, confirming that Anthropic's own plugins adopt the fan-out/fan-in orchestration model at scale.

---

## 11. The Dependency Decision (reversed in 5.0.0)

> Most of the handlers this section discusses shipped in `toque-guard`, retired in 9.0.0. The three plan-context handlers still in `toque` follow the same rules, and the rules are kept here because they are the reason a blocking hook is not a small thing to add.

### Why Dependencies Are the Enemy

Here is a fun rule of thumb: the number of machines where your safety hooks will fail silently is directly proportional to the number of dependencies those hooks require. Toque learned this the hard way, across four painful versions.

The goal from day one was simple. Seven safety hooks, all running inside Claude Code's bash environment, all parsing JSON from stdin, all making pass/block decisions. The problem was JSON parsing. Bash does not have a built-in JSON parser. So you reach for a tool. And that is where the trouble starts.

### The Four Failures

Every version of the hook system that relied on an external tool eventually broke on someone's machine. Here is the timeline, and each failure taught us something specific.

| Version | Approach | Failure | Result | Lesson |
| :------ | :------- | :------ | :----- | :----- |
| v4.14 | python3 in hooks | Git Bash on Windows did not have python3 on PATH. | All 7 hooks exited silently with no guard behavior. | "Available on most systems" is not good enough for safety infrastructure. |
| v4.21 | jq required | Developer machines without jq installed. | All 7 hooks exited silently. | A single required binary breaks the zero-config promise. |
| v4.26 | jq installed but invisible | winget installed jq to AppData, but Git Bash could not see it. | jq failed, hooks exited 0, and all guards were bypassed. | "Installed" and "on PATH" are different reliability states. |
| v4.26.1 | grep+sed only | Nested JSON, escaped quotes, and multiline values. | Partial parsing, missed fields, and false positives. | grep+sed works for flat JSON but breaks on real payloads. |

> Visual cue: this is a graveyard, not a timeline. Each row is a discarded architecture pattern that failed a reliability test.

The v4.26 failure was the worst. A developer had jq installed via `winget install jqlang.jq`. It worked in PowerShell. It worked in CMD. But Git Bash (where Claude Code hooks run) uses a different PATH. The `jq` command failed, the `set -e` wasn't set (because hooks need to handle errors gracefully), and the hook exited 0. Every safety guard was silently bypassed. Force pushes, migration edits, direct database deploys. All allowed.

That is the failure mode we designed the current system to prevent.

### The Current Solution: Graceful Degradation

The architecture that shipped in v4.27 used a three-layer fallback chain, described here for the record. v5.0.0 replaced it with Node handlers and no preamble; the fail-closed principle survived, the mechanism did not.

```mermaid
flowchart TD
    START["Hook receives JSON on stdin"] --> PREAMBLE["PATH preamble<br/><code>export PATH=$PATH:$LOCALAPPDATA/Microsoft/WinGet/Links:/usr/local/bin</code>"]
    PREAMBLE --> JQ_CHECK{"jq available?"}

    JQ_CHECK -->|"Yes"| JQ_PARSE["Parse with jq<br/><code>jq -r '.tool_input.command // empty'</code>"]
    JQ_CHECK -->|"No"| GREP_PARSE["Parse with grep+sed<br/><code>grep -o '\"command\":\"[^\"]*\"' | sed ...</code>"]

    JQ_PARSE --> JQ_RESULT{"Field extracted?"}
    JQ_RESULT -->|"Yes"| EVALUATE["Evaluate safety rules"]
    JQ_RESULT -->|"No (empty)"| GREP_PARSE

    GREP_PARSE --> GREP_RESULT{"Field extracted?"}
    GREP_RESULT -->|"Yes"| EVALUATE
    GREP_RESULT -->|"No"| SAFE_EXIT["exit 0<br/>(input doesn't match,<br/>not a security concern)"]

    EVALUATE --> BLOCK{"Dangerous<br/>operation?"}
    BLOCK -->|"Yes"| EXIT2["exit 2 + warning<br/>BLOCKED"]
    BLOCK -->|"No"| EXIT0["exit 0<br/>ALLOWED"]

    style START fill:#4A90D9,stroke:#2C6FAC,color:#fff
    style PREAMBLE fill:#F39C12,stroke:#E67E22,color:#fff
    style JQ_CHECK fill:#8E44AD,stroke:#6C3483,color:#fff
    style JQ_PARSE fill:#2ECC71,stroke:#27AE60,color:#fff
    style GREP_PARSE fill:#E67E22,stroke:#D35400,color:#fff
    style EVALUATE fill:#3498DB,stroke:#2980B9,color:#fff
    style EXIT2 fill:#E74C3C,stroke:#C0392B,color:#fff
    style EXIT0 fill:#2ECC71,stroke:#27AE60,color:#fff
    style SAFE_EXIT fill:#95A5A6,stroke:#7F8C8D,color:#fff
```

The PATH preamble is the first key insight. On Windows, `winget` installs binaries to `$LOCALAPPDATA/Microsoft/WinGet/Links`, which Git Bash does not include in its default PATH. On macOS/Linux, `/usr/local/bin` is the standard location for user-installed tools. By prepending both before every `jq` call, we cover the most common "installed but invisible" scenarios.

Source (historical, v4.x): the inline hook commands in `.claude-plugin/plugin.json` at that time. Current hooks live in `plugins/*/hooks/hooks.json` and `plugins/*/scripts/`.

### The Six Design Rules

These emerged from the failures above, and from the six defects an adversarial review found in the 5.0.0 rewrite itself. They are non-negotiable in any future hook development. Rules 2, 3 and 5 replace the pre-5.0.0 guidance that recommended jq-then-grep+sed; the example that settles rule 3 is that `git push "--force"` must be denied while a commit message mentioning it must not.

```text
  ┌─────────────────────────────────────────────────────────────┐
  │          THE SIX RULES OF HOOK DESIGN (5.0.0)                   │
  ├─────────────────────────────────────────────────────────────┤
  │                                                                 │
  │  1. A BLOCKING GUARD NEVER DENIES ON AN UNPARSED PAYLOAD        │
  │     Malformed under a real parser: fail closed. A construct the │
  │     guard cannot EVALUATE (a variable, a substitution, a nested │
  │     shell): return "ask" - not allow, not deny. Informational   │
  │     hooks fail OPEN, always. A tracker that blocks work costs   │
  │     more than one that miscounts.                               │
  │                                                                 │
  │  2. PARSE, DO NOT PATTERN-MATCH                                 │
  │     JSON.parse the payload and read the NAMED field. Never grep │
  │     the raw blob: it cannot tell which field a value came from, │
  │     and it truncates at the first escaped quote.                │
  │                                                                 │
  │  3. SPLIT INTO SHELL WORDS, MATCH WORD SEQUENCES                │
  │     Quotes contribute content and vanish as delimiters, so a    │
  │     quoted flag is still that flag while a commit message that  │
  │     merely mentions one is not a command. Match at a COMMAND    │
  │     POSITION, skipping global options - adjacency alone is      │
  │     defeated by `git -c core.pager=cat push`.                   │
  │                                                                 │
  │  4. STOP HOOKS MUST EXIT 0                                      │
  │     On the Stop event, exit 2 makes Claude Code retry the stop, │
  │     creating an infinite loop. Stop hooks may warn but must     │
  │     ALWAYS exit 0.                                              │
  │                                                                 │
  │  5. NEVER WRITE TO STDERR ON EXIT 0                             │
  │     It is not surfaced. Three notices sat in this plugin for    │
  │     months, correct and unseen. Exit-0 output is JSON.          │
  │                                                                 │
  │  6. ALL INPUT COMES FROM STDIN                                  │
  │     A JSON blob with tool_input fields. No file arguments, no   │
  │     environment-variable contracts, no assumptions about the    │
  │     working directory. Anything interpolated into a path        │
  │     (session_id) is validated before use.                      │
  │                                                                 │
  └─────────────────────────────────────────────────────────────┘
```

### How Each Hook Implements the Pattern

Every handler follows the same structural template: read stdin, `JSON.parse`, read one
named field, decide. Here is how it mapped across all **eight** handlers as of 8.x; the five marked retired left with `toque-guard` in 9.0.0. Handler filenames and the retired plugin's name are given throughout in their **current** spelling; the 10.0.0 rename changed both, so at the older tags where these files still exist they carry their pre-rename names. The columns that
used to appear here — "jq Path" and "grep+sed Fallback" — are gone with the ladder they
described; the deep links formerly pointed at line numbers inside `plugin.json`, which no
longer contains hooks at all.

| Handler | Event | Matcher | Field it reads | Decision it can return |
| :------ | :---- | :------ | :------------- | :--------------------- |
| [tq-session-start.js](plugins/toque/scripts/tq-session-start.js) | SessionStart | (none) | `source` | JSON `systemMessage` only |
| tq-migration-guard.js (retired 9.0.0) | PreToolUse | `Write\|Edit` | `tool_input.file_path` | deny (exit 2) / allow |
| tq-git-guard.js (retired 9.0.0) | PreToolUse | `Bash` | `tool_input.command` | deny / **ask** / allow |
| tq-track-change.js (retired 9.0.0) | PostToolUse | `Write\|Edit` | `tool_input.file_path`, `session_id` | JSON `systemMessage` only |
| tq-track-test.js (retired 9.0.0) | PostToolUse | `Bash` | `tool_input.command`, `session_id` | nothing (writes markers) |
| tq-session-stop.js (retired 9.0.0) | Stop | (none) | `session_id` | JSON `systemMessage` only |
| [tq-subagent-stop.js](plugins/toque/scripts/tq-subagent-stop.js) | SubagentStop | (none) | `reason` | nothing (appends to a log) |
| [tq-pre-compact.js](plugins/toque/scripts/tq-pre-compact.js) | PreCompact | (none) | (none) | JSON `systemMessage` only |

Two things this table now makes explicit that the old one hid. The **Matcher** column
reads "(none)" for four events rather than `*`: SessionStart, Stop, SubagentStop and
PreCompact have no tool to match on, and Claude Code silently ignores a matcher there —
the field was present and meaningless until a setup audit flagged it. And the git guard
is the only handler that can return **ask**: a hard reset and any command containing a
construct the guard cannot evaluate both prompt rather than being denied or waved through.

The three blocking hooks (Git Guard, Migration Guard, DB Deploy Guard) were the ones where the fail-open problem mattered most. If any of them cannot parse the input and the input actually contains a dangerous command, we have a security hole. That is why the jq-first-then-grep pattern existed.

Source: [scripts/tq-git-guard.js](https://github.com/krwhynot/toque/blob/main/scripts/tq-git-guard.js), [scripts/tq-migration-guard.js](https://github.com/krwhynot/toque/blob/main/scripts/tq-migration-guard.js), [plugins/toque/scripts/tq-session-start.js](https://github.com/krwhynot/toque/blob/main/plugins/toque/scripts/tq-session-start.js) — the `.sh` handlers these lines used to cite were deleted in 5.0.0

### The grep+sed Pattern Up Close

This section previously documented a `jq`-then-`grep`+`sed` fallback ladder as the design. **That pattern was removed in v5.0.0 and is recorded here as a defect, not a technique**, because it reads as reasonable and is not.

```bash
# REMOVED in v5.0.0 — do not reintroduce this shape.
COMMAND=$(echo "$INPUT" | jq -r ".tool_input.command // empty" 2>/dev/null)
[ -z "$COMMAND" ] && \
  COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | sed 's/"command":"//;s/"$//')
```

Three failures, all of them silent:

1. **It is not field-scoped.** `grep -o '"command":"..."'` takes the first key of that name anywhere in the payload, so a sibling object carrying its own `command` wins over the real `tool_input.command`.
2. **It truncates at the first quote.** `[^"]*` stops at any escaped quote inside the command, so what gets matched is a prefix of what will actually run.
3. **It cannot tell a command from text.** Nothing distinguishes an instruction from a quoted mention of one, which over-blocks (a commit message naming a force push) and under-blocks (an exemption token appearing outside the command field suppressing a real denial).

The replacement parsed the payload with `JSON.parse`, read the named field only, and split the command into shell words so quoted text contributed data rather than structure. That handler (`tq-git-guard.js`) and its acceptance corpus (`tests/fixtures/hook-corpus.json`, which encoded each of these three failures as a test) were retired with `toque-guard` in 9.0.0; the git history at tag `v8.0.0` holds both, under their pre-rename names.

Source (historical, v4.x): the inline hook commands carried by `.claude-plugin/plugin.json` at those tags. That file no longer holds hooks at all, so the line numbers this citation used to give no longer exist in it.

### Why Not Just Require jq?

This section argued against requiring a dependency, and 5.0.0 reversed it. The argument below is preserved because the reasoning is still worth reading and the counter-argument is specific, not a change of taste: a fallback ladder whose lower rung cannot parse JSON does not preserve the guarantee, it hides its absence. What follows is the original case, then why it lost:

1. **Discovery**: How does the user find out they need jq? A README line? A startup error? An install script? Every one of these has a failure mode.
2. **Enforcement**: What happens when jq is missing? If you block everything, the plugin is unusable. If you allow everything, the safety hooks are theater.

**5.0.0 chose the required dependency instead, and this is the paragraph that changed.** The old answer was that `jq` is optional but recommended, with a `grep`+`sed` path when it is absent. That reads as having it both ways, and it does not: the two paths do not enforce the same rules, so the guarantee silently depended on which one ran. The plugin now requires Node.js 18+ — already required by Claude Code — and has exactly one parsing path. On a host without it the guards do not run and Claude Code reports a hook error on every guarded event. That is a worse availability story and a better safety one, which is the correct direction for a security control: the failure is visible instead of silent.

The matrix below is the **pre-5.0.0 assessment**, kept as it was written. Its Verdict column records the answer of the day, not the current one:

| Approach | Strength | Failure Mode | Verdict (pre-5.0.0) |
| :------- | :------- | :----------- | :------ |
| **Required dependency** | Best quality when the tool is present. | The whole safety system degrades when the dependency is missing. | Bad default for safety hooks. |
| **Optional + fallback** | Works everywhere and improves when jq is available. | More implementation complexity, but failure stays controlled. | The sweet spot, as it looked then. |
| **Pure Bash** | No dependency management burden. | Fragile parsing on real-world payloads and edge cases. | Risky unless inputs are extremely simple. |

> Visual cue: read the Verdict column as a dated opinion. The failure mode in the first row is real, but 5.0.0 judged a loud failure preferable to a quiet one.

5.0.0 took the first row. Toque now requires Node.js 18 or later — already required by Claude Code — and has exactly one parsing path, so the same rules are enforced on every host that can run the guards at all. Where the guards cannot run, they are absent and loud rather than silently weaker.

---

## 12. Sources Index

Every source cited in this methodology, organized by topic. Each entry includes a one-sentence summary of the key insight that informed Toque's design.

### AI-Ready Codebases

- [Matt Pocock: "Your codebase is NOT ready for AI"](https://www.aihero.dev/how-to-make-codebases-ai-agents-love~npyke) - The 8 principles for AI-ready codebases, treating AI agents like a constantly arriving new starter who needs clear signposts to navigate your code.
- [Derick Chen: "Your code base isn't ready for AI"](https://www.buildwithdc.co/posts/your-code-base-isnt-ready-for-ai/) - Identifies 5 enterprise code smells that break AI agents: poor structure, distributed logic, acronyms, missing comments, and documentation distance from code.
- [Mark Mishaev: AI Harness Scorecard](https://github.com/markmishaev76/ai-harness-scorecard) - A deterministic scorecard with 31 checks across 5 categories, proving that AI readiness can be measured with numbers rather than opinions.
- [OpenAI: Harness Engineering](https://openai.com/index/harness-engineering/) - Introduces Context Engineering, Architectural Constraints, and Entropy Management, arguing that "the model is commodity, the harness is moat."
- [Shaharia Azam: AI Integration Framework](https://shaharia.com/blog/ai-integration-framework/) - Quality gates, AI-navigable context, and frictionless workflow, all built on a zero-trust mindset for AI contributions.
- [SuperGok: Agent Readiness Framework](https://supergok.com/agent-readiness-framework/) - An assessment framework spanning 8 axes and 5 maturity levels for measuring how ready a codebase is for autonomous agents.
- [NxCode: Harness Engineering Complete Guide](https://www.nxcode.io/resources/news/harness-engineering-complete-guide-ai-agent-codex-2026) - A comprehensive walkthrough of harness engineering patterns for AI coding agents, covering context injection, constraint systems, and feedback loops.
- [Developer Toolkit: File Organization for AI](https://developertoolkit.ai/en/shared-workflows/context-management/file-organization/) - File organization patterns that help AI assistants discover and navigate project structure without needing to ask.
- [Basti Ortiz: Coding Agents as First-Class Consideration](https://dev.to/somedood/coding-agents-as-a-first-class-consideration-in-project-structures-2a6b) - The 40% context window rule: if your agent spends more than 40% of its context on orientation, it has less than 60% left for actual work; vertical slicing beats horizontal for agent-friendly structure.

### CLAUDE.md Best Practices

- [Tembo: How to Write a Great CLAUDE.md](https://www.tembo.io/blog/how-to-write-a-great-claude-md) - "Even the best frontier models can only reliably follow around 200 distinct instructions," making brevity a functional requirement.
- [HumanLayer: Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) - "Never send an LLM to do a linter's job"; reveals that Claude Code wraps CLAUDE.md with an advisory caveat, meaning the agent already treats it as potentially disposable.
- [Allahabadi.dev: 7 CLAUDE.md Mistakes](https://allahabadi.dev/blogs/ai/7-claude-md-mistakes-developers-make/) - Reports that Boris Cherny (Claude Code creator) keeps his team's file at 2.5K tokens (roughly 100 lines), setting a practical upper bound.
- [Builder.io: CLAUDE.md Guide](https://www.builder.io/blog/claude-md-guide) - A comprehensive guide to structuring effective CLAUDE.md files with concrete patterns for instruction organization and prioritization.
- [Buildcamp: Ultimate Guide to CLAUDE.md](https://www.buildcamp.io/guides/the-ultimate-guide-to-claudemd) - End-to-end walkthrough of CLAUDE.md authoring, covering structure, anti-patterns, and real-world examples from production codebases.
- [Ogenki Blog: AI Coding Tips](https://blog.ogenki.io/post/series/agentic_ai/ai-coding-tips) - "CLAUDE.md is advisory (Claude CAN ignore). Hooks are deterministic (always run)." The distinction that shaped Toque's entire hook architecture.

### Production Readiness

- [Google SRE Book Ch. 32: The Evolving SRE Engagement Model](https://sre.google/sre-book/launching/) - The Production Readiness Review framework covering system architecture, instrumentation, emergency response, capacity planning, change management, and performance.
- [Cortex: Production Readiness](https://www.cortex.io/) - Bronze, Silver, and Gold maturity tiers for production readiness, providing a graduated model that Toque adapted for its own tiering system.
- [GitLab: Production Readiness Review](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/readiness/) - "Enough documentation, observability, and reliability for production scale," defining the minimum bar for shipping safely.
- [Supabase: Managing Environments](https://supabase.com/docs/deployment/managing-environments) - "Use a CI/CD pipeline rather than deploying from your local machine," the principle behind Toque's DB Deploy Guard.
- [DORA: DevOps Research and Assessment](https://dora.dev/) - The four key metrics for software delivery performance (deployment frequency, lead time, change failure rate, time to restore), providing the empirical foundation for what "good" delivery looks like.

### Context Engineering

- [Steven Poitras: Three-Tier Context System](https://agenticthinking.ai/blog/three-tier-context/) - A tiered context architecture (Ephemeral, Internal, Public, Rules) that maps directly to Toque's always-loaded, conditionally-loaded, and on-demand context strategy.
- [Colin McDonnell (Zod): AI Autodiscovery in package.json](https://colinhacks.com/essays/ai-autodiscovery-in-package-json) - Proposes standardized fields in package.json that let AI agents discover project capabilities without parsing documentation.
- [Ryan Walker: AGENTS.md Standard](https://rywalker.com/research/agents-md-standard) - A proposed standard for agent context files, providing structured metadata that AI agents can consume to understand project conventions and constraints.

### Claude Code Plugin Architecture

- [Anthropic: Official Plugin Examples](https://github.com/anthropics/claude-code/tree/main/plugins) - The official repository of Claude Code plugin examples and patterns that Toque's plugin structure is built on.
- [Anthropic: Plugin File Structure](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-structure/SKILL.md) - The canonical reference for how plugins organize their files, defining the `.claude-plugin/plugin.json`, `commands/`, `agents/`, `skills/`, and `scripts/` directories.
- [Claude Code: Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide) - Official documentation for the hooks system, covering event types (SessionStart, PreToolUse, PostToolUse, Stop, PreCompact), matchers, exit codes, and stdin JSON format.
- [Claude Code: Memory](https://code.claude.com/docs/en/memory) - Documentation for Claude Code's memory and context file system, explaining how CLAUDE.md, CLAUDE.local.md, and child context files interact.

### Database and CI/CD

- [Supabase: Agent Skills](https://github.com/supabase/agent-skills) - A library of AI agent skills for database operations, demonstrating safe patterns for agent-driven schema changes.
- [Supabase: Database Migrations](https://supabase.com/docs/guides/deployment/database-migrations) - Migration best practices including the "never edit a deployed migration" principle that Toque's Migration Guard enforces.
- [Supabase: Branching](https://supabase.com/docs/guides/deployment/branching) - Environment branching for databases, enabling preview environments where AI agents can safely test schema changes before they hit production.

---

*Sources last verified: March 2026. If a link is dead, search for the author name and article title.*
