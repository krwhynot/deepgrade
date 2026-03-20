# Containment Before Root Cause (SRE Incident Response)

## What It Is

Containment is the principle that for high-severity production incidents, RESTORING SERVICE takes priority over FINDING ROOT CAUSE. A quick mitigation — rollback, feature flag toggle, config revert, traffic reroute — that gets users back online in 5 minutes is more valuable than a perfect root cause analysis that takes 2 hours while users are down.

This is counterintuitive for engineers trained on methodical debugging. The instinct is to understand the problem before acting. But in production incident response, that instinct causes unnecessary downtime. Containment separates "make it stop hurting" from "understand why it hurts."

The key mental model: **Incident Management** (restore service) and **Problem Management** (find root cause) are two different processes with two different timelines. You can close an incident (service restored) while the problem remains open (root cause TBD). Running them in sequence — contain first, investigate second — is faster and less damaging than running them in parallel or skipping containment entirely.

## Enterprise Origin

**Source:** Google SRE "Managing Incidents," ITIL Incident Management vs Problem Management separation, Azure Chaos Studio incident response patterns.

Google's SRE practice explicitly separates incident response roles. The Incident Commander's job is to restore service, not to debug. The Ops Lead focuses on mitigation actions. Debugging happens AFTER service is restored, often by a different person or team. This role separation enforces containment-first because the people making decisions during the incident are optimizing for time-to-recovery, not time-to-root-cause.

ITIL's separation of Incident Management and Problem Management is the formal framework for this principle. An Incident is "an unplanned interruption to a service, or reduction in the quality of a service." Incident Management's goal is to restore service as quickly as possible. A Problem is "the underlying cause of one or more incidents." Problem Management's goal is to identify and eliminate root causes. They are intentionally different processes because they optimize for different things.

Azure Chaos Studio's incident response scenarios describe this explicitly: *"Reproduce an incident that affected your application to better understand the failure. Ensure that post-incident repairs prevent the incident from recurring."* The key phrase is "post-incident repairs" — the investigation and permanent fix happen AFTER the incident is contained, not during.

The chaos engineering philosophy (Polly/Simmy, Azure Chaos Studio) also contributes: by pre-testing failure modes, you build a library of known containment actions. When a real incident matches a tested scenario, containment is faster because the mitigation is already known.

## How It Works

### 1. Containment Decision Gate (SEV1/SEV2 only)

After severity classification, before investigation:

```
Is this SEV1 or SEV2?
  YES → Enter Containment Mode
    Is there an obvious rollback? (last deploy, recent config change)
      YES → "The most recent change was {commit/deploy}. Rollback? [Y/n]"
      NO  → Continue to Containment Checklist
  NO  → Skip to standard investigation (Phase 2)
```

### 2. Containment Checklist (OODA Loop)

For production fires, use the OODA loop (Observe-Orient-Decide-Act):

**Observe:** What are the symptoms RIGHT NOW?
- Error rates, status codes, user reports
- Which services/endpoints are affected
- When did it start (correlate with recent changes)

**Orient:** What changed recently?
- Last deploy (git log, CI/CD history)
- Recent config changes (environment variables, feature flags)
- External dependencies (third-party API status pages)
- Traffic patterns (spike, new geography, bot traffic)

**Decide:** What's the fastest SAFE mitigation?

| Mitigation | Speed | Risk | When to Use |
|-----------|-------|------|------------|
| Rollback last deploy | Fast | Low | Symptoms started after deploy |
| Toggle feature flag | Fast | Low | New feature is the likely culprit |
| Revert config change | Fast | Low | Config was recently modified |
| Scale up / restart | Medium | Low | Resource exhaustion, memory leak |
| Block bad traffic | Medium | Medium | Attack, bot, or specific client causing load |
| Failover to secondary | Slow | Medium | Primary service unrecoverable |
| Disable non-critical features | Medium | Medium | Reduce load to keep critical path alive |

**Act:** Apply the containment. Verify service is restored.

### 3. Containment Report

After containment, log what was done BEFORE starting investigation:

```markdown
## Containment Report
**Incident start:** {timestamp}
**Containment applied:** {timestamp}
**Time to contain:** {duration}
**Mitigation action:** {what was done}
**Service status after containment:** {restored | partially restored | degraded}
**Temporary tradeoffs:** {what's lost until permanent fix — e.g., "new feature disabled"}
**Root cause investigation:** PENDING — scheduled after service stabilization
```

### 4. Transition to Investigation

Once service is stable:
- "Service restored via {mitigation}. Ready to investigate root cause? [Y/n]"
- If yes: proceed to standard Phase 2 (Root Cause Investigation)
- If no: log the containment report and mark for follow-up

The investigation now has the ADVANTAGE of the containment data: what mitigation worked tells you a lot about what the root cause likely is. "Rollback fixed it" narrows the cause to the rolled-back changes. "Feature flag toggle fixed it" narrows it to that feature's code path.

## Why It Prevents Gaps

- **Prevents extended downtime during investigation.** The most expensive debugging mistake in production is investigating for 2 hours while users are down, when a 2-minute rollback would have restored service.
- **Preserves evidence for investigation.** Containment actions (which mitigation worked, which didn't) are evidence. A rollback that fixes the issue tells you the cause is in the rolled-back changes. This is stronger evidence than reading code.
- **Separates urgency from importance.** Containment handles urgency (stop the bleeding). Investigation handles importance (prevent recurrence). Mixing them degrades both.
- **Reduces panic-driven debugging.** Under incident pressure, engineers make worse debugging decisions. Containing first reduces pressure, leading to better root cause analysis afterward.
- **Creates a containment playbook over time.** Each containment report adds to the knowledge base. Future incidents matching the same pattern can be contained faster by referencing past containment actions.

## Status Before Implementation

Our troubleshooting command's Iron Law states: "NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST." This is correct for development bugs but dangerous for production incidents. A SEV1 production outage should NOT wait for Phase 1 completion before taking mitigating action.

The current command has no concept of:
- Containment vs permanent fix
- Temporary mitigations (rollback, feature flag)
- Time-to-recovery as a metric
- The OODA loop for rapid response
- Transitioning from containment to investigation

The multi-agent escalation (Phase 1, Step 1.6) is triggered by technical complexity, not by business urgency. A simple bug that takes down production won't trigger multi-agent because it "looks like a straightforward issue."

## Implementation

- Add containment as **Phase 1** (shifting current phases by 1) for SEV1/SEV2 only
- The Iron Law is modified: "No PERMANENT fixes without root cause investigation. Containment mitigations are allowed immediately for SEV1/SEV2."
- Add OODA loop checklist for rapid containment assessment
- Add containment mitigation decision table (rollback, feature flag, config revert, scale up)
- Add containment report template to troubleshooting log
- Track time-to-contain as a metric alongside time-to-resolve
- Add "containment → investigation" transition step
- SEV3/SEV4 skip containment entirely and go straight to investigation

## References

- Google SRE Book: "Managing Incidents" — role separation (IC, Ops Lead, Communications)
- ITIL: Incident Management vs Problem Management separation
- Azure Chaos Studio: Post-incident investigation scenarios (learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-overview)
- Polly/Simmy chaos engineering: Pre-tested failure modes as containment playbooks (github.com/app-vnext/polly/blob/main/docs/chaos/index.md)
