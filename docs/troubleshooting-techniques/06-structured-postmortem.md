# Structured Postmortem (Blameless Incident Review)

## What It Is

A Structured Postmortem is a formalized incident review that goes beyond "what happened and how we fixed it" to capture the full incident timeline, contributing factors (not just root cause), concrete action items with owners and deadlines, and follow-up verification. It is explicitly **blameless** — focused on systemic failures, not individual mistakes.

The current troubleshooting log captures the investigation and fix. A postmortem captures the FULL STORY: how the incident was detected, how it was communicated, how long it took to contain, what decisions were made under pressure, what those decisions cost, and what systemic changes prevent recurrence.

The critical distinction: a troubleshooting log is for the engineer who fixes the bug. A postmortem is for the organization that learns from the incident. Different audiences, different content, different format.

## Enterprise Origin

**Source:** Google SRE blameless postmortem culture, PagerDuty incident lifecycle (triggered → acknowledged → resolved), Microsoft Sentinel incident management workflow.

Google's SRE practice treats postmortems as a core cultural artifact. The blameless principle means: *"We assume that people involved in an incident did the best they could with the information they had at the time."* The postmortem focuses on systemic factors — missing alerts, unclear runbooks, insufficient automation — not on who made a mistake.

PagerDuty's incident model includes structured post-incident artifacts: notes appended during the incident for context, status updates for stakeholders, and responder requests that track who was involved and when. The lifecycle (triggered → acknowledged → resolved) creates a natural timeline that the postmortem can reference. PagerDuty's "Past Incidents" feature also enables learning: *"Responders can see who was involved in a previous Incident, when these types of Incidents happened, and dive into Incident details to discover the remediation steps that were taken."*

Microsoft Sentinel's incident workflow demonstrates enterprise-grade incident tracking: incidents have assigned owners, severity levels, status tracking, tags for categorization, and comments for activity logging. The workflow explicitly includes triage, investigation, and remediation as tracked stages with actions at each step.

## How It Works

### 1. Postmortem Trigger Criteria

Not every bug needs a postmortem. Generate one when:

| Trigger | Reasoning |
|---------|-----------|
| SEV1 or SEV2 incident | High business impact warrants organizational learning |
| Incident lasted > 1 hour | Extended incidents reveal process gaps |
| Containment required rollback or emergency action | Emergency actions indicate prevention gaps |
| Same root cause category appeared 2+ times | Recurrence indicates systemic issue |
| Incident was detected by users, not monitoring | Detection gaps need systemic fixes |
| Data integrity was affected | Data issues have long-tail consequences |

SEV3/SEV4 issues get standard troubleshooting logs, not full postmortems.

### 2. Postmortem Template

```markdown
# Postmortem: {Incident Title}

**Date:** {date}
**Severity:** SEV{N}
**Duration:** {time from detection to resolution}
**Time to detect:** {time from incident start to first alert/report}
**Time to contain:** {time from detection to service restoration}
**Time to resolve:** {time from detection to permanent fix deployed}
**Author:** {who wrote this postmortem}
**Reviewers:** {who reviewed it}

## Executive Summary
{2-3 sentences: what happened, what was the impact, what prevented recurrence}

## Timeline
| Time | Event | Actor |
|------|-------|-------|
| {HH:MM} | {First symptom or alert} | {System/Person} |
| {HH:MM} | {Detection — how was it noticed?} | {System/Person} |
| {HH:MM} | {Severity classified as SEV{N}} | {Person} |
| {HH:MM} | {Containment action taken} | {Person} |
| {HH:MM} | {Service restored} | {Person} |
| {HH:MM} | {Root cause identified} | {Person} |
| {HH:MM} | {Permanent fix deployed} | {Person} |
| {HH:MM} | {Incident closed} | {Person} |

## Impact
- **Users affected:** {number or percentage}
- **Services affected:** {list}
- **Data impact:** {none | read degradation | write failures | data corruption}
- **Revenue impact:** {estimated if applicable}
- **SLA impact:** {was any SLA breached?}

## Root Cause
{Clear, specific root cause — not "human error" but the systemic condition that
allowed the error to have impact}

## Contributing Factors
{Root cause is singular. Contributing factors are the additional conditions that
made the incident possible or made it worse. List ALL of them:}

1. {Factor}: {why it contributed}
2. {Factor}: {why it contributed}
3. {Factor}: {why it contributed}

## What Went Well
{Things that WORKED during the incident — fast detection, good containment,
effective communication. Reinforcing what works is as important as fixing what
didn't.}

1. {What went well}: {why it helped}

## What Went Wrong
{Things that DIDN'T work — slow detection, unclear runbooks, missing
automation, communication gaps.}

1. {What went wrong}: {what the impact was}

## Action Items
| ID | Action | Owner | Priority | Deadline | Status |
|----|--------|-------|----------|----------|--------|
| 1 | {Specific action to prevent recurrence} | {Name} | P1/P2/P3 | {Date} | Open |
| 2 | {Guardrail improvement} | {Name} | P1/P2/P3 | {Date} | Open |
| 3 | {Process improvement} | {Name} | P1/P2/P3 | {Date} | Open |

## Lessons Learned
{What did we learn that applies beyond this specific incident?}

## Related Incidents
{Links to past incidents with the same root cause category, contributing
factors, or affected services}
```

