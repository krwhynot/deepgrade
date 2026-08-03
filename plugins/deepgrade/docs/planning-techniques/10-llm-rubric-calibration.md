# LLM Rubric Calibration

## What It Is

LLM Rubric Calibration is a technique that makes AI-based plan scoring consistent and reproducible by defining explicit rubrics with reasoning requirements, calibration examples, and consistency tracking.

Without calibration, two LLM audit runs on the same plan can produce different scores because the scoring criteria are implicit in the model's interpretation. With calibration, scores are anchored to concrete definitions and examples, making them deterministic enough to track over time and compare across plans.

The core principle: **if you can't define what a "3/5" looks like concretely, you can't score reliably.**

## Enterprise Origin

**Source: Anthropic's "Create Strong Empirical Evaluations" documentation** which recommends:

> "Have detailed, clear rubrics: 'The answer should always mention Acme Inc. in the first sentence. If it does not, the answer is automatically graded as incorrect.'"

> "Empirical or specific: instruct the LLM to output only 'correct' or 'incorrect', or to judge from a scale of 1-5. Purely qualitative evaluations are hard to assess quickly and at scale."

And critically:

> "Encourage reasoning: Ask the LLM to think first before deciding an evaluation score, and then discard the reasoning. This increases evaluation performance, particularly for tasks requiring complex judgement."

Additional enterprise origins:

