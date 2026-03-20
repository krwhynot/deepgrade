## Scenario Matrix

| Scenario | Planned? | Which Phase? | Tested? | Monitored? | Status |
|----------|----------|-------------|---------|-----------|--------|
| Happy path | yes | Phase 1 | tests/billing/test_checkout.py | metrics | covered |
| Failure path | yes | Phase 2 | tests/billing/test_payment_failure.py | alerts | covered |
| Partial rollout | yes | Phase 3 | tests/billing/test_rollback.py | none | covered |
| Backward compatibility | yes | Phase 1 | tests/billing/test_backward_compat.py | none | covered |
| Scale/volume edge | no | - | - | - | GAP |
| Auth/permission edge | yes | Phase 2 | tests/auth/test_permissions.py | audit log | covered |
| Config/environment diff | no | - | - | - | GAP |
| Rollback path | yes | all | tests/billing/test_rollback.py | runbook | covered |
