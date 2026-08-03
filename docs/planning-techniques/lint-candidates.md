# Lint Rule Candidates

Findings from the Phase 5 rubric-free holistic pass that mapped to no existing
criterion. Each entry is a candidate for promotion into
[lint-registry.md](lint-registry.md) — or for explicit rejection, recorded here so
the same candidate is not re-litigated every audit.

This file is append-only for the holistic pass and owner-curated otherwise. The
pass itself never gates; a finding here is a claim that the *rubric* has a gap, not
that any particular plan does.

Why this exists: every enforcement mechanism in Phase 5 makes the judge honest
about the criteria it was given. None of them can notice that the criteria are
incomplete. A plan can satisfy every rule and still fail in production for a reason
no rule names. The holistic pass is the only mechanism looking for that class, and
this file is where its output lands.

Format per entry:

```markdown
## {date} — {plan-name}
**Finding:** {what the rubric-free judge said would fail in production}
**Maps to:** none (checked against the registry as of {date})
**Proposed rule:** {draft LINT text, if the finding generalises}
**Status:** proposed | promoted as LINT-NN | rejected ({reason})
```

## Candidates

*(none yet — the holistic pass has not run against a real plan)*
