# Feeding basket checkout and request details: mobile integration

For the Flutter donor app. This covers the backend half of the `design/figma/user-app-update/` feeding-flow handoff: basket checkout, payment methods, contact prefill, and the new fields on request details.

| | |
|---|---|
| **Base URL** | same as today: `https://<marketplace-host>/api/v1/feeding` |
| **Auth** | unchanged: `Authorization: Bearer <marketplace access token>`, `Accept-Language: en` or `ar` |
| **Envelope, errors, timestamps** | unchanged; see [FEEDING_MOBILE_API_GUIDE.md §0](FEEDING_MOBILE_API_GUIDE.md#0--conventions) |
| **Compatibility** | additive only. Existing app builds keep working; no field was removed or renamed. |
| **Examples** | every JSON body below was captured from the service running under the test harness. IDs and times are sample data. |

---

## 1. What changed

| Area | Before | Now |
|---|---|---|
| Create request | one `package_id` | `items: [{package_id, quantity}]` (the old body still works) |
| Prices / totals | app could only show one package price | server quote: line totals, grand total, integer minor units |
| Retries | a retried checkout could create a duplicate | `Idempotency-Key` header returns the same request |
| Payment methods | hard-coded in the app | `GET /requests/payment-methods` |
| Contact | app had to read the profile elsewhere | `GET /requests/checkout-contact` |
| Request details | single package, no feeding time | `items[]`, `fed_at`, `zone`, `feeding_notes`, six-stage `progress` |
| Proof videos | `thumbnail_url: null` | signed JPEG poster image |

**Remove these workarounds from the app:**
- Blocking submission above one item/quantity: the backend now accepts baskets.
- Deriving quantity from the total, or showing approval time as the feeding time.
- Copying any Figma sample amounts, dates or photos into live screens.

---

## 2. Screen → endpoint map

| Screen | Call |
|---|---|
| Package list/grid | `GET /programs/{program_id}/packages` (unchanged) |
| Basket / step header totals | `POST /requests/quote` every time the basket changes (debounced) |
| Donor details sheet | `GET /requests/checkout-contact` to prefill |
| Payment method rows | `GET /requests/payment-methods` |
| Review | data from the latest quote, plus contact and notes |
| Submit | `POST /requests` with `Idempotency-Key`, then `POST /requests/{id}/payment-intent` |
| Pending / completed details | `GET /requests/{id}` |
| My donations | `GET /requests/my` |

---

## 3. Quote a basket: `POST /requests/quote`

Server prices for the current basket. **Writes nothing**, so it is safe to call as often as needed.

**Request**

```json
{
  "items": [
    { "package_id": "460e5a5b-5fa1-4385-a14e-d6d3d262de8a", "quantity": 2 },
    { "package_id": "5136c435-14d6-44f1-b01f-4c877a95c20b", "quantity": 1 }
  ]
}
```

**Response `200`**

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "program": { "id": "b2378e8a-6dbe-4fa7-b607-81c62d611443", "title": "Feed community cats in Makkah", "city": "Makkah" },
    "items": [
      {
        "package_id": "460e5a5b-5fa1-4385-a14e-d6d3d262de8a",
        "name": "Small",
        "description": null,
        "image_url": null,
        "quantity": 2,
        "unit_amount": "30.00",
        "unit_amount_minor": 3000,
        "line_amount": "60.00",
        "line_amount_minor": 6000,
        "currency": "SAR",
        "meal_count": 20,
        "food_quantity_grams": 2000,
        "available": true
      },
      {
        "package_id": "5136c435-14d6-44f1-b01f-4c877a95c20b",
        "name": "Medium",
        "description": null,
        "image_url": null,
        "quantity": 1,
        "unit_amount": "75.00",
        "unit_amount_minor": 7500,
        "line_amount": "75.00",
        "line_amount_minor": 7500,
        "currency": "SAR",
        "meal_count": 25,
        "food_quantity_grams": 2500,
        "available": true
      }
    ],
    "total_quantity": 3,
    "meal_count": 45,
    "food_quantity_grams": 4500,
    "amount": "135.00",
    "amount_minor": 13500,
    "currency": "SAR",
    "fulfilment_sla_hours": 72,
    "limits": { "max_line_items": 10, "max_item_quantity": 20 }
  }
}
```

- `meal_count` and `food_quantity_grams` on each item are **line totals** (unit × quantity).
- Use `limits` to cap the quantity stepper and the number of basket lines. Don't hard-code 10/20; they are server config.
- An unavailable or unknown package makes the quote fail (see §8). It is not returned with `available: false`, so treat any error as "refresh the package list".

### Basket rules (apply to quote and create)

| Rule | Error |
|---|---|
| Send `items` **or** `package_id`, never both, never neither | `422` |
| Each `package_id` once per basket; use `quantity` to add more | `422` |
| `quantity` ≥ 1 | `422` |
| `quantity` ≤ `limits.max_item_quantity` | `400 basket_quantity_invalid` |
| Number of lines ≤ `limits.max_line_items` | `400 basket_too_many_items` |
| All packages from one programme | `409 basket_mixed_programs` |
| All packages in one currency | `409 basket_mixed_currency` |

If **any** line is invalid, the whole basket is rejected and no request is created. A partial request is never created.

---

## 4. Contact prefill: `GET /requests/checkout-contact`

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "full_name": "Sara Ahmed",
    "email": "sara@example.co.uk",
    "phone_number": "+447700900123",
    "missing": [],
    "optional": ["phone_number", "country_code"]
  }
}
```

