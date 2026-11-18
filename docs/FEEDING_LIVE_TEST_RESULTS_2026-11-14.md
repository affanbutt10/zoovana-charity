# Live donor integration test — 14 November 2026

> Subsequent backend retest: request create/list/detail 500s are resolved and mock
> payment, idempotency and cancellation passed. PKR/SAR mismatch remains. See
> [updated live retest](FEEDING_LIVE_RETEST_2026-11-14.md). Details below are the
> historical first pass.

Environment: configured live auth and Marketplace feeding services. Tested the
user-authorized donor account. No credentials or access tokens are included here.

## Confirmed working against the live service

| Check | Result |
| --- | --- |
| Corrected account login and session | 200 |
| Checkout contact prefill | 200; required fields present |
| Payment method discovery | 200; mock provider, card only, saved cards disabled |
| Programme list | 200; four active Makkah/Madinah cat/bird programmes |
| Packages for all four programmes | 200; three packages each |
| Programme detail, highlights and zones | 200 for the two sampled Makkah programmes |
| Multi-item quote | 200; quantities 2 + 1, total 18,000.00 PKR |
| Server limits | max 10 lines, max quantity 20 |
| Arabic quote | 200; currency remains PKR |
| Duplicate item / both items and package_id / zero quantity | Correct 422 validation errors |
| Quantity above server max | Correct 400 basket_quantity_invalid |
| Mixed programme basket | Correct 409 basket_mixed_programs |
| Unknown package | Correct 404 package_not_found |
| Notifications list | 200 |
| Profile read | 200 |
| Profile update and restoration | PATCH 200 both times; original name restored |

## Blocking live backend failures

### Request list, creation and details return HTTP 500

- `GET /requests/my`, with default pagination and page sizes 20 and 50.
- `POST /requests` with a valid two-line basket that already received a 200 quote,
  valid account contact and an `Idempotency-Key`.
- `GET /requests/{id}` for three existing request IDs obtained from this account's
  own notifications.

All returned `Internal server error`. Existing request IDs for backend log lookup:

- `0e443de2-928a-4f48-baa2-cc1f1e9f2ccc`
- `093b1d74-8e81-4964-982b-5a37d96d9743`
- `a12d092c-05b5-4234-8988-73857d47bde0`

Inspect service logs and deployed request/item schema migrations. A migration
problem is a diagnostic possibility, not a confirmed cause. Quote and account
services succeed, so this is not a general connectivity/authentication failure.

The failed create returned no request ID. It is therefore not possible to verify
whether a write committed before the 500 or cancel that attempt through the
client. Check the authorized account's unpaid drafts before re-running creation.
The test feeding note was `Live integration QA - basket and retry check`.

### Payment currency mismatch

All 12 returned packages and the successful basket quote use **PKR**.
`GET /requests/payment-methods` declares **SAR** as its only currency. The client
correctly blocks checkout instead of changing the currency. Align supported
currencies and package prices on the backend. The app now shows an explicit
unsupported-currency message rather than only offering a checkout refresh.

### Missing product images

All 12 package `image_url` values are null. Neutral placeholders remain necessary.

## Verification blocked by these failures

Live idempotent create/retry and changed-body conflict, payment intent, mock
funding/webhook confirmation, cancellation, completed proof/media and the full
request detail UI could not be confirmed against this deployment. Fixture tests
cover their mobile contracts, but are not counted as live passes. No card charge
or successful payment was performed.

Android emulator app installed and launched with live configuration. Live login also succeeded in the Android app. Home and city cards loaded;
request history displayed the same backend error. City/animal selection, package
list/grid toggle and multi-item quantity edits worked. The emulator showed
18,000.00 PKR for two small packages plus one medium package and advanced to the
payment screen; submit stayed blocked by the SAR-only methods contract.

## Mobile fixes made from these findings

- Added an explicit unsupported-currency explanation on checkout.
- Removed the empty-donation welcome claim when request history fails.
- Impact shows unavailable metrics rather than zero when history could not load,
  and does not claim an empty verified feed when that feed failed.
- Added regression coverage for the observed PKR/SAR mismatch and unavailable
  history/impact states. Focused basket/design and responsive tests pass;
  Android debug APK builds successfully.

## Data changes and cleanup

The profile name was changed for the update test, restored immediately, and a
fresh profile GET confirmed the original value. Quote arithmetic and total
quantity were independently checked against returned line totals. No successful
request ID or paid donation was returned; no existing request was cancelled or
modified. The failed create may require backend inspection as noted above.

## Local regression results after live QA fixes

The focused integration/design/API/input/notification/responsive coverage now
contains 49 passing cases across the runs. For the live-QA changes, the targeted basket/design suite (19 cases) and
donor-responsive suite (13 cases) passed. `flutter analyze` reports no issues and
the corrected Android debug APK builds successfully.

## Final emulator verification of corrected build

Session restored after reinstall. Home no longer claimed a new/empty donation
journey on backend error; Impact visually showed three unavailable dashes instead
of zero counts. Requests error/retry and Profile settings were reachable. City,
cat programme and quoted package navigation succeeded. Checkout showed the
explicit PKR-unavailable message and its Next control was confirmed disabled.

Screenshots: `design/figma/user-app-update/validation/live-2026-11-14/`.
The native accessibility tree groups stat values with labels, so the automated
exact-string dash counter did not match; the screenshot and widget regression
both confirm all three unavailable metrics.
