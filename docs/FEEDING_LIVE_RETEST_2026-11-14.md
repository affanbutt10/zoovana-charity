# Live backend retest — 14 November 2026

Follow-up to `FEEDING_LIVE_TEST_RESULTS_2026-11-14.md` after the backend update.
Authenticated with the authorized donor account. No credentials or tokens are
included in this report.

## Resolved and verified live

| Check | Result |
| --- | --- |
| Login, contact and method discovery | 200 |
| Request history | 200; previous 500 resolved |
| Existing request details | 200 for all five history records checked |
| Multi-item quote | 200; 2 small + 1 medium, 18,000.00 PKR |
| Basket create | 201; one request containing both lines and total quantity 3 |
| Retry with the same Idempotency-Key/body | 201; exact same request ID |
| Same key with changed body | Expected 409 idempotency_key_reused |
| New basket detail | 200; correct unit prices, line totals and quantities |
| Payment intent | 200; mock provider with checkout URL and correct amount |
| Mock checkout confirmation | Expected 303 return deep link |
| Server funding confirmation | GET detail confirmed payment_status=paid, status=assigned |
| Progress | Created/paid/assigned done; preparing current; feeding/completed upcoming |
| Current/upcoming timestamps | Null as required |
| Cancel paid request | Expected 409 request_not_cancellable |
| Legacy single-package create | 201 |
| Cancel unpaid legacy request | 200; final status cancelled |
| Cancelled progress | Created done; remaining five stages halted |
| Final request history | 200 |

## Remaining live blocker: currency contract

`GET /requests/payment-methods` still returns `currencies: ["SAR"]`, while
packages, quote and intent amounts are in **PKR**. The mock gateway processed PKR
in the API test, but the advertised supported-currency contract contradicts it.
The mobile app correctly blocks checkout for an unadvertised currency. Backend
must return the currencies actually supported by the configured provider, or
change package currency/prices consistently. Mobile must not relabel PKR as SAR
or bypass this contract.

## Test data

- Mock-funded basket: **FR-20261114-00001**, now assigned. This is mock funding; no real card
  was charged. Paid cancellation is blocked by the API, so this QA request remains
  in the account and may be cleaned up by backend/admin if needed.
- Legacy cancellation test: **FR-20261114-00002**, cancelled successfully.
- Previous unpaid QA-marker cleanup was checked; no matching cancellable draft
  was found. Existing user requests were not modified.

No completed request is available in this account, so approved proof/media and
completed feeding timestamps could not be live-verified. The account currently
contains assigned/awaiting/reassignment/cancelled requests. No feeder-role actions
or fabricated proof were performed.

This pass verifies live API and mock gateway behavior. It does not claim a new
physical-device or production-card-payment test. Earlier screenshots represent
the prior deployment and its then-current failures.
