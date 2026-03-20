# Approach: Payment Gateway Migration

## Scope
### IN
- Replace Stripe with Adyen for EU transactions

### OUT
- US payment processing
- Refund flow changes

## Pattern
Migration pattern. Strangler Fig with feature flags.

## Top 3 Risks
1. Adyen API response format differs from Stripe — HIGH impact
2. Webhook signatures use different algorithm — MEDIUM impact
3. Settlement timing changes affect reconciliation — MEDIUM impact

## Dependencies
- External: Adyen sandbox access (pending)
- Internal: Finance team approval for new MCC codes
