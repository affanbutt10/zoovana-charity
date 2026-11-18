# User app design update: backend and image handoff

> Checkout update (14 November 2026): basket quotes/create, contact, method discovery,
> SDK payment and new detail fields are integrated. The older checkout gaps below
> are historical; see [current integration status](FEEDING_BASKET_INTEGRATION_STATUS.md).

Reference: `design/figma/user-app-update/`, copied from the supplied Downloads
`zoovana Project` folder on 12 November 2026. Applies to the donor/user Home,
Requests, Impact and Profile tabs and their updated donor flows. Operator roles,
operator screens and role routing are outside this change.

## Evidence and current behavior

The existing signed-in account was used on Oppo CPH2269. Read-only mobile calls to
`GET /programs`, `GET /requests/my` and notifications returned successfully. The
account has four requests and no completed request, so the live Impact screen
shows an empty verified-feedings state. No request was created, paid, cancelled,
or otherwise changed during visual checking.

The following requirements are based on the current mobile API contracts/models
and the observed responses. Suggested endpoints below are proposals, not existing
APIs. No dummy successful server responses or sample donation metrics were added.

## Required backend work

| Area | Gap / required contract | Current frontend behavior |
| --- | --- | --- |
| Home greeting location | Account/session needs a display location, region and optionally an approximate address. Do not infer the donor's address from programme cities. | Shows programme cities instead of the sample Syria address. |
| Programme / request covers | Populate `GET /programs[].image_url` and `GET /requests/my[].program.image_url`; observed values were null. Return HTTPS image URLs and optionally thumbnails/alt text. | Uses original Figma programme illustrations for the matching Makkah/Madinah animals; a cover URL is supported when returned. These are illustrations, not feeding proof. |
| Package photos | Populate `GET /programs/{id}/packages[].image_url` with the correct food/package photo, not a shared unrelated brand photo. | When absent, a neutral food-bag asset is used. A real package image is still required. |
| City cards | A stable city catalogue with `city_code`, localized display name and `cover_image_url`, plus related programme IDs. | Groups the returned programmes by city and uses supplied city photographs. Explore opens that city's actual programmes. |
| Request card labels | Keep `status` and localized `status_label/status_labels` consistent. Figma's Placed/Assigned/Completed are sample display states, while the API has a richer lifecycle. A short localized `status_short_label` would match the small pills more closely. | Shows the real API status label; long labels wrap. |
| Lifetime impact | Provide donor-wide totals independent of request pagination: `request_count`, `funded_meal_count`, `completed_count`, optionally verified animals/food totals. Suggested `GET /donor/impact/summary`. Clarify whether cancelled/refunded/unpaid requests contribute. | Existing request/meal counts are derived from the loaded request history (first 50 plus loaded pages); not authoritative lifetime metrics. |
| Verified feedings feed | A paginated donor-specific approved proof list, with request/proof IDs, cover, served time, zone/city, meals, food grams and animals. Suggested `GET /donor/feedings`. | Loads completed requests' existing detail endpoints to get actual approved proof; no stock illustration is presented as verified proof. |
| Missing proof images | Every approved proof should have at least one usable image or video thumbnail. Include signed URL expiry and refresh semantics. | A missing-image placeholder appears if approved proof has no usable photo. Existing proof viewer remains available. |
| Profile avatar | Session/profile needs `avatar_url` and an upload/update contract if avatar editing is supported. Current `SessionUser`/`DonorAccount` contract exposes no avatar. | Uses the signed-in user's initial, not the Figma sample person's photo. Edit Profile uses the existing account API. |
| Notification preferences | GET/PATCH donor notification categories and channel settings, enforced by server push/email delivery. Suggested `/donor/notification-preferences`. | Device-local preferences are saved and explicitly identified as not synced; they do not claim to change server delivery. |
| Language/region/currency | Persist preferred locale, country/region and supported currencies; define whether currency is presentation-only or affects payment. French strings are not supplied in the current app. | Supports existing English/Arabic/Urdu; persists device locale. Prices retain API currencies. Does not silently relabel PKR as SAR or offer untranslated French. |
| Help / FAQs | Localized, charity-relevant FAQ categories and answers; support contact and service hours. Suggested `GET /support/faqs`, `GET /support/contact`. | Local guidance for Requests, Feeding Proof and Account. No invented phone/email or 24/7 service claim. |
| Contact Support | Ticket submission contract including authenticated identity, full name, email, phone, message, validation errors and returned ticket reference. Suggested `POST /support/tickets`. | Contact form is rendered read-only with submission disabled while service details are unavailable; no fake submission/success. |
| Privacy & Terms | Approved localized content or HTTPS URLs, document versions and last-updated dates. Suggested `GET /legal/documents`. | Explicit unavailable state; Figma filler text is not shipped as a legal policy. |
| Package quantity/cart | New designs show multiple package quantities. Existing `POST /requests` accepts one `package_id` and no quantity/items. Define `items[{package_id,quantity}]`, server-calculated prices/totals, currency constraints and request/payment ownership before enabling multi-item donations. | List/grid quantity controls and a local multi-item review are implemented. Submission is blocked for multiple items or quantity above one until the API supports the complete basket; no partial request is sent. |
| Card/wallet checkout | Figma includes card details, Apple/Google Pay and e-wallet. Supply gateway tokenization/session contracts, supported payment methods/currencies, webhooks and paid/refunded reconciliation. | The Figma payment layout is implemented, including all method rows, card fields and save-card control. Card inputs stay read-only until tokenization exists; method selection is a local preview, not a charge. Existing single-item draft creation remains supported. |
| Donor/request metadata | New detail frames include donor identity/date/type, scheduled feeding location/time and item quantities. Add donor-safe fields to `GET /requests/{id}` if they should be shown; distinguish actual timestamps from estimates. | All pending/completed detail sections are rendered: information, items, notes/progress or summary/media. Missing dates and notes show unavailable states; approved media alone is shown. No sample donor/schedule values. |

## Image inventory

Original embedded artwork was extracted from the supplied SVG exports; no AI
replacement artwork was generated. All source exports are kept under
`design/figma/user-app-update/`.

Bundled runtime artwork:

| File in `assets/images/donor/` | Used for |
| --- | --- |
| `city_madinah.png` | Madinah city programme card |
| `city_makkah.png` | Makkah city programme card |
| `cats_madinah.png` | Madinah cats programme illustration |
| `cats_makkah.png` | Makkah cats programme illustration |
| `birds_feeding.png` | Birds programme illustration |

Other extracted originals are archived in `embedded-artwork/` under the reference
folder, so unused artwork is not added to the runtime bundle. The sample profile
portrait is intentionally not used as the real signed-in user's avatar.

Still required from backend/content owner: real package/product photographs; real user avatars; non-null programme
and city covers (especially future cities/animal types); actual approved feeding
photos/video thumbnails. Arbitrary dog/unknown programme artwork must not be
mistaken for real proof or a verified programme photograph.

## Visual/behavior differences that await backend work

- Counts, money, request references, dates and statuses are real data, so they
  differ from the Figma samples.
- The live account has no approved feedings; a verified card cannot be verified
  against this account's live backend data.
- Region/currency selectors, remote notification settings, legal content and
  support submission cannot be claimed complete without the contracts above.
- Multiple package quantities and the design's payment methods remain gated by
  the existing backend capabilities.

Detailed feeding-flow contracts and UI behavior: [FEEDING_FLOW_BACKEND_HANDOFF.md](FEEDING_FLOW_BACKEND_HANDOFF.md).
