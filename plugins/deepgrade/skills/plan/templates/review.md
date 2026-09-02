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

- Deployment sequence:
  1. <step> — verify: <command, healthy output>
- Rollback trigger: <observable condition>
- Rollback steps:
  1. <step>
- Monitoring: <what to watch, for how long, threshold that trips rollback>
- Owner: <name>

## Release authorization

- Name: <human who authorized>
- Date: <YYYY-MM-DD>
- Decision: Authorized | Rejected | Deferred
- Notes: <conditions, or reason for rejection/deferral>
