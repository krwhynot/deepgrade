# <Title> — Release Review

- Plan: docs/plans/<date>-<name>/
- Base: <commit or branch the diff was taken against>
- Date: <YYYY-MM-DD>

## Summary

<What is being released, in three sentences or fewer.>

## Diff-versus-plan

- Matched: <N> of <M> planned files changed
- Unplanned: <list of files in the diff not in plan.md ## Files that change>
- Untouched: <list of planned files not in the diff>
- Departures acknowledged in plan.md ## Departures from plan: Yes | No

## Constraint check

| Constraint (intent.md) | Result | Evidence |
|---|---|---|
| <constraint> | VERIFIED / APPEARS VIOLATED / NOT APPLICABLE | <file:line> |

## Findings

<Ordered by severity. Important = would break behavior, leak data, or breach
a policy. At most 5 nits; summarize the rest as a count.>

1. [Important | Nit] <file:line> — <finding>. Evidence: <what was observed>.

Nits not listed: <count>

## Release checklist

- Runbook: <path to runbook.md, or "inline below">
- Owner of the release window: <name>

### Pre-deploy

- [ ] All tests passing in CI at <commit>
- [ ] Findings above resolved or explicitly accepted by the authorizer
- [ ] Database migrations tested against a production-shaped copy (or N/A)
- [ ] Feature flags configured and default state confirmed (or N/A)
- [ ] Breaking API or contract changes: consumers notified (or N/A)
- [ ] Rollback steps below rehearsed or dry-run
- [ ] On-call or owner reachable for the monitoring window

### Deploy

1. <step> — verify: <command, healthy output>
2. <step> — verify: <command, healthy output>
- [ ] Staging or canary verified before full rollout (or N/A, with reason)
- [ ] Smoke tests run: <command>
- [ ] Key user flows exercised by hand: <list>

### Post-deploy

- [ ] Metrics nominal at end of monitoring window
- [ ] Release notes or changelog updated
- [ ] Stakeholders notified
- [ ] Plan status.json and manifest.md updated

### Rollback

- Triggers (any one trips rollback; numbers, not feelings):
  - Error rate exceeds <X>% over <N> minutes
  - P50 or P95 latency exceeds <X> ms over <N> minutes
  - <critical user flow> fails smoke test
  - <data integrity check> returns unexpected count
- Steps:
  1. <step> — verify: <command, healthy output>
- Monitoring: <dashboard or query>, for <duration>, thresholds as above

## Release authorization

- Name: <human who authorized>
- Date: <YYYY-MM-DD>
- Decision: Authorized | Rejected | Deferred
- Notes: <conditions, or reason for rejection/deferral>
