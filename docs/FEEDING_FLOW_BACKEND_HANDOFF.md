# Feeding flow and request detail handoff

Reference: supplied `design/figma/user-app-update/` exports. Scope: donor feeding
flow and donor request details. Existing operator roles are unchanged.

## Implemented UI

- Package list/grid quantities, local basket totals and responsive step header.
- Payment method rows, card form layout, save-card control and total.
- Review: donation details, every selected item/quantity and payment summary.
- Pending details: feeding information, items, notes and six-stage progress.
- Completed details: feeding summary, information, donation items and six-cell
  approved photo/video gallery with overflow count and viewer.
- Loading skeleton matches the request detail sections.

## Backend requirements

1. **Basket checkout:** existing `POST /requests` accepts one `package_id`.
   Add an agreed `items: [{package_id, quantity}]` contract, validated quantities,
   server prices, currency, totals and availability. Consider a quote endpoint and
   idempotency for checkout retries. Frontend supports draft baskets but blocks
   submission above one item/quantity rather than silently dropping selections.
2. **Payments:** provide gateway/session/tokenization integration, supported
   methods/currencies, wallet availability, server payment state and webhook
   reconciliation. Card fields are read-only; no PAN/CVV is collected or stored.
   Save-card is local preview intent only. Selecting Apple/Google/e-wallet does
   not initiate payment. A legacy request is a draft, not a successful charge.
3. **Donor contact:** account name/email/phone should be available for checkout.
   Missing required contact is collected in a validated sheet. Existing request
   contact fields remain in use.
4. **Request information:** return actual `fed_at`, separate from `approved_at`,
   `expected_completion_at`, location/zone and `feeding_notes`. The frontend does
   not substitute proof approval time for feeding time or invent schedule dates.
5. **Line items:** return `items` or `feeding_items` with `name`, `description`,
   `image_url`, `unit_amount`, `currency`, `quantity`. Existing single-package
   requests fall back to one item with quantity one. Supply canonical unit prices
   so quantity is never inferred from the total.
6. **Progress:** supply actual timestamped lifecycle events; provide explicit
   estimates separately. Pending stages show no invented completion timestamp.
7. **Approved proof:** return meal count, food grams, estimated animals, feeder
   note and approved media with usable HTTPS URLs, type and video thumbnails.
   Define signed URL expiry/refresh. Real feeding photos remain absent for the
   current live account, which has no completed request.
8. **Images:** package image URLs are currently missing. A neutral bundled food
   image is a fallback, not the real product photograph. Supply package images,
   approved proof photos and video thumbnails; Figma samples are not proof.

## Visible behavior while data is missing

Missing notes/dates display explicit unavailable text. Missing proof displays an
empty media state. Prices/currency/statuses come from actual data, so Figma sample
amounts and dates are not copied into live requests. Payment stays pending until
the server confirms funding. Multi-item submission returns an explanatory error
and sends no partial request.

## Validation

`test/feeding_design_test.dart` covers quantity persistence/removal/limits,
integer money totals, preventing partial basket submission, payment/review at
320/393/600 widths, missing detail fields, approved media overflow/viewer, and
narrow RTL layouts with increased text size. Fixture screenshots in the reference
validation folder are test data; they are not live feeding evidence.