### 3. Blameless Principles

When writing the postmortem:
- Replace "Person X forgot to..." with "The process did not include a check for..."
- Replace "Person X made a mistake..." with "The system allowed {action} without {safeguard}..."
- Focus on what the SYSTEM should prevent, not what the PERSON should remember
- Treat human error as a symptom of systemic gaps, not as a root cause

### 4. Action Item Follow-Up

Action items without follow-up are performative. Track them:
- P1 action items: follow up within 1 week
- P2 action items: follow up within 2 weeks
- P3 action items: follow up within 1 month
- Any action item older than its deadline: flag in next troubleshooting session

### 5. Postmortem Review

Postmortems are reviewed, not just filed:
- Share with the team (or link from the plan if plan-linked)
- Identify action items that overlap with existing tech debt
- Check if the contributing factors appear in other areas of the codebase

## Why It Prevents Gaps

- **Captures contributing factors, not just root cause.** Root cause analysis finds the trigger. Postmortems find the conditions. Removing the trigger fixes one bug; removing the conditions fixes a class of bugs.
- **Creates accountability for prevention.** Action items with owners and deadlines convert "we should fix this" into tracked work.
- **Builds organizational memory.** Related incidents linked across postmortems reveal systemic patterns invisible in individual incident logs.
- **Reinforces what works.** "What Went Well" sections identify effective practices to preserve, not just problems to fix.
- **Blameless culture encourages honest reporting.** When postmortems assign blame, people hide information. When postmortems focus on systems, people share what actually happened.

## Status Before Implementation

Our troubleshooting log template captures Phase-by-phase investigation, root cause, and a brief "Prevention" section. It does not include:
- Incident timeline (detection → containment → resolution)
- Impact assessment (users, services, data, revenue)
- Contributing factors beyond root cause
- What went well during the incident
- Action items with owners and deadlines
- Follow-up tracking
- Related incident linking
- Blameless language guidance

The knowledge base entries are terse summaries: category, symptom, root cause, fix. They don't capture the organizational learning that prevents recurrence at a systemic level.

## Implementation

- Add postmortem template to troubleshooting log output for SEV1/SEV2 incidents
- Add postmortem trigger criteria checklist
- Add contributing factors section (separate from root cause)
- Add "What Went Well" and "What Went Wrong" sections
- Add action items table with owner, priority, deadline, status
- Add blameless language guidance
- Add follow-up tracking mechanism (flag overdue action items in future troubleshooting sessions)
- Add related incident linking to knowledge base correlation
- Location: `docs/troubleshooting/postmortems/YYYY-MM-DD-{incident-slug}.md`

## References

- Google SRE Book: "Postmortem Culture: Learning from Failure" chapter
- PagerDuty: Incident lifecycle and post-incident artifacts (developer.pagerduty.com/api-reference)
- PagerDuty: Past Incidents for historical correlation (developer.pagerduty.com/api-reference)
- Microsoft Sentinel: Incident management workflow (learn.microsoft.com/en-us/azure/sentinel/incident-navigate-triage)
