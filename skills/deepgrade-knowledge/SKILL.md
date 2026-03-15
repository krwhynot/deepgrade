---
name: deepgrade-knowledge
description: (deepgrade) Knowledge about the DeepGrade methodology for codebase audit and documentation. Covers enterprise best practices for discovery, risk assessment, and report generation. Auto-invoked during DeepGrade audits.
---

# DeepGrade Methodology

This skill contains the methodology and enterprise research backing the Phase 2
DeepGrade codebase audit.

## The DeepGrade

### Grade Category 1: Documentation as the Foundation
Before AI can help with a codebase, the codebase must be documented. Feature
inventories, dependency maps, and business rule documentation are prerequisites,
not nice-to-haves.

### Grade Category 2: Phased Delivery Over Big-Bang Releases
Risk-classified modules should be modified in phases: safe modules first, then
medium-risk, then high-risk. Each phase has entry/exit criteria and regression
testing requirements.

### Grade Category 3: Operational Readiness
With documentation (Category 1) and risk assessment (Category 2) in place, the
codebase needs ongoing safety nets to support continuous development. Category 3
measures whether guardrails, context files, and test coverage are sufficient
for safe changes. Based on Google SRE's Production Readiness Review framework.

Four deliverables:
- 3A. Guardrail Coverage: Are automated safety nets installed? (hooks, gates, CI)
- 3B. Context Currency: Are docs and baselines fresh or stale?
- 3C. Test Safety Net: Is test coverage adequate for high-risk modules?
- 3D. Change Readiness Score: GREEN/YELLOW/ORANGE/RED composite rating

## Enterprise Best Practices (from 16-source research)

### Risk Assessment
- Risk = business criticality x dependency exposure (not just LOC)
- Fan-in > 20 = danger zone (PViz framework)
- Fan-out > 40 = fragile to external changes
- Classify debt: CRITICAL (must fix) / MANAGED (documented) / DEFERRED (low risk)

### Discovery
- Start with "outcomes that cannot fail," not component inventory
- Triangulate: static analysis + runtime traces + scheduling layer
- Phase discovery in layers: structure first, then coupling, then risk

### Documentation
- Audit-ready artifacts emerge as a by-product of development (Agile V)
- 67% of legacy systems lack reliable documentation (Replay.build, $3.6T crisis)
- Connect every finding to a business outcome

### Report Generation
- Tell a story, not just data (TechDebt.best)
- Severity before category: CRITICAL > HIGH > MEDIUM > LOW > INFO
- Every finding must reference specific files with paths
- The report should be useful to someone who has never seen the codebase

### Self-Audit (Epistemic Transparency)
- Every finding carries a verification tier: A (tool-verified), B (code-reading), C (pattern inference)
- Evidence basis format: `{Tier}-{Confidence}: {method}`
- Cascade risk is category-based (auth/payment/required-mod), not numeric fan-out
- The self-audit-knowledge skill is the single source of truth for tier definitions,
  failure mode flags, and cascade risk rules
- HIGH confidence + Tier C = SUSPECT — always spot-check these combinations

## Stack Detection

The Phase 2 orchestrator detects the codebase stack automatically:
- React/TypeScript: package.json, src/ directories, .tsx files
- C#/.NET: *.sln, *.csproj, Controllers/, Forms/
- Python: pyproject.toml, requirements.txt, manage.py
- Rust: Cargo.toml
- Go: go.mod

Stack-specific patterns are passed to each agent so they grep for the right
file extensions and import patterns.
