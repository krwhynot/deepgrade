# Incident Pre-Flow (Phase 0: Severity / Triage, Containment Gate, Status Updates)

Phase file for /toque:troubleshoot, loaded by SKILL.md on entry.

<incident_preflow>
## INCIDENT PRE-FLOW (conditional, before the 4 phases)

For every issue, classify severity on intake. This takes 30 seconds and
determines whether the issue enters the containment gate or goes straight
to Phase 1.

### Phase 0: Severity / Triage

Classify the issue using these signals. If --severity is passed, use that.
Otherwise, infer from the user's language:

| Severity | Definition | Containment? | Route |
|----------|-----------|-------------|-------|
| **SEV1** | Production down, data loss, security breach, revenue impact | YES — mandatory | Containment Gate → Phase 1 |
| **SEV2** | Major feature broken, significant user impact, degraded service | YES — recommended | Containment Gate → Phase 1 |
| **SEV3** | Minor feature broken, workaround exists, limited user impact | No | Straight to Phase 1 |
| **SEV4** | Cosmetic, minor annoyance, tech debt discovered | No | Straight to Phase 1 |

Auto-classification signals:

| Signal in user's report | Likely Severity |
|------------------------|----------------|
| "Production is down", "users can't access", "losing money", "security breach" | SEV1 |
| "Not working", "broken for everyone", "errors in production", "data is wrong" | SEV2 |
| "Something's wrong with", "intermittent", "works but slowly", "edge case" | SEV3 |
| "I noticed", "minor issue", "when you get a chance", "cosmetic" | SEV4 |

ALWAYS confirm: "I'm classifying this as **SEV{N}** based on {signal}.
Adjust? [1/2/3/4/keep]"

Severity can ESCALATE during investigation (never downgrade without resolution):
- Blast radius larger than thought → escalate
- Data integrity affected → escalate to SEV1
- Security implications discovered → escalate to SEV1

Record `T_TRIAGED` after classification.

### Containment Gate (SEV1/SEV2 only)

SEV3/SEV4: skip this gate entirely. Go straight to Phase 1.

For SEV1/SEV2, assess whether a quick, safe mitigation can restore service
BEFORE spending time on root cause investigation.

**OODA loop (Observe-Orient-Decide-Act):**

1. **Observe:** What are the symptoms right now?
2. **Orient:** What changed recently? (last deploy, config change, traffic spike)
3. **Decide:** What's the fastest SAFE mitigation from this list?

| Mitigation | Speed | Risk | When to Use |
|-----------|-------|------|------------|
| Rollback last deploy | Fast | Low | Symptoms started after deploy |
| Toggle feature flag | Fast | Low | New feature is the likely culprit |
| Revert config change | Fast | Low | Config was recently modified |
| Scale up / restart | Medium | Low | Resource exhaustion, memory leak |
| Block bad traffic | Medium | Medium | Attack or specific client causing load |
| Failover to secondary | Slow | Medium | Primary service unrecoverable |

4. **Act:** Apply the containment. Verify service is restored.

"Service restored via {mitigation}. Containment is not closure — proceeding
to Phase 1 for root cause investigation."

If no safe containment is available: "No obvious safe mitigation. Proceeding
directly to Phase 1 investigation."

Record `T_CONTAINED` after containment (or "N/A" if skipped or no mitigation available).

LOG the containment action, what was mitigated, and any temporary tradeoffs
(e.g., "new feature disabled until permanent fix").

### Status Updates (SEV1/SEV2 only)

While an incident is open, people who are not in the investigation need to
know four things: what is happening, who is affected, what is being done, and
when the next update comes. Produce the first update immediately after the
Containment Gate and repeat on a fixed cadence (SEV1: every 30 minutes;
SEV2: every 60 minutes) until Status is Resolved. Keep updates factual. No
speculation about cause until Phase 3 confirms it.

```markdown
## Incident Update: {title}
**Severity:** SEV{N} · **Status:** Investigating | Identified | Monitoring | Resolved
**Impact:** {who or what is affected, in plain terms}
**Last Updated:** {timestamp} · **Next Update:** {timestamp}

### Current Status
{What is known now. Verified facts only.}

### Actions Taken
- {containment applied, with time}
- {investigation step completed}

### Next Steps
- {what happens next and its ETA}

### Timeline
| Time | Event |
|------|-------|
| {HH:MM} | {event} |
```

Append each update to the troubleshooting log under `## Status Updates` so
the postmortem timeline in Step 5 can be assembled from them.
</incident_preflow>
