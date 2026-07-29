# Knowledge Base Entry Schema

This document defines the shape of a structured knowledge base entry for past
troubleshooting incidents. The destination project chooses the storage
location — common patterns are `.troubleshooting/kb.md` or
`docs/troubleshooting/knowledge-base.md`.

The schema supports two uses:
1. **Future correlation matching** (multi-dimensional, see techniques/08)
2. **Pattern detection** across recurring issues

## Required Fields

Every KB entry should include these fields, even when the value is "N/A":

```markdown
### {Issue Title} ({YYYY-MM-DD})

**Category:** {logic | boundary | error handling | data flow | integration | timing}
**Service / Module:** {affected file, module, or service path}
**Error Signature:** {exact error message, exception type, or error code, or "N/A" if no error}
**Code Path:** {function call chain — e.g., checkout → payment → charge → processResponse}
**Symptom:** {what the user observed}
**Root Cause:** {what was actually wrong, one sentence}
**Fix:** {what resolved it, one or two sentences}
**Prevention:** {architectural or process-level guardrail to keep this class of bug out}
**Log:** {path to the full troubleshooting log if one was written}
```

## Optional Fields (use when applicable)

These fields are populated when the corresponding extension was used during
the investigation:

```markdown
**Severity:** SEV{1|2|3|4}                       (from technique 01)
**Containment:** {mitigation, or "N/A"}          (from technique 02)
**Blast Radius:** {isolated | contained | spreading | system-wide}  (from technique 03)
**Contributing Factors:** {list}                 (from technique 06 postmortem)
**Guardrails Missed:** {type:classification,...} (from technique 05)
**Guardrails Added:** {what was added}           (from technique 05)
**Recurrence Count:** {N}                        (from technique 08 correlation)
**Related Incidents:** {titles/dates}            (from technique 08 correlation)
**Five Whys Depth:** {N}                         (if Five Whys was used)
**Detection Gap:** {duration}                    (from technique 09 timeline)
**Time to Resolve:** {duration}                  (from technique 09 timeline)
```

## Field Notes

### Category

Use one of the six categories from Phase 1.1 (logic, boundary, error handling,
data flow, integration, timing). Stick to these — a custom category undermines
pattern detection across entries.

### Service / Module

Specific enough to enable matching. `src/payment/charge.ts` is good.
`payment` is too coarse. Include the path so multi-dimensional correlation can
match by affected service.

### Error Signature

The exact error message or exception type. Include error code if available.
Keywords lose precision over time — the exact signature does not.

Good: `NullReferenceException at PaymentService.Charge line 47`
Less good: `null reference somewhere in payment code`

### Code Path

The call chain from entry point to error site. Helps correlation match by
where the failure flows through the system.

Format: `entry → middle → ... → site` with arrow separators.

### Guardrails Missed (token format)

Use `{guardrail-type}:{classification}` machine-friendly tokens so pattern
detection can find recurring guardrail gaps:

| Token Example | Meaning |
|---|---|
| `unit-tests:not-present` | No unit test existed for the buggy function |
| `unit-tests:insufficient` | Test exists but doesn't cover this case |
| `integration-tests:not-present` | No integration test for this interaction |
| `linter:disabled` | A relevant rule exists but is disabled |
| `types:n-a` | No reasonable type system catch was possible |
| `ci:wrong-layer` | CI runs the tests but at the wrong layer |

Classifications: `not-present`, `insufficient`, `disabled`, `wrong`,
`wrong-layer`, `n-a`.

When the KB has 2+ entries with the same token (e.g., three
`unit-tests:not-present`), that's a systemic gap, not three isolated misses.

## Example Entry (minimal — Required Fields only)

```markdown
### Receipt formatting crashes for French orders (2026-03-12)

**Category:** data flow
**Service / Module:** src/checkout/receipt.ts
**Error Signature:** TypeError: Cannot read properties of null (reading 'format')
**Code Path:** checkout → renderReceipt → localizeString → lookup
**Symptom:** Checkout returns 500 for French-locale orders; English orders work
**Root Cause:** French resource file missing from build configuration
**Fix:** Added fr-FR.json to build manifest in webpack.config.js
**Prevention:** Build-time validation that all locales listed in supported-locales.ts have corresponding resource files
**Log:** docs/troubleshooting/2026-03-12-french-receipt-crash.md
```

## Example Entry (full — with optional extension fields)

```markdown
### Payment gateway timeout takes down checkout (2026-03-15)

**Severity:** SEV2
**Category:** integration
**Service / Module:** src/payment/charge.ts
**Error Signature:** PaymentGatewayTimeoutError after 30s
**Code Path:** checkout → payment → charge → processResponse
**Blast Radius:** contained (checkout only)
**Containment:** Toggled payment-retry feature flag off, restored service in 4 min
**Symptom:** All checkouts hanging then 500ing after 30s
**Root Cause:** Payment gateway's primary region degraded, no failover configured
**Contributing Factors:** No timeout shorter than 30s; no circuit breaker; no failover region configured
**Fix:** Added 5s timeout with retry to secondary gateway region
**Prevention:** Circuit breaker pattern around all external service calls
**Guardrails Missed:** integration-tests:not-present, runtime-validation:insufficient
**Guardrails Added:** Integration test for payment timeout; circuit breaker in payment service
**Recurrence Count:** 1
**Related Incidents:** none
**Time to Resolve:** 1h 47min
**Log:** docs/troubleshooting/2026-03-15-payment-timeout.md
```

## Storage Location

The schema is location-agnostic. Common conventions:

- `.troubleshooting/kb.md` — per-project, hidden directory style
- `docs/troubleshooting/knowledge-base.md` — per-project, docs style
- `~/.troubleshooting/kb.md` — user-level, all projects (rare)

The destination project picks. The schema does not care.
