# Structured Peer Review with Reading Time

## What It Is

Structured Peer Review is a formalized human review process that requires dedicated reading time, structured comment collection, and facilitated discussion before a plan can proceed to execution. Unlike ad-hoc "can you look at this?" reviews, it follows a specific protocol: reviewers get dedicated time to read the plan (typically 10-15 minutes), write comments independently (which prevents groupthink), and then discuss each comment as a group. The review produces a ternary outcome -- Accept, Needs Rework, or Reject -- with documented rationale for each decision.

The key insight is that automated audits catch structural gaps but miss business context, political constraints, organizational dynamics, and tacit knowledge that only humans possess. A plan can pass every automated check with flying colors and still fail because the VP of Sales already promised the client a different timeline, or because the platform team is deprecating the API the plan depends on. Structured Peer Review is the mechanism that catches these human-domain gaps.

## Enterprise Origin

**AWS Prescriptive Guidance ADR Process** describes the core protocol: "The review meeting should start with a dedicated time slot to read the ADR. On average, 10 to 15 minutes should be enough. During this time, each team member reads the document and adds comments and questions to flag unclear topics. After the review phase, the ADR owner reads out and discusses each comment with the team."

**Google Code Review (Software Engineering at Google)** by Titus Winters, Tom Manshreck, and Hyrum Wright documents Google's requirement that at least one qualified reviewer must approve a change before it can be merged. Chapter 9 details the review culture: reviews are not optional, reviewers are expected to provide substantive feedback, and the process is designed to create shared understanding across the team.

**Architecture Review Boards (ARBs)** at enterprise organizations formalize review gates for architecturally significant decisions. Before a major technical direction can be adopted, it must pass through a review board that evaluates it against organizational standards, existing systems, and strategic direction. The ARB pattern has been adopted across financial services, healthcare, and government agencies as a governance mechanism.

## How It Works

### Step 1: Preparation

The plan author designates the document as "Ready for Review" and identifies reviewers. A minimum of 1 reviewer is required; 2-3 reviewers are recommended. Reviewers should be selected for complementary perspectives: at least one person familiar with the affected codebase, one person with business/domain context, and ideally one person from an adjacent team that might be impacted.

### Step 2: Reading Phase (10-15 minutes)

Each reviewer reads the plan independently. No discussion is permitted during this phase. Each reviewer writes comments directly in a structured format:

- **Section reference**: Which part of the plan the comment pertains to
- **Comment type**: One of Question / Concern / Suggestion / Blocker
- **The comment itself**: A clear, written statement

The silent reading phase is critical. Without it, the loudest voice dominates, reviewers anchor on the presenter's framing, and subtle gaps get overlooked because discussion drifts to surface-level issues. Written comments during silent reading are more precise and substantive than verbal reactions.

### Step 3: Discussion Phase

The plan owner reads each comment aloud. The group discusses. For each comment, the group decides one of three dispositions:

- **Address Now**: The comment identifies a real issue that must be resolved before the plan can proceed
- **Defer**: The comment is valid but can be addressed during execution rather than planning
- **Reject with reason**: The comment is noted but the group disagrees, with documented rationale

### Step 4: Action Items

Any changes requiring rework are assigned to specific people with deadlines. Action items are concrete and verifiable, not vague ("think about this more").

### Step 5: Decision

The review concludes with one of three outcomes:

- **Accept**: The plan is approved to proceed to the build phase
- **Needs Rework**: The plan requires changes and must be re-reviewed after those changes are made
- **Reject**: The plan is sent back to an earlier phase (e.g., back to planning or even back to scoping)

### Step 6: Record

The review outcome, reviewer names, date, action items, and key discussion points are recorded. This creates an audit trail and ensures accountability.

## Why It Prevents Gaps

- **Catches business context gaps that automated tools miss.** Humans know things like "Legal won't approve that approach" or "The CFO froze all non-critical spending last week." No amount of codebase scanning can detect these constraints.

- **Prevents groupthink through independent reading before discussion.** When reviewers form opinions independently before hearing others, the review captures a wider range of perspectives. Without silent reading, early speakers anchor the conversation and dissenting views go unvoiced.

