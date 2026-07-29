# Observability-First Diagnosis

## What It Is

Observability-First Diagnosis is the principle that you check telemetry signals — logs, traces, metrics, and error aggregation — BEFORE reading source code. In a properly instrumented system, observability data tells you WHERE the problem is and WHAT the system was doing when it broke, without requiring you to reason about code paths from first principles.

The current troubleshooting approach starts with `grep` and `git log` — reading code and checking what changed. This works for development bugs but is backwards for production incidents in instrumented systems. Telemetry data shows you the actual runtime behavior, not what the code is supposed to do. The code might look correct while the telemetry shows it's receiving unexpected inputs, timing out on external calls, or running in a degraded environment.

Observability is not just "check the logs." It is the ability to ask arbitrary questions about your system's behavior from the outside, without deploying new code. A system is observable when you can understand its internal state by examining its outputs: structured logs with correlation IDs, distributed traces that show request flow across services, and metrics that reveal trends and anomalies.

## Enterprise Origin

**Source:** OpenTelemetry observability framework, Google SRE "Monitoring Distributed Systems," DORA research on observability as a capability.

OpenTelemetry defines observability through three signal types: *"The application code must emit signals such as traces, metrics, and logs. An application is properly instrumented when developers don't need to add more instrumentation to troubleshoot an issue, because they have all of the information they need."*

The key insight from OpenTelemetry's observability primer: observability lets you *"troubleshoot and handle novel problems, that is, 'unknown unknowns.'"* This is the distinction from traditional monitoring. Monitoring tells you WHEN something breaks (alert fires). Observability tells you WHY it broke (you can query the data to understand the failure mode even if you've never seen it before).

OpenTelemetry's three pillars:

1. **Logs**: Timestamped messages with structured data. *"Logs aren't enough for tracking code execution, as they usually lack contextual information, such as where they were called from. They become far more useful when they are included as part of a span, or when they are correlated with a trace and a span."*

2. **Traces**: Distributed traces that show request flow across services. *"Without tracing, finding the root cause of performance problems in a distributed system can be challenging."* Each trace contains spans with attributes (HTTP method, status code, route, server address) that show exactly what happened at each step.

3. **Metrics**: Aggregated numeric data. Combined with SLIs (Service Level Indicators) and SLOs (Service Level Objectives), metrics answer "is the service doing what users expect?"

OpenTelemetry explicitly distinguishes **reliability** from **uptime**: *"A system could be up 100% of the time, but if, when a user clicks 'Add to Cart' to add a black pair of shoes to their shopping cart, the system doesn't always add black shoes, then the system could be unreliable."* This definition reframes troubleshooting from "is it up?" to "is it working correctly?"

## How It Works

### 1. Check Telemetry Before Code (The Observability Ladder)

When investigating any issue, climb the observability ladder from cheapest to most expensive:

| Level | Signal | What It Tells You | Check First? |
|-------|--------|-------------------|-------------|
| 1 | **Error aggregation** | What errors are happening, how often, when they started | YES — always |
| 2 | **Metrics / SLIs** | Is the service meeting its performance targets? What's the trend? | YES — if available |
| 3 | **Structured logs** | What happened in the specific request/transaction that failed | YES — if correlation ID available |
| 4 | **Distributed traces** | How did the request flow across services? Where did it slow/fail? | For cross-service issues |
| 5 | **Source code** | What is the code supposed to do? | LAST — after telemetry narrows the scope |

### 2. Telemetry Questions to Ask

Before opening any source file, try to answer:

| Question | Telemetry Source | Why It Matters |
|----------|-----------------|---------------|
| When did this start? | Error rate timeline, deploy markers | Correlates with changes |
| How often does it happen? | Error count, success rate | 100% failure vs 1% failure = different bugs |
| Which endpoint/service? | Request metrics, trace root spans | Narrows investigation scope |
| What's the error? | Structured error logs, span status | Gives direct clue to root cause |
| What was the request? | Trace attributes, log payloads | Reproduces the failure |
| What did downstream services do? | Child spans in trace | Shows if the bug is local or upstream |
| Is it environment-specific? | Per-environment metrics | Config issue vs code issue |