- If `missing` is non-empty (it can contain `full_name`, `email`), open the validated contact sheet and require those fields before submit.
- Send the edited values in the create body. Anything you leave out defaults to the account values.

---

## 5. Payment methods: `GET /requests/payment-methods`

```json
{
  "success": true,
  "message": "Success",
  "data": {
    "provider": "moyasar",
    "currencies": ["SAR"],
    "methods": [
      { "id": "card", "type": "card", "provider_method": "creditcard", "networks": ["mada", "visa", "mastercard"], "platforms": ["ios", "android"] },
      { "id": "apple_pay", "type": "wallet", "provider_method": "applepay", "platforms": ["ios"] },
      { "id": "stc_pay", "type": "wallet", "provider_method": "stcpay", "platforms": ["ios", "android"] }
    ],
    "saved_cards": { "supported": false, "reason": "not_enabled" },
    "flow": "Create the request, then POST /requests/{id}/payment-intent and open the provider sheet with client_payload. The request stays unpaid until the provider webhook is verified server-side."
  }
}
```

(Production sends the Moyasar list shown. Dev and test run the mock gateway and return `provider: "mock"` with `card` only.)

- **Only render a method row if it is in `methods` and its `platforms` include the current OS.** Apple Pay must never show on Android.
- **Google Pay is not supported** by the gateway, so remove that row from the design.
- `saved_cards.supported` is `false`: hide the save-card switch, or keep it as a disabled preview. Nothing is stored either way.
- Never collect card number/CVV in Flutter fields. Card entry happens in the provider SDK sheet.
- Selecting a method does not start a payment. Payment starts only after `payment-intent` (§7).

---

## 6. Create the request: `POST /requests`

**Headers**

```http
Authorization: Bearer <token>
Accept-Language: en
Idempotency-Key: 8f14e45f-ceea-467f-a0e6-1c2b3d4e5f60
```

**Request**

```json
{
  "items": [
    { "package_id": "460e5a5b-5fa1-4385-a14e-d6d3d262de8a", "quantity": 2 },
    { "package_id": "5136c435-14d6-44f1-b01f-4c877a95c20b", "quantity": 1 }
  ],
  "full_name": "Sara Ahmed",
  "email": "sara@example.co.uk",
  "phone_number": "+447700900123",
  "country_code": "GB",
  "feeding_notes": "Near the Aziziyah park",
  "dedication": "For my grandmother",
  "is_anonymous": false,
  "notify_push": true,
  "notify_email": true,
  "locale": "en"
}
```

| Field | Notes |
|---|---|
| `items` | required (or legacy `package_id`) |
| `feeding_notes` | **new**, optional, ≤ 500 chars; the donor's note shown on request details. Blank becomes `null`. |
| everything else | unchanged from the current create body |

**Response `201`**: the full request detail (§9), status `draft`.

### Idempotency-Key