- **Creates shared understanding.** After the review, every reviewer understands the plan deeply. This distributes knowledge across the team and reduces bus factor risk.

- **Catches organizational gaps.** Reviewers from adjacent teams spot coordination needs: "Team X is doing something similar, you should coordinate" or "The infrastructure team is migrating to a new deployment pipeline next month."

- **Surfaces tacit knowledge.** Experienced engineers spot risks from past experience that are not documented anywhere: "We tried this approach in 2024 and it failed because the database couldn't handle the write amplification."

- **Forces the plan author to make the document readable and self-contained.** If the plan requires verbal explanation to be understood, it is not ready for review. This quality pressure improves the plan itself.

- **Creates accountability.** Reviewers are named in the review record, so they have skin in the game. A reviewer who approves a plan that later fails due to an obvious gap they should have caught bears some responsibility.

- **Prevents "rubber stamp" reviews.** The structured comment requirement means reviewers must produce written feedback. This is a much higher bar than nodding along in a meeting.

## Status Before Implementation

Our Phase 5 Audit is 100% automated. Five AI specialist agents score the plan across dimensions and produce gap matrices. Deterministic pre-checks run keyword searches. Codebase verification checks referenced files. Gap verification produces four structured matrices.

There is no human review step built into the workflow.

The automated audit catches structural gaps -- missing sections, unverified assumptions, uncovered scenarios, missing cross-cutting concerns. But it cannot catch:

- "The VP of Sales already promised the client a different timeline"
- "Legal flagged this data handling approach last quarter"
- "The platform team is deprecating that API next month"
- "We tried this exact approach two years ago and it failed for reasons not documented in the codebase"
- "The team lead is going on parental leave in three weeks and this plan assumes their availability"
- "Budget for this initiative was quietly cut in the last planning cycle"

These are human-context gaps that no amount of automated analysis can detect. They live in people's heads, in Slack conversations, in meeting notes, and in organizational memory. The only way to surface them is to put the plan in front of humans who possess that context.

## Implementation (Completed)

### Human Review Gate Between Phase 5 (Audit) and Phase 6 (Build)

After the automated audit completes, insert a human review checkpoint before Build begins.

**Auto-generate a review checklist from audit findings** to give reviewers a structured starting point:

- Audit score summary (overall score and per-dimension scores)
- Gap summary (count and severity of identified gaps)
- Top 5 risks identified by the audit
- Key assumptions that remain unverified
- Cross-cutting concerns flagged as partially addressed

**Require minimum 1 human reviewer sign-off** before Build begins.

### Status Tracking

Track review status in status.json:

```json
{
  "review": {
    "reviewers": [
      {
        "name": "Jane Smith",
        "date": "2026-03-15",
        "decision": "accepted"
      },
      {
        "name": "Bob Chen",
        "date": "2026-03-15",
        "decision": "accepted"
      }
    ],
    "outcome": "accepted",
    "comments": 12
  }
}
```

Valid values for `outcome`: `"accepted"`, `"rework"`, `"rejected"`.

### Manifest Integration

Add a review section to manifest.md linking to review notes so there is a permanent record alongside the plan.

### Solo Developer Protocol

For solo developers who do not have a team to review their plans, use a self-review protocol with specific prompts:

- "If I were my boss, what would I question?"
- "What did I assume that I haven't verified?"
- "What would break if the timeline slipped 2 weeks?"
- "What organizational context am I taking for granted?"
- "Who else might be affected by this work that I haven't consulted?"

### Review Skip Waiver

Allow the review to be skipped with an explicit waiver for time-critical plans. The skip must be logged in status.json with the reason and the person who authorized it. This ensures that skipping review is a conscious decision, not a default.

## References

- AWS Prescriptive Guidance: ADR Process (docs.aws.amazon.com/prescriptive-guidance/latest/architectural-decision-records/adr-process.html)
- Titus Winters, Tom Manshreck, Hyrum Wright, "Software Engineering at Google" (Chapter 9: Code Review)
- Mark Richards, "Software Architecture Monday" - Architecture Decision Records episode
- RedHat, "Why you should use ADRs" (redhat.com/architect/architecture-decision-records)