### 3. Correlation ID Tracing

For any specific incident, trace the request through the system using its correlation ID:

```
User reports: "Order #12345 failed"

Step 1: Find the correlation ID for order 12345
Step 2: Query logs across all services for that correlation ID
Step 3: Reconstruct the request timeline:
  10:23:01.100 - API Gateway: received POST /orders (200ms)
  10:23:01.200 - Order Service: validate order (50ms)
  10:23:01.250 - Payment Service: charge card → TIMEOUT after 30s
  10:23:31.250 - Order Service: payment failed, return 500
  10:23:31.300 - API Gateway: return 500 to client

Root cause location: Payment Service timeout
(Without observability, you'd be reading Order Service code)
```

### 4. When Observability Data Is Not Available

Not every project has distributed tracing or structured logging. When telemetry is limited:

| Available | Not Available | Fallback Approach |
|-----------|--------------|-------------------|
| Application logs | Structured logging | Search logs for error strings, timestamps |
| Error tracking (Sentry, etc.) | Nothing | Check error tracker for stack traces and frequency |
| Basic monitoring | Application metrics | Check server metrics (CPU, memory, disk, network) |
| Git history | Any telemetry | Fall back to code-first approach (current method) |
| Nothing | Everything | Current approach is correct — read code, trace logic |

The observability-first approach degrades gracefully. When telemetry exists, use it first. When it doesn't, fall back to code reading. But always CHECK for telemetry before assuming it doesn't exist.

## Why It Prevents Gaps

- **Prevents investigating the wrong service.** Telemetry shows where the failure actually occurs. Without it, you investigate the service that REPORTS the error, which may not be the service that CAUSES the error.
- **Provides runtime context code can't.** Code shows what SHOULD happen. Telemetry shows what ACTUALLY happened. The gap between the two is often the bug.
- **Reduces investigation time.** A distributed trace that shows "Payment Service timed out after 30s" eliminates hours of reading Order Service code trying to find the bug.
- **Catches environment-specific issues.** A bug that only happens in production with production data and production config is invisible in code review but visible in production telemetry.
- **Provides reproduction data.** Trace attributes and log payloads show the exact input that triggered the failure, enabling reproduction without guessing.

## Status Before Implementation

Our troubleshooting command's Phase 1 goes: categorize bug type → check git history → reproduce → read code → gather evidence. There is no step for checking observability signals. The implicit assumption is that the codebase IS the source of truth.

For projects with monitoring, structured logging, error tracking (Sentry, Application Insights, Datadog), or distributed tracing (Jaeger, Zipkin, OpenTelemetry), our framework ignores these data sources entirely. An engineer using our troubleshoot command on a well-instrumented system would skip past the most valuable diagnostic data and go straight to reading code.

## Implementation

- Add "Check Observability Signals" as a new step in Phase 2 (Root Cause Investigation), before "Read the Actual Code"
- Add the Observability Ladder as a diagnostic checklist
- Add telemetry questions checklist
- Add correlation ID tracing guidance
- Add graceful degradation when telemetry is not available
- Prompt the user: "Does this project have monitoring, error tracking, or distributed tracing? [describe what's available]"
- If yes: guide through telemetry investigation before code reading
- If no: proceed with current code-first approach

## References

- OpenTelemetry Observability Primer (opentelemetry.io/docs/concepts/observability-primer)
- OpenTelemetry Signals: Traces, Metrics, Logs (opentelemetry.io/docs/concepts/signals)
- OpenTelemetry Logging specification (opentelemetry.io/docs/specs/otel/logs)
- Google SRE Book: "Monitoring Distributed Systems" chapter
- DORA Research: Observability as a software delivery capability (dora.dev)
