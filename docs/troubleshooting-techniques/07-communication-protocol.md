# Communication Protocol (Incident Stakeholder Management)

## What It Is

A Communication Protocol defines WHO gets notified, WHEN, and with WHAT information during an incident. It separates the engineering response (debug and fix) from the communication response (keep stakeholders informed). Without a protocol, communication either doesn't happen (stakeholders learn about outages from customers) or becomes ad-hoc (the engineer debugging the issue is also answering Slack messages, slowing both activities).

Enterprise incident management treats communication as a separate, parallel track to investigation. In Google's SRE model, the Incident Commander delegates communication to a dedicated Communications Lead. In PagerDuty's model, "Status Updates" are a distinct artifact type: *"Status Updates are updates for stakeholders who are not responding to incidents."* The update goes to people who need to KNOW about the incident, not people who are WORKING on the incident.

The communication protocol is severity-driven. A SEV4 bug needs no communication beyond a log entry. A SEV1 production outage needs real-time stakeholder updates, a status page update, and possibly customer communication. The protocol removes the decision "should I tell anyone?" and replaces it with a lookup table.

## Enterprise Origin

**Source:** PagerDuty incident communication model, Google SRE Incident Commander framework, Microsoft Sentinel incident workflow.

PagerDuty's incident model separates communication artifacts from investigation artifacts:
- **Notes**: Context appended by responders during investigation (internal, technical)
- **Status Updates**: Updates for stakeholders not actively responding (external, business-level)
- **Responder Requests**: Requests for specific people to join the response (escalation)

This three-way split ensures that technical investigation notes don't get mixed with stakeholder communications, and that escalation requests are tracked separately from both.

PagerDuty's escalation policy model automates the "who to notify" decision: *"An Escalation Policy determines what User or Schedule will be Notified and in what order."* Escalation Rules define tiers — if the first tier doesn't acknowledge within a timeout, the next tier is notified automatically. This removes human judgment from the notification decision during high-stress incidents.

Google's SRE Incident Commander framework assigns communication as a dedicated role. The IC doesn't debug — they coordinate. And they don't communicate — they delegate communication to a Communications Lead. This role separation prevents the common failure mode where the best debugger is also the person answering Slack, doing neither well.

Microsoft Sentinel's incident workflow includes explicit communication actions: assign ownership, update status, change severity, add tags, and add comments to log actions. Each of these is a communication act visible to the team, creating an audit trail of the incident response.

## How It Works

### 1. Communication Cadence by Severity

| Severity | Internal Update | Stakeholder Update | Status Page | Customer Comms |
|----------|----------------|-------------------|-------------|----------------|
| SEV1 | Every 15 min | Every 15 min | Immediately | If customer-facing |
| SEV2 | Every 30 min | Every 30 min | If customer-facing | On request |
| SEV3 | On resolution | On resolution | No | No |
| SEV4 | Log only | No | No | No |

### 2. Update Template (for stakeholder communication)

Each update follows a consistent format so recipients can quickly parse:

```markdown
## Incident Update: {Title}
**Severity:** SEV{N}
**Status:** {Investigating | Identified | Containment Applied | Monitoring | Resolved}
**Updated:** {timestamp}

**Current state:** {1-2 sentences: what's happening right now}
**Impact:** {who is affected and how}
**Next update:** {when the next update will be sent}
**ETA to resolution:** {estimate or "investigating"}
```

### 3. Communication Decision Points

At each phase of the troubleshooting process, check if communication is needed:

| Phase | Communication Trigger | Action |
|-------|----------------------|--------|
| Phase 0: Triage | Severity classified as SEV1/SEV2 | Send initial notification |
| Phase 1: Containment | Containment applied or failed | Send containment status |
| Phase 2: Root Cause | Root cause identified | Send update with cause and ETA |
| Phase 5: Fix | Fix deployed | Send resolution notification |
| Postmortem | Postmortem complete | Share with stakeholders |

### 4. Who Gets Notified (Escalation Tiers)

| Tier | Who | When | Channel |
|------|-----|------|---------|
| Tier 1 | Immediate team / on-call | All severities | Slack/Teams, PagerDuty |
| Tier 2 | Engineering manager, tech lead | SEV1/SEV2 | Direct message |
| Tier 3 | Product owner, stakeholders | SEV1 | Email, status page |
| Tier 4 | Executive leadership | SEV1 > 1 hour | Email summary |

### 5. Communication Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| No updates during investigation | Stakeholders assume nothing is happening | Send updates on cadence even if "still investigating" |
| Technical jargon in stakeholder updates | Recipients can't understand the impact | Use business language: "checkout is down" not "connection pool exhausted" |
| Debugger is also communicator | Both debugging and communication are degraded | Delegate communication if possible |
| Optimistic ETAs | Missed ETAs erode trust faster than "unknown" | Say "investigating, no ETA yet" until you have evidence-based estimate |
| No resolution notification | Stakeholders don't know it's fixed | Always send a "resolved" update |

## Why It Prevents Gaps

- **Prevents stakeholders learning about outages from customers.** Proactive communication preserves trust. Reactive communication damages it.
- **Prevents the debugger from being interrupted.** When communication is delegated or automated, the person investigating can focus on investigation.
- **Creates an audit trail.** Timestamped updates create a communication timeline that feeds into the postmortem.
- **Removes decision-making during stress.** The protocol replaces "should I tell someone?" with a lookup table. Under incident stress, fewer decisions is better.
- **Enables accurate postmortems.** Communication logs show when stakeholders were notified, what they were told, and whether ETAs were accurate.

## Status Before Implementation

Our troubleshooting command has zero communication guidance. There is no mechanism to:
- Notify anyone based on severity
- Send periodic updates during investigation
- Distinguish technical investigation notes from stakeholder updates
- Track who was informed and when
- Send resolution notifications

The implicit assumption is that the engineer debugging the issue is the only audience. In production incidents, this assumption fails — managers, product owners, and sometimes customers need information at a different level of detail and on a different cadence.

## Implementation

- Add communication cadence table driven by severity classification
- Add stakeholder update template to troubleshooting output
- Add communication decision points at each phase transition
- Add escalation tier lookup table
- Log all communication actions in the troubleshooting log
- Add communication anti-pattern warnings
- For AI-assisted troubleshooting: generate draft stakeholder updates that the user can send

## References

- PagerDuty API Concepts: Notes, Status Updates, Responder Requests (developer.pagerduty.com/api-reference)
- PagerDuty: Escalation Policies and Rules (developer.pagerduty.com/api-reference)
- Google SRE Book: Incident Commander and Communications Lead roles
- Microsoft Sentinel: Incident workflow with status tracking (learn.microsoft.com/en-us/azure/sentinel/incident-navigate-triage)
