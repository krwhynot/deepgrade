# Incident Timeline Reconstruction

## What It Is

Incident Timeline Reconstruction is the practice of building a precise, timestamped sequence of events from the moment an incident began (or was introduced) through detection, response, containment, investigation, and resolution. It is the backbone of both effective debugging and effective postmortems.

A timeline answers questions that narrative investigation cannot: How long between the bug being introduced and being detected? How long between detection and first response? How long was spent on dead ends? Was containment applied before or after the root cause was found? These durations reveal process efficiency and surface improvement opportunities that are invisible in a narrative format.

Timeline reconstruction is not just recording what the debugger did. It works BACKWARD from the current moment to the incident origin, correlating git history, deploy logs, monitoring alerts, and user reports into a single chronological view.

## Enterprise Origin

**Source:** PagerDuty incident lifecycle timestamps, Google SRE incident timelines, Microsoft Sentinel incident workflow tracking.

PagerDuty's incident model is fundamentally timeline-based. Every incident transitions through states (triggered → acknowledged → resolved) with timestamps at each transition. Escalation rules have time-based triggers: *"If all On-Call Users for a given Escalation Rule have been acknowledged of an Incident and the Escalation Rule's escalation delay has elapsed, the Incident escalates to the next Escalation Rule."* The timestamps are not optional — they are the mechanism that drives escalation.

Google's SRE postmortem template centers on the timeline. The timeline is not supplementary material — it is the primary artifact from which all other postmortem sections are derived. Contributing factors, action items, and lessons learned are all tied back to specific points in the timeline.

Microsoft Sentinel's incident workflow tracks explicit state transitions with timestamps: when the incident was created, when it was assigned, when the status changed, when comments were added. Each action is logged as a timestamped event, creating a complete audit trail.

## How It Works

### 1. Build the Timeline Backward (from NOW to origin)

Start from the current moment and work backward:

```
NOW: User reports the issue
  ↑ When did the user first notice?
  ↑ When was the last successful operation?
  ↑ When was the most recent deploy/change?
  ↑ When did monitoring first show anomaly (if it did)?
  ↑ When was the causal change committed?
```

### 2. Data Sources for Timeline Events

| Data Source | What It Provides | How to Access |
|------------|-----------------|---------------|
| Git log | When causal commits were made | `git log --oneline --after={date}` |
| CI/CD history | When deploys happened | CI dashboard, deploy logs |
| Monitoring/alerts | When anomalies started | Monitoring dashboard, alert history |
| User reports | When users noticed | Support tickets, Slack messages |
| Error logs | When errors first appeared | Log aggregation, `grep` with timestamps |
| Application logs | Request-level timeline | Structured logs with correlation IDs |

### 3. Timeline Template

```markdown
## Incident Timeline

| Time | Event | Source | Notes |
|------|-------|--------|-------|
| {date HH:MM} | Causal commit merged | git log | commit {hash}: {message} |
| {date HH:MM} | Deploy to {env} | CI/CD | deploy #{id} |
| {date HH:MM} | First error in logs | Error logs | {error signature} |
| {date HH:MM} | Monitoring alert (if any) | Monitoring | {alert name} or "NO ALERT" |
| {date HH:MM} | User report | User | "{what user said}" |
| {date HH:MM} | Investigation started | Troubleshooting | Classified as SEV{N} |
| {date HH:MM} | Containment applied | Troubleshooting | {mitigation action} |
| {date HH:MM} | Service restored | Troubleshooting | {verification method} |
| {date HH:MM} | Root cause identified | Troubleshooting | {root cause summary} |
| {date HH:MM} | Permanent fix deployed | CI/CD | commit {hash} |
| {date HH:MM} | Incident closed | Troubleshooting | {resolution summary} |
```

### 4. Key Duration Metrics

Extract these durations from the timeline:

| Metric | Definition | Why It Matters |
|--------|-----------|---------------|
| **Time to detect (TTD)** | From incident start to first detection | Measures monitoring effectiveness |
| **Time to respond (TTR)** | From detection to first response action | Measures alerting and on-call effectiveness |
| **Time to contain (TTC)** | From detection to service restoration | Measures containment readiness |
| **Time to resolve (MTTR)** | From detection to permanent fix deployed | Measures overall incident management effectiveness |
| **Dead end time** | Time spent on hypotheses that didn't pan out | Measures investigation efficiency |
| **Detection gap** | From causal change to detection | Measures test/monitoring coverage for this failure mode |

### 5. Timeline Anti-Patterns to Flag

| Pattern | Signal | Implication |
|---------|--------|------------|
| Detection gap > 24 hours | Bug shipped days ago, only found now | Monitoring and test gaps for this failure mode |
| TTR > TTC (long investigation after containment) | Service was restored but root cause took hours | May indicate insufficient logging or complex root cause |
| No monitoring alert | User detected before monitoring | Alert gap for this failure mode |
| Multiple dead ends | > 30 min spent on wrong hypotheses | Investigation guidance or observability needs improvement |
| Containment not applied for SEV1/2 | No containment row in timeline | Process gap — containment should happen before investigation |

## Why It Prevents Gaps

- **Reveals detection gaps.** A bug that existed for 3 days before anyone noticed it reveals a monitoring blind spot.
- **Measures process effectiveness.** TTD, TTR, TTC, and MTTR over time show whether incident management is improving.
- **Provides postmortem evidence.** The timeline is objective — it shows what actually happened, not what people remember happening.
- **Surfaces dead-end investigation time.** If 60% of investigation time was spent on wrong hypotheses, the investigation approach needs improvement.
- **Creates accountability for follow-up.** "Detection gap was 3 days because no alert exists for this error class" is a specific, actionable finding.

## Status Before Implementation

Our troubleshooting log records Phase-by-phase findings but not timestamps. There is no:
- Timeline of when events occurred
- Duration metrics (TTD, TTR, TTC, MTTR)
- Backward reconstruction from incident to origin
- Detection gap measurement
- Dead end time tracking

The log captures WHAT was investigated but not WHEN, making it impossible to measure process effectiveness or identify temporal patterns.

## Implementation

- Add timestamp logging to each phase transition in the troubleshooting workflow
- Add backward timeline reconstruction as part of Phase 2 (Root Cause Investigation)
- Add timeline template to troubleshooting log output
- Calculate and log key duration metrics (TTD, TTR, TTC, MTTR, dead end time, detection gap)
- Flag timeline anti-patterns automatically
- Track duration metrics over time in knowledge base for trend analysis

## References

- PagerDuty: Incident lifecycle timestamps and escalation delays (developer.pagerduty.com/api-reference)
- Google SRE Book: Postmortem timeline as primary artifact
- Microsoft Sentinel: Timestamped incident workflow (learn.microsoft.com/en-us/azure/sentinel/incident-navigate-triage)
- DORA Metrics: Mean Time to Recovery (dora.dev)
