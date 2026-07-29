# Severity Classification and Triage

## What It Is

Severity Classification is an intake protocol that categorizes every incident by business impact BEFORE investigation begins. It determines urgency, resource allocation, communication cadence, and whether containment takes priority over root cause analysis. Without severity classification, every bug gets the same methodical investigation — a SEV1 production outage waits in the same queue as a cosmetic typo.

Enterprise incident management separates **severity** (business impact) from **priority** (order of work). A cosmetic bug on the checkout page might be low severity but high priority if the CEO noticed it. A data corruption issue in a batch job might be high severity but lower priority if the batch doesn't run until next week. The classification system handles both dimensions.

The classification happens at intake, before any debugging work. It takes 30 seconds and determines the entire response posture. Skip it, and you risk spending 2 hours on a methodical root cause analysis while production is burning.

## Enterprise Origin

**Source:** PagerDuty Incident Response framework, ITIL Problem Management, Google SRE "Managing Incidents" chapter.

PagerDuty's incident model uses a three-state lifecycle: `triggered → acknowledged → resolved`. Incidents are created through events, deduplicated, and routed through escalation policies. Each escalation policy defines tiers of responders — if the first tier doesn't acknowledge within a timeout, it escalates to the next. The key design principle is that incident routing is driven by **classification at intake**, not by who happens to be available.

From PagerDuty's API concepts: *"A triggered Incident prompts a Notification to be sent to the current On-Call User(s) as defined in the Escalation Policy used by the Service."* The escalation policy is selected based on the service affected and the incident severity — not based on the content of the investigation.

PagerDuty also implements **Past Incidents** correlation: *"Past Incidents allow Responders to view past resolved Incidents that have similar metadata and were generated on the same Service as their current active Incident. Past Incidents add helpful context for accurate triage, which can lead to shorter resolution time."*

ITIL Problem Management defines the distinction between Incident Management (restore service) and Problem Management (find root cause). The two are intentionally separate processes because they have different objectives and different timelines. An incident can be resolved (service restored) while the underlying problem remains open (root cause unknown). This separation is the foundation of the containment-first principle.

Google's SRE book describes incident severity as the primary driver for the Incident Commander role: *"The Incident Commander holds the high-level state about the incident... The IC's most important function is to assign responsibilities and keep track of their progress."* Severity determines whether an Incident Commander is needed at all.

## How It Works

### 1. Classify on Intake (30 seconds, before ANY investigation)

| Severity | Definition | Containment? | Communication Cadence | Escalation |
|----------|-----------|-------------|----------------------|------------|
| **SEV1 - Critical** | Production down, data loss, security breach, revenue impact | MANDATORY before investigation | Every 15 min | Immediate, multi-agent |
| **SEV2 - High** | Major feature broken, significant user impact, degraded service | Recommended | Every 30 min | Within 1 hour |
| **SEV3 - Medium** | Minor feature broken, workaround exists, limited user impact | Optional | On resolution | Standard process |
| **SEV4 - Low** | Cosmetic, minor annoyance, tech debt discovered | No | Log only | Best effort |

### 2. Auto-Classification Signals

When the user doesn't explicitly state severity, infer from language:

| Signal in report | Likely Severity | Reasoning |
|-----------------|----------------|-----------|
| "Production is down", "users can't access", "losing money", "security breach" | SEV1 | Direct revenue/security/availability impact |
| "Not working", "broken for everyone", "errors in production", "data is wrong" | SEV2 | Major functionality loss, broad impact |
| "Something's wrong with", "intermittent", "works but slowly", "edge case" | SEV3 | Limited impact, workaround likely exists |
| "I noticed", "minor issue", "when you get a chance", "cosmetic" | SEV4 | No functional impact |

### 3. Confirm Classification

Always confirm: "I'm classifying this as **SEV{N}** based on {signal}. Adjust? [1/2/3/4/keep]"

This takes 5 seconds and prevents misclassification from driving the wrong response.

### 4. Severity Can Escalate, Never Downgrade Without Resolution

During investigation, severity can increase:
- Blast radius larger than thought → escalate
- Data integrity affected → escalate to SEV1
- Security implications discovered → escalate to SEV1
- Multiple teams/services affected → escalate by one level

Severity NEVER decreases during an active investigation. If the issue turns out to be less severe, that's captured in the resolution, not in a mid-investigation reclassification.

### 5. Severity Drives Process Selection

| Severity | Process Path |
|----------|-------------|
| SEV1 | Fast-track OODA → Containment → Full investigation after service restored |
| SEV2 | Containment assessment → Standard 4-phase with urgency |
| SEV3 | Standard 4-phase investigation |
| SEV4 | Log and fix when convenient, or batch with similar issues |

## Why It Prevents Gaps

- **Prevents treating production fires like development bugs.** Without severity classification, a SEV1 gets the same "let me read the code and trace the data flow" treatment as a SEV4. Classification forces the appropriate response posture.
- **Prevents under-communication.** A SEV1 without a communication protocol means stakeholders find out about the outage from customers, not from engineering. Classification triggers the right communication cadence.
- **Prevents over-investigation of minor issues.** A SEV4 doesn't need Five Whys, multi-agent escalation, or a structured postmortem. Classification prevents the framework from applying heavyweight process to lightweight problems.
- **Enables resource allocation.** A SEV1 justifies pulling in additional engineers, spinning up multi-agent investigation, and interrupting other work. A SEV4 does not. Without classification, there's no justification framework for resource decisions.
- **Creates historical severity data.** Over time, the distribution of SEV1/2/3/4 incidents reveals systemic health. A project with recurring SEV1s has a different problem than one with many SEV4s.

## Status Before Implementation

Our troubleshooting command treats every issue identically. A production outage affecting all users and a cosmetic rendering glitch both enter the same 4-phase pipeline at the same pace. There is no mechanism to:
- Fast-track critical issues
- Trigger different communication patterns based on severity
- Skip heavyweight investigation for trivial issues
- Justify multi-agent escalation based on business impact rather than technical complexity

The current escalation criteria (Phase 1, Step 1.6) are based on technical complexity (spans 3+ layers, 2+ hypotheses), not business impact. A technically simple bug that takes down production doesn't trigger escalation because it only affects one layer.

## Implementation

- Add severity classification as **Phase 0: Triage** before the current Phase 1
- Add auto-classification heuristics based on user language signals
- Add severity confirmation step (5-second prompt)
- Route SEV1/SEV2 to containment-first path before investigation
- Route SEV3/SEV4 directly to standard investigation
- Log severity in troubleshooting log and knowledge base entries
- Add severity distribution tracking to pattern detection

## References

- PagerDuty API Concepts: Incidents, Escalation Policies (developer.pagerduty.com/api-reference)
- PagerDuty Past Incidents correlation (developer.pagerduty.com/api-reference)
- ITIL Problem Management: Incident vs Problem separation
- Google SRE Book: "Managing Incidents" chapter
- Microsoft Sentinel: Incident severity and triage workflow (learn.microsoft.com/en-us/azure/sentinel/incident-navigate-triage)
