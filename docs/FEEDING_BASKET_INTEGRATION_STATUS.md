# Feeding basket mobile integration

Implemented against the backend handoff in `FEEDING_BASKET_MOBILE_INTEGRATION.md`.

- Debounced quote on basket changes, stale-response protection and server-provided
  quantity/line limits. Latest quote is required before advancing or submitting.
- Checkout contact prefill; phone is optional, name/email validated. Contact can be
  edited. Feeding notes support 500 characters.
- Basket create uses `items` and an attempt UUID in `Idempotency-Key`. Network
  retries reuse that UUID; changed contact/notes/basket/locale regenerate it.
- Payment methods come from the server, filtered by OS and currency. Google Pay
  and save-card controls are removed. No app-owned PAN/CVV fields remain.
- Official Moyasar 3.0.6 SDK opens after payment intent. SDK callbacks never mark
  a donation paid. Server detail is polled; an unpaid draft shows pending UI.
- Payment retry reuses the existing draft. Request details can resume card payment.
- Detail parses line quantities/unit prices, `fed_at`, zone, nullable proof
  metrics and server progress. Current/upcoming stages never display timestamps.
- Media uses signed posters; expiry refresh remains enabled. Failed 401/404 media
  refreshes detail once per failed URL; the open viewer consumes refreshed URLs.

## Provider configuration and deployment checks

The client payload must provide `publishable_key` (or `publishable_api_key`),
`amount_minor`, `currency`, `metadata` and permitted `methods`. For Apple Pay it
also needs `apple_pay: {merchant_id, label}`. No merchant identifier was supplied
in the handoff or repository. The deployment owner must provision the Apple Pay
merchant/certificates and matching Xcode Apple Pay entitlement before enabling
that method on a signed iOS build. The app fails visibly if configuration is
absent; it does not invent merchant data. No iOS signing/capability change was made.

Live payment/webhook and device checks were not performed: no Android device was
connected. Test HTTP responses use isolated fixtures, never a real donation.
See `test/feeding_basket_integration_test.dart` for wire bodies, idempotency,
quotes/limits, platform filtering and parsing checks. Existing legacy demo-flow
failures documented previously are separate from this integration's tests.

This supersedes the older handoff statements that multi-item submission was
blocked and payment rows were local previews. Remaining non-checkout gaps in
`USER_APP_DESIGN_BACKEND_GAPS.md` still apply.

## Verification results

- 47 focused test cases passed across basket integration, feeding design,
  API contracts, donor responsiveness, input validation and notification settings.
- `flutter analyze`: no issues.
- Android debug APK builds successfully. Moyasar 3.0.6's API-33 library compile
  setting is aligned to API 36 in the root Gradle configuration; no pub-cache
  changes are required. The upstream plugin still emits a future Kotlin Gradle
  compatibility warning on the installed Flutter version.
- An SDK return without verified funding stays pending; retries reuse the draft.
  A fresh server-paid preflight prevents opening another payment intent.

## Live deployment verification — 14 November 2026

Authenticated live API and Android emulator checks were subsequently performed.
Request create/list/detail return 500; package PKR currency conflicts with the
SAR-only methods response. See [live test report](FEEDING_LIVE_TEST_RESULTS_2026-11-14.md)
for verified passes, frontend fixes, exact blockers and screenshots. Earlier
statements about no connected device/live testing describe the initial integration
pass; the follow-up used an Android emulator.

## Backend redeployment retest

[Live retest results](FEEDING_LIVE_RETEST_2026-11-14.md): request 500s resolved;
basket idempotency, mock funding, server progress and cancellation verified.
The advertised SAR-only payment currency still conflicts with PKR packages.
