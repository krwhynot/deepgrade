# Blast Radius Assessment

## What It Is

Blast Radius Assessment is a structured evaluation of an incident's scope and impact BEFORE diving into code-level investigation. It answers: how many users are affected? Which services? Is the impact spreading or contained? What's the business cost per minute of downtime?

Without blast radius assessment, engineers tunnel-vision into the code while the incident may be affecting more systems than they realize. A database connection pool exhaustion might initially present as "search is slow" but actually affects every service that shares that database. The engineer debugging search doesn't know that checkout, reporting, and user management are also degrading.

Blast radius assessment is the bridge between severity classification ("how bad is it conceptually?") and investigation ("where in the code is the problem?"). It provides the SCOPE that determines whether you need one engineer or five, whether you contain one service or multiple, and whether you communicate to one team or the whole organization.

## Enterprise Origin

**Source:** Azure Chaos Studio blast radius controls, AWS Resilience Hub fault injection experiments, Polly/Simmy chaos engineering injection rate management.

Azure Chaos Studio explicitly manages blast radius as a first-class concept: *"A way to revert easily, to control the blast radius."* Chaos experiments are designed with intentional blast radius limits — you inject faults into a subset of instances, not all of them. This same thinking applies in reverse during incident response: understanding the blast radius of a real failure determines the appropriate response scope.

AWS Resilience Hub uses fault injection experiments to measure resilience, and each experiment has a defined blast radius: which resources are affected, which are protected. The resilience score reflects how well the application handles failures within different blast radii. From AWS docs: *"AWS Resilience Hub uses AWS FIS to provide tailored recommendations for improving application resilience."*

Polly/Simmy's chaos engineering approach explicitly controls injection rates to manage blast radius during testing. Their documentation states: *"In production environments, however, you may prefer to limit chaos to certain users and tenants, ensuring that regular users remain unaffected."* This per-user, per-tenant granularity in failure injection reflects the same thinking needed for blast radius assessment during real incidents: who exactly is affected?

## How It Works

### 1. Impact Scope Matrix (complete before investigating code)

| Dimension | Assessment Question | How to Check |
|-----------|-------------------|-------------|
| **Users** | How many users are affected? All, subset, single? | Error rates, support tickets, monitoring |
| **Services** | Which services are impacted? Just one, or cascading? | Health checks, dependency map, error logs |
| **Data** | Is data integrity at risk? Read-only impact or writes corrupted? | Database logs, transaction logs, data validation |
| **Revenue** | Is revenue directly impacted? Transactions blocked? | Payment processing logs, order counts |
| **Geographic** | All regions or specific regions? | CDN logs, regional health checks |
| **Temporal** | Getting worse, stable, or improving? | Error rate trend over last 15 min |

### 2. Blast Radius Classification

| Radius | Description | Response |
|--------|-----------|----------|
| **Isolated** | Single user, single feature, no spreading | Standard investigation, single engineer |
| **Contained** | Subset of users or one service, not spreading | Elevated priority, monitor for spread |
| **Spreading** | Impact growing to adjacent services or more users | Immediate containment, multi-agent investigation |
| **System-wide** | Multiple services, all users, cascading failures | All hands, containment is #1 priority, communication protocol activated |

### 3. Dependency Cascade Check

Before investigating the reported symptom, check if the root cause is upstream:

```
User reports: "Search is slow"

Dependency check:
  Search → Database connection pool → Shared database
  Other consumers of shared database: Checkout, Reports, User Management

Are those services also affected?
  YES → The blast radius is the shared database, not search
  NO  → The blast radius is search-specific
```

This reframes the investigation. If the shared database is the actual blast radius, debugging the search service is wasted effort.

### 4. Blast Radius Monitoring During Investigation

Blast radius is not static. Re-assess periodically during investigation:
- Every 15 minutes for SEV1
- Every 30 minutes for SEV2
- On any new symptom report for SEV3

If blast radius expands during investigation:
- Escalate severity
- Expand containment scope
- Notify additional stakeholders

## Why It Prevents Gaps

- **Prevents tunnel-vision on the reported symptom.** The user reports "search is slow" but the blast radius is the shared database. Without blast radius assessment, you debug search while checkout silently fails.
- **Prevents under-scoped containment.** If you contain only the reported service but the blast radius includes three services, your containment is incomplete.
- **Informs resource allocation.** An isolated blast radius needs one engineer. A system-wide blast radius needs a war room. Without the assessment, you guess.
- **Catches cascading failures early.** A spreading blast radius means the incident is getting worse. Without monitoring, you discover the cascade when users report it — too late for proactive containment.
- **Provides investigation direction.** If the blast radius includes services that share a common dependency, that dependency is the likely root cause. This is faster than tracing each affected service individually.

## Status Before Implementation

Our troubleshooting command jumps from bug categorization (Step 1.1) to checking recent changes (Step 1.2) without assessing how broad the impact is. The multi-agent escalation criteria (Step 1.6) check technical complexity ("spans 3+ layers") but not impact scope ("affects all users" vs "affects one user").

There is no mechanism to:
- Assess how many users/services are affected before investigating
- Check if the reported symptom is part of a larger cascading failure
- Monitor whether the blast radius is expanding during investigation
- Use blast radius to inform containment scope

## Implementation

- Add blast radius assessment as a step within Phase 0 (Triage), after severity classification
- Add Impact Scope Matrix as a diagnostic checklist
- Add dependency cascade check to identify upstream causes
- Add blast radius classification (isolated/contained/spreading/system-wide)
- Add periodic re-assessment cadence based on severity
- Log blast radius in troubleshooting log and knowledge base entries
- Use blast radius to inform multi-agent escalation (not just technical complexity)

## References

- Azure Chaos Studio: Blast radius management in chaos experiments (learn.microsoft.com/en-us/azure/chaos-studio/chaos-studio-overview)
- AWS Resilience Hub: Fault injection experiment scoping (docs.aws.amazon.com/resilience-hub/latest/userguide/arh-testing.html)
- Polly/Simmy: Injection rate management and per-tenant blast radius (github.com/app-vnext/polly/blob/main/docs/chaos/index.md)
- AWS Resilience Hub Concepts: SOP and fault injection (docs.aws.amazon.com/resilience-hub/latest/userguide/concepts-terms.html)