- **Educational assessment theory (Bloom's Taxonomy rubrics)** -- structured scoring frameworks that define observable evidence per mastery level.
- **Standardized testing methodology (SAT/GRE scoring guides)** -- detailed anchor papers and scoring guides that calibrate human scorers to a common scale.
- **Enterprise performance review calibration sessions** -- where managers meet to align on what "Exceeds Expectations" means concretely before scoring employees, reducing inter-rater variance.

## How It Works

### 1. Define Explicit Rubrics per Dimension per Score Level

For each of the 8 plan-auditor dimensions, define what each score (1-5) looks like concretely:

```
Dimension 1: Problem Definition

5/5: Problem statement with quantified business impact, current-state evidence
     (file paths, metrics), specific success criteria with measurable thresholds.
     Example: "Receipt printing fails for 12% of Canadian transactions (see logs/
     errors_q4.csv). Success = 0% failure rate measured over 30 days."

4/5: Clear problem with business impact stated but not quantified. Current
     state described with some evidence. Success criteria defined but not all
     measurable.

3/5: Problem stated but impact is vague ("it's important"). Current state
     described without evidence. Success criteria exist but are subjective.

2/5: Problem mentioned but not clearly separated from solution. No current
     state analysis. Vague success criteria ("it works").

1/5: No problem statement, or problem is actually a solution in disguise. No
     success criteria. Reader cannot understand WHY this work matters.
```

### 2. Require Reasoning Before Scoring

The auditor must output its reasoning in a structured format BEFORE assigning a score:

```
Dimension 1 Analysis:
- Problem statement found in section 1.1: "Receipt printing fails..." [PRESENT]
- Business impact quantified: "12% failure rate" [PRESENT]
- Current state evidence: references logs/errors_q4.csv [VERIFIED - file exists]
- Success criteria: "0% failure rate over 30 days" [MEASURABLE]
Score: 5/5 (matches rubric level 5: quantified impact + evidence + measurable criteria)
```

The reasoning serves two purposes: it forces the auditor to ground its score in observable evidence, and it makes the score auditable by humans who can check whether the reasoning supports the conclusion.

### 3. Calibration Examples

Provide 2-3 example plan excerpts per dimension with pre-assigned "correct" scores. The auditor must score these examples correctly before scoring the actual plan. If calibration fails, the auditor's methodology is suspect.

```
Calibration Check for Dimension 1:
  Example A (expected: 5/5): [plan excerpt with quantified impact + evidence]
  Example B (expected: 2/5): [plan excerpt with vague problem statement]
  Example C (expected: 3/5): [plan excerpt with stated but unquantified impact]

Auditor scored: A=5, B=2, C=3 --> CALIBRATION PASSED
Auditor scored: A=5, B=4, C=3 --> CALIBRATION FAILED (B off by 2 points)
```

### 4. Consistency Tracking

Store scores per plan version. If the same plan is re-audited without changes, scores should be within +/- 0.5 of the previous audit. Larger variance indicates calibration drift.

### 5. Cross-Auditor Validation

Periodically run the same plan through the auditor twice and compare scores. If variance > 1 point on any dimension, rubrics need tightening.

## Why It Prevents Gaps

- **Makes scoring reproducible:** same plan = same score (within tolerance). Without this, audit results are noise.
- **Prevents score inflation:** explicit rubrics prevent "generous" scoring where everything gets 4/5 because the auditor defaults to positive.
- **Prevents score deflation:** explicit rubrics prevent "everything is bad" bias where the auditor defaults to negative.
- **Reasoning requirement catches scoring errors:** if the reasoning says "all criteria met" but the score is 3/5, the contradiction is visible and correctable.
- **Calibration examples anchor the scale** to concrete reality (not abstract ideals). A "3/5" means the same thing every time.
- **Enables trend tracking:** scores over time are meaningful only if the scale is consistent. A plan improving from 3/5 to 4/5 should reflect real improvement, not calibration drift.
- **Makes audit reports actionable:** "You scored 3/5 because [specific missing items per rubric]" vs "You scored 3/5" with no explanation.
- **Reduces noise in gap detection:** if scoring is inconsistent, gap matrices based on scores are unreliable. Calibrated scoring produces reliable gap data.

## Status Before Implementation

Our plan-auditor has 8 dimensions with question-based criteria (e.g., "Is the problem being solved clearly stated?") but **no explicit rubric defining what each score level (1-5) looks like**. The auditor instruction says "Score honestly. A plan with no timeline is a 1/5 on dimension 6, period." but this is one example, not a full rubric.

Two different audit runs could score the same plan differently because the boundary between 3/5 and 4/5 is implicit. Our confidence tiers (HIGH/MEDIUM/LOW with A/B/C) apply to evidence quality but not to scoring consistency. We have no calibration mechanism -- no reference examples, no consistency tracking, no variance detection.

## Implementation (Completed)

- **Add explicit rubric definitions (1-5) for all 8 dimensions** in the plan-auditor agent. Each rubric level must have:
  - A definition (what this score means)
  - Minimum requirements (what must be present)
  - One concrete example (what a plan excerpt at this level looks like)

- **Add "reasoning before scoring" requirement** to the auditor workflow:
  1. List what evidence was found for this dimension
  2. Map evidence to rubric criteria
  3. Select the rubric level that matches
  4. Output the score with rubric reference

- **Add calibration examples as a test set:** 3 example plan excerpts with known scores. Before each audit, run calibration check -- score the examples, verify they match expected scores.

- **Track score consistency in status.json:**
  ```json
  {
    "audit_history": [
      {
        "date": "2026-03-19",
        "plan_version": "2.1.0",
        "scores": { "d1": 4, "d2": 5, "d3": 3, "d4": 4, "d5": 5, "d6": 4, "d7": 3, "d8": 4 },
        "calibration": "PASSED"
      }
    ]
  }
  ```

- **Add variance check:** if re-auditing an unchanged plan produces scores differing by > 1 point on any dimension, flag calibration drift in the audit report.

- **Add to audit report output:**
  ```
  Calibration: PASSED (3/3 examples scored correctly)
  ```
  or:
  ```
  WARNING: Calibration drift detected on Dimension 3 (previous: 4, current: 2).
  Rubric tightening recommended.
  ```

## References

- Anthropic, "Create Strong Empirical Evaluations" (docs.anthropic.com/en/docs/test-and-evaluate/develop-tests)
- Anthropic, "Building Effective Agents" evaluation patterns (anthropic.com/research/building-effective-agents)
- Bloom's Taxonomy rubric design methodology
- Enterprise performance review calibration practices