- Generate **one UUID when the donor taps "Pay / Confirm"** and keep it for that checkout attempt.
- Reuse it for network retries and timeouts: the server returns the **same** request (`201`, same `id`), never a second one.
- If the donor changes the basket or details, generate a **new** key. Reusing a key with a different body returns:

```json
{ "success": false, "message": "Idempotency-Key was already used for a different checkout", "code": "idempotency_key_reused", "details": {} }
```

- Without the header, every call creates a new request (old behaviour).

---

## 7. Payment (unchanged flow)

1. `POST /requests/{id}/payment-intent` → `client_payload` (Moyasar: publishable key, `amount_minor`, `currency`, `metadata`, `methods`).
2. Open the Moyasar SDK sheet with that payload. Do not change the amount.
3. On return, **poll `GET /requests/{id}`** until `payment_status == "paid"` (status moves past `payment_pending`). The SDK's "success" callback alone is not proof of payment; only the verified webhook marks a request paid.
4. Unpaid requests auto-cancel after 60 minutes. A `draft` is not a successful charge, so don't show a receipt for it.

---

## 8. Errors to handle in the basket flow

| HTTP | `code` | When | UI |
|---|---|---|---|
| 400 | `basket_quantity_invalid` | quantity above max (`details.max`, `details.package_id`) | clamp stepper to `details.max` |
| 400 | `basket_too_many_items` | too many lines (`details.max_line_items`) | block adding |
| 404 | `package_not_found` | package deleted | refresh packages, drop the line |
| 409 | `package_inactive` | package switched off (`details.package_id`) | refresh packages, drop the line |
| 404 | `program_not_found` | programme inactive | back to charity home |
| 409 | `basket_mixed_programs` / `basket_mixed_currency` | items from different campaigns | keep one programme per basket |
| 409 | `idempotency_key_reused` | key reused with changed body | new key, resubmit |
| 400 | `donor_details_required` | name/email missing (`details.missing`) | open contact sheet |
| 429 | `rate_limited` | > 10 requests/hour (`Retry-After` header) | show wait message |
| 422 | (FastAPI `detail[]`) | duplicate package, both/neither of items/package_id, quantity < 1 | developer error, so fix the body |

Example:

```json
{ "success": false, "message": "Quantity out of range", "code": "basket_quantity_invalid",
  "details": { "package_id": "460e5a5b-5fa1-4385-a14e-d6d3d262de8a", "min": 1, "max": 20 } }
```

---

## 9. Request details: `GET /requests/{id}`

### 9.1 New fields

| Field | Type | Meaning |
|---|---|---|
| `items[]` | list | line items, same shape as quote items (without `available`). Older requests return **one** item, quantity 1. |
| `total_quantity` | int | sum of quantities |
| `amount_minor` | int | total in minor units (halalas) |
| `feeding_notes` | string? | donor's note from checkout; `null` → show "No notes" |
| `fed_at` | datetime? | **actual feeding time** reported by the feeder on the approved proof. `null` until approved. |
| `approved_at` | datetime? | when the proof was reviewed and approved. **Not** the feeding time. |
| `zone` | `{id, name}`? | feeding area once operations set it; `null` → show "Location to be confirmed" or the programme city |
| `progress` | object | six stages, see 9.3 |
| `package.image_url` | string? | first item with a photo |
| `proof.fed_at`, `proof.submitted_at` | datetime? | new on the proof object; `proof.completed_at` is **deprecated** (use `fed_at`) |
| `proof.media[].thumbnail_url` | string? | images: same as `url`; videos: signed JPEG poster |

`package.name` for a basket is a joined label such as `"Small ×2 + Medium"`. Render `items[]` for the item list instead.

### 9.2 Pending example (feeder assigned)

```json
{
  "id": "708324fd-bc47-491c-924a-1ecf9ba5c217",
  "reference": "FR-20261114-00001",
  "status": "assigned",
  "status_label": "Feeder assigned",
  "package": { "id": "460e5a5b-…", "name": "Small ×2 + Medium", "image_url": null, "meal_count": 45, "food_quantity_grams": 4500, "fulfilment_sla_hours": 72 },
  "items": [
    { "package_id": "460e5a5b-…", "name": "Small", "description": null, "image_url": null, "quantity": 2,
      "unit_amount": "30.00", "unit_amount_minor": 3000, "line_amount": "60.00", "line_amount_minor": 6000,
      "currency": "SAR", "meal_count": 20, "food_quantity_grams": 2000 },
    { "package_id": "5136c435-…", "name": "Medium", "description": null, "image_url": null, "quantity": 1,
      "unit_amount": "75.00", "unit_amount_minor": 7500, "line_amount": "75.00", "line_amount_minor": 7500,
      "currency": "SAR", "meal_count": 25, "food_quantity_grams": 2500 }
  ],
  "total_quantity": 3,
  "amount": "135.00",
  "amount_minor": 13500,
  "currency": "SAR",
  "payment_status": "paid",
  "paid_at": "2026-11-14T07:52:46.723513+00:00",
  "feeding_notes": "Near the Aziziyah park",
  "created_at": "2026-11-14T07:52:46.389728+00:00",
  "fed_at": null,
  "approved_at": null,
  "expected_completion_at": "2026-11-17T07:52:46.723513+00:00",
  "completed_at": null,
  "zone": { "id": "8e9a5e5b-2899-4145-93d7-1a95fa097713", "name": "Al-Aziziyah" },
  "progress": {
    "stages": [
      { "key": "created",   "label": "Request created",     "state": "done",     "occurred_at": "2026-11-14T07:52:46.389728+00:00" },
      { "key": "paid",      "label": "Payment confirmed",   "state": "done",     "occurred_at": "2026-11-14T07:52:46.723513+00:00" },
      { "key": "assigned",  "label": "Feeder assigned",     "state": "done",     "occurred_at": "2026-11-14T07:52:46.908815+00:00" },
      { "key": "preparing", "label": "Food being prepared", "state": "current",  "occurred_at": null },
      { "key": "feeding",   "label": "Feeding in progress", "state": "upcoming", "occurred_at": null },
      { "key": "completed", "label": "Feeding completed",   "state": "upcoming", "occurred_at": null }
    ],
    "current_stage": "preparing",
    "halted_status": null,
    "estimated_completion_at": "2026-11-17T07:52:46.723513+00:00"
  },
  "proof": null
}
```

(Unchanged fields such as `program`, `status_labels`, `timeline`, `dedication` and `notify_*` are trimmed here.)

### 9.3 Progress rules

| | |
|---|---|
| Stage keys (fixed order) | `created`, `paid`, `assigned`, `preparing`, `feeding`, `completed` |
| `state` | `done` · `current` · `upcoming` · `halted` (cancelled/refunded: stages that never happened) |
| `occurred_at` | real time the stage **began**; only set when `state == "done"`. Never show a time for `current`/`upcoming`. |
| `estimated_completion_at` | an **estimate**; label it as such ("Expected by …"). `null` before payment and after a terminal status. |
| `current_stage` | key of the active stage; `null` when completed or halted |
| `halted_status` | `cancelled` or `refunded` when the flow stopped; otherwise `null` |

A `done` stage can still have `occurred_at: null` if no event was recorded for it. Show the tick without a time.

### 9.4 Completed example (proof section)

```json
{
  "status": "completed",
  "fed_at": "2026-11-14T07:52:47.618718+00:00",
  "approved_at": "2026-11-14T07:52:47.750826+00:00",
  "completed_at": "2026-11-14T07:52:47.750826+00:00",
  "zone": { "id": "8e9a5e5b-…", "name": "Al-Aziziyah" },
  "progress": { "current_stage": null, "halted_status": null, "estimated_completion_at": null, "stages": [ "…all six with state done…" ] },
  "proof": {
    "id": "039dff7e-09ab-4dfd-b33c-5961ee5e2966",
    "review_status": "approved",
    "fed_at": "2026-11-14T07:52:47.618718+00:00",
    "submitted_at": "2026-11-14T07:52:47.618718+00:00",
    "completed_at": "2026-11-14T07:52:47.618718+00:00",
    "approved_at": "2026-11-14T07:52:47.750826+00:00",
    "approximate_zone": "Al-Aziziyah",
    "meal_count": 45,
    "food_quantity_grams": 4500,
    "animals_fed_estimate": 30,
    "feeder_note": "Fed near the park",
    "media": [
      {
        "id": "13c7b38d-3849-4f86-b606-db315c75e2a3",
        "media_type": "image",
        "resource_type": "image",
        "url": "https://res.cloudinary.com/<cloud>/image/authenticated/s--…--/v1/feeding/proofs/…/….jpg",
        "thumbnail_url": "https://res.cloudinary.com/<cloud>/image/authenticated/s--…--/v1/feeding/proofs/…/….jpg",
        "expires_at": null,
        "width": 800,
        "height": 600,
        "captured_at": null
      }
    ],
    "receipt_summary": null
  }
}
```

Completed screen mapping:

| UI | Field |
|---|---|
| Feeding date/time | `fed_at` (fallback text "Feeding time not reported" if `null`) |
| Verified on | `approved_at` |
| Location | `zone.name` → else `proof.approximate_zone` → else `program.city` |
| Meals / food / animals | `proof.meal_count`, `proof.food_quantity_grams`, `proof.animals_fed_estimate` (may be `null`) |
| Feeder note | `proof.feeder_note` (may be `null`) |
| Gallery (six cells + "+N") | `proof.media[]`; tile image = `thumbnail_url`; video when `media_type == "video"` (play `url`) |
| Empty media state | `proof == null` or `proof.media` empty |

### 9.5 Media URLs

- URLs are **signed on every read**. If `expires_at` is non-null and has passed, or an image load fails with 401/404, **re-fetch `GET /requests/{id}`** to get fresh URLs. Don't cache URLs across sessions.
- Proof media only appears once the proof is approved. Unapproved proof is never sent to the donor.

---

## 10. My donations: `GET /requests/my`

New fields per row: `image_url` (first item photo or `null`), `total_quantity`, `amount_minor`. `package_name` is the joined basket label.

```json
{
  "id": "708324fd-bc47-491c-924a-1ecf9ba5c217",
  "reference": "FR-20261114-00001",
  "status": "completed",
  "package_name": "Small ×2 + Medium",
  "image_url": null,
  "total_quantity": 3,
  "meal_count": 45,
  "amount": "135.00",
  "amount_minor": 13500,
  "currency": "SAR",
  "has_proof": true
}
```

---

## 11. Money in Dart

- Do all arithmetic on the `*_minor` integers (halalas). Display = `minor / 100` with 2 decimals, formatted for locale/RTL.
- The basket total shown before submit must come from the **latest quote**, not from local multiplication. Local maths is fine for instant feedback while the quote request is in flight.
- `currency` always comes from the response. Never assume SAR in code.

---

## 12. Missing data: what the app should show

| Data | Current state | Show |
|---|---|---|
| Package / item `image_url` | `null` for all live packages (photos not uploaded yet) | neutral bundled food placeholder, not a Figma sample photo |
| `description` | often `null` | hide the line |
| `feeding_notes` | `null` unless donor typed one | "No notes" |
| `fed_at` | `null` until proof approved | "Not fed yet" / omit |
| `zone` | `null` until operations assign one | programme city |
| `expected_completion_at` | `null` before payment | omit |
| Proof media | none for the current live account (no completed request yet) | empty media state |

---

## 13. Not available yet

| Item | Status |
|---|---|
| Saved cards | not supported (`saved_cards.supported: false`); needs a product decision on Moyasar tokenization |
| Google Pay | not offered by the gateway |
| Real package photos | field ready; operations must upload images via the CMS package editor |

---

## 14. Test checklist

- [ ] Quote updates on every quantity change; stepper capped at `limits.max_item_quantity`.
- [ ] Multi-item basket creates **one** request; detail shows each item with its quantity.
- [ ] Killing the network during submit and retrying with the same `Idempotency-Key` gives the same request id.
- [ ] Changing the basket after a failed submit uses a new key.
- [ ] Apple Pay row hidden on Android; no Google Pay row; save-card hidden or disabled.
- [ ] Request stays "payment pending" until `payment_status == "paid"` from the server.
- [ ] Pending detail: no time on current/upcoming stages; estimate labelled as expected.
- [ ] Completed detail: feeding time uses `fed_at`, not `approved_at`.
- [ ] Video tile shows the poster from `thumbnail_url`.
- [ ] Old single-package requests still render (one item, quantity 1).
- [ ] RTL (`Accept-Language: ar`) at 320 px with increased text size.