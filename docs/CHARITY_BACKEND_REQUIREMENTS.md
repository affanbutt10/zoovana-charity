# Zoovana Charity App — Backend Requirements and Integration Handoff

## 1. Purpose

This document defines the backend support required by the standalone **Zoovana Charity** mobile app.

The app has two private experiences behind one login screen:

1. **Donor experience** — browse active animal-feeding programmes, choose a feeding package, create a charity request, follow its progress, and view approved proof and impact.
2. **Operator experience** — an approved feeder receives assigned tasks, accepts or declines them, updates work progress, submits proof, and follows payout status.

The word **Operator** is used in the mobile UI. The existing backend role and API name remain **`feeder`**.

Administrative work is not part of the new mobile app. Programme management, assignment, feeder approval, proof review, reports, refunds, and finance operations remain in the Zoovana CMS.

## 2. Phase-one scope

### Included

- Donor and operator authentication.
- Automatic donor/operator routing from authenticated account information.
- Public active feeding programmes and approved highlights.
- Fixed feeding packages.
- Donor details and charity-request creation.
- Donor request history, status tracking, approved proof, and impact summary.
- Donor and operator in-app notifications and deep links.
- Operator application/KYC and verification status.
- Operator availability and daily capacity.
- Operator task acceptance, decline, progress, proof submission, rejection correction, and resubmission.
- Operator payout history/status as read-only information.
- English and Arabic API content.
- Role isolation, privacy, validation, event history, and auditability.

### Explicitly deferred

Payment-provider selection, card entry, wallets, payment SDKs, live checkout, payment webhooks, and production refund processing will be specified in a later phase.

Existing payment-related database fields and states may remain. They must not be removed. For development and demo testing, the backend may continue using seeded requests or its existing server-controlled mock/funding mechanism. Production payment integration is not an acceptance criterion for this phase.

### Excluded from this app

- Marketplace products, cart, delivery orders, and receipts.
- Pet profiles and pet-care services.
- Adoption.
- Shelter item donations.
- Generic service-provider bookings.
- Feeding administration, catalogue management, assignment board, proof review, reports, refunds, and payout administration.

## 3. Required application modes and routing

The mobile app must never display an Operator switch, Provider switch, or role selector to normal users.

After authentication, the backend response must allow the app to select exactly one shell:

```text
feeder role
  → operator shell

mp_client token or marketplace_client role
  → donor shell

any other staff-only role
  → unsupported/no-access screen
```

When an account has both `feeder` and donor access, **`feeder` takes precedence** and the app opens the operator shell.

### Required normalized login result

The existing applications currently use different login endpoints:

- Donor: `POST {AUTH}/api/v1/mp-clients/login`
- Operator/staff: `POST {AUTH}/api/v1/auth/login`

For a single login form with automatic routing, the preferred backend addition is:

```http
POST {AUTH}/api/v1/charity/auth/login
```

Request:

```json
{
  "email": "person@example.com",
  "password": "secret",
  "fcm_token": "optional-device-token",
  "device_id": "optional-stable-device-id",
  "locale": "en"
}
```

Normalized response:

```json
{
  "success": true,
  "data": {
    "access_token": "...",
    "refresh_token": "...",
    "expires_in": 3600,
    "token_type": "bearer",
    "account_type": "staff",
    "roles": ["feeder"],
    "app_mode": "operator",
    "user": {
      "id": "uuid",
      "email": "person@example.com",
      "full_name": "Operator Name"
    },
    "feeder_profile": {
      "id": "uuid",
      "verification_status": "approved"
    }
  }
}
```

Allowed `app_mode` values:

- `donor`
- `operator`
- `unsupported`

If a unified login endpoint cannot be added, both existing login endpoints must return a distinct machine-readable `wrong_account_type` error so the client can safely try the appropriate alternate endpoint. The app must not rely on email patterns or hardcoded account lists.

### Session context

Add or confirm a token-authenticated endpoint that returns the same normalized account information during app startup:

```http
GET {AUTH}/api/v1/charity/auth/session
```

This endpoint is required so a restored token routes to the correct shell without briefly displaying donor screens.

## 4. Authorization rules

Backend authorization is authoritative even when the mobile UI hides routes.

| Identity | Allowed mobile capabilities |
|---|---|
| `mp_client` | Donor endpoints for the authenticated donor only |
| `marketplace_client` | Donor endpoints for the authenticated donor only |
| `feeder` + approved feeder profile | Operator profile, own tasks, own proof uploads, own payouts |
| `feeder` + pending/rejected/suspended profile | Own profile and verification state only |
| `feeding_admin` | CMS only |
| `feeding_reviewer` | CMS only |
| `finance_admin` | CMS only |
| `super_admin` | CMS only unless it also has an approved feeder profile |

Requirements:

- A donor token must receive `403` from all feeder endpoints.
- A feeder must never access another feeder's tasks, media, proof, or payouts.
- A wrong-role `403` must return a stable code such as `insufficient_role`; it must not be represented as an expired login.
- An unapproved feeder must receive a code such as `feeder_profile_not_approved` and the current verification status.
- All sensitive actions must be recorded in an immutable audit/event log.

## 5. Shared API conventions

### Base URL

```text
{MARKETPLACE_HOST}/api/v1/feeding
```

Feeding remains part of the Marketplace backend service. It is not a separate service.

### Response envelope

```json
{
  "success": true,
  "message": "Optional localized message",
  "data": {}
}
```

Paginated response:

```json
{
  "success": true,
  "data": [],
  "meta": {
    "page": 1,
    "page_size": 20,
    "total": 0,
    "total_pages": 0,
    "has_next": false,
    "has_prev": false
  }
}
```

Error response:

```json
{
  "success": false,
  "message": "Readable localized error",
  "code": "machine_readable_code",
  "details": {}
}
```

### General rules

- Respect `Accept-Language: en` and `Accept-Language: ar`.
- Return timestamps as ISO 8601 values with timezone information.
- Return money as two-decimal strings and always include currency.
- IDs must be stable UUID/string values.
- Mutating endpoints must validate the current state on the server.
- Repeated accept/status/proof requests must be idempotent where practical.
- List endpoints must support pagination.
- Signed media URLs must use HTTPS and include `expires_at` when they expire.

## 6. Operational state machine

The backend owns all state transitions. The mobile app only requests a transition and renders the server result.

The phase-one operational lifecycle is:

```text
awaiting_assignment
  → assigned
  → accepted
  → purchasing
  → feeding
  → proof_submitted
  → completed
```

Exception paths:

```text
assigned / accepted
  → reassignment_required

proof_submitted
  → proof_rejected
  → feeding
  → proof_submitted
```

Rules:

- Only operations staff may assign or reassign a request.
- Only the assigned approved feeder may accept, decline, update, upload, or submit proof.
- The operator may never mark a request `completed`.
- Only an authorized reviewer/admin proof approval may transition a request to `completed`.
- Completion must generate the donor notification and payout eligibility.
- Every transition must record actor, timestamp, previous state, new state, and optional reason.

## 7. Donor experience requirements

### 7.1 Programme discovery

Existing endpoints to preserve:

```http
GET /programs
GET /programs/{program_id}
GET /programs/{program_id}/highlights?limit=10
GET /programs/{program_id}/packages
```

The app design contains city and animal choices. These choices must be derived from active programmes returned by the API; the app will not hardcode Makkah, Madinah, cats, or birds.

Programme fields:

```text
id, code, city_code, city_name_en, city_name_ar, country_code,
animal_type, title_en, title_ar, description_en, description_ar,
image_url, fulfilment_sla_hours, is_active, sort_order
```

Highlight fields:

```text
proof_id, program_id, approximate_zone_en, approximate_zone_ar,
meal_count, food_quantity_grams, animals_fed_estimate,
feeder_note, fed_at, media
```

Only approved and anonymised proof may appear in highlights.

### 7.2 Fixed feeding packages

The mobile design will select one package per request. A package is an impact package, not a cart product, and must not require a delivery address.

Package fields:

```text
id, program_id, code, name_en, name_ar,
description_en, description_ar, image_url,
price, currency, meal_count, food_quantity_grams,
fulfilment_sla_hours, is_popular, sort_order, is_active
```

Internal food cost, operator fee, platform fee, VAT, and margin must not be returned by donor endpoints.

### 7.3 Create charity request

Existing endpoint to preserve:

```http
POST /requests
```

Request:

```json
{
  "package_id": "uuid",
  "full_name": "Sara Ahmed",
  "email": "sara@example.com",
  "phone_number": "+966500000000",
  "country_code": "SA",
  "dedication": "Optional donor message",
  "is_anonymous": false,
  "notify_push": true,
  "notify_email": true,
  "locale": "en"
}
```

The backend must snapshot programme/package title, price, currency, meal count, food quantity, SLA, and internal cost split so later catalogue edits do not change an existing request.

Payment activation is outside this document. For development, the backend may return the state produced by the configured demo/seed mechanism.

### 7.4 Donor request list and details

Existing endpoints to preserve:

```http
GET  /requests/my?page=1&page_size=20&status=
GET  /requests/{request_id}
POST /requests/{request_id}/cancel
```

The list must return enough information for a status card:

```text
id, reference, status, status_label, status_labels,
package_name, amount, currency, created_at,
expected_completion_at, completed_at, has_proof
```

The detail must return:

```text
id, reference, status, status_label, status_labels,
program, package, amount, currency,
created_at, expected_completion_at, completed_at,
dedication, donor-safe timeline, approved proof
```

Donor-facing status mapping:

| Internal state | Donor-facing meaning |
|---|---|
| `awaiting_assignment` | Finding a local operator |
| `assigned` | Operator assigned |
| `accepted` / `purchasing` | Food is being prepared |
| `feeding` | Feeding round in progress |
| `proof_submitted` | Proof is being reviewed |
| `proof_rejected` | Verification is in progress |
| `reassignment_required` | Arranging another operator |
| `completed` | Feeding completed |
| `cancelled` | Cancelled |
| `refunded` | Refunded |

The donor must never receive internal rejection reasons, reviewer notes, precise GPS, operator identity/KYC, bank information, or payout data.

### 7.5 Approved proof

`proof` must be `null` until the proof is approved.

Approved donor proof:

```json
{
  "review_status": "approved",
  "approved_at": "2026-10-27T12:00:00+03:00",
  "approximate_zone": "Al-Aziziyah",
  "meal_count": 50,
  "food_quantity_grams": 3000,
  "animals_fed_estimate": 35,
  "feeder_note": "The feeding round was completed safely.",
  "media": [
    {
      "id": "uuid",
      "media_type": "image",
      "url": "https://signed-media-url",
      "thumbnail_url": "https://signed-thumbnail-url",
      "expires_at": null
    }
  ],
  "receipt_summary": {
    "amount": "92.50",
    "currency": "SAR",
    "has_receipt_image": true
  }
}
```

The receipt image itself must not be returned to donors.

## 8. Operator experience requirements

### 8.1 Operator application and profile

Existing endpoints to preserve:

```http
POST  /feeders/apply
GET   /feeders/me
PATCH /feeders/me
```

Application fields:

```text
program_id, full_name, phone_number, email, zone_ids,
bank_account_holder_name, bank_name, iban,
daily_capacity, fcm_token,
government_id_front, government_id_back, selfie_with_id
```

Verification states:

```text
pending_review, approved, rejected, suspended
```

Profile response must include:

```text
id, full_name, phone_number, verification_status,
rejection_reason when applicable,
programs, zones, is_available, daily_capacity,
tasks_completed, iban_last_four
```

Never return a full stored IBAN after application submission.

### 8.2 Operator dashboard summary

New endpoint required for the dashboard design:

```http
GET /feeder/dashboard/summary
```

Response:

```json
{
  "success": true,
  "data": {
    "new_tasks": 2,
    "active_tasks": 1,
    "completed_tasks": 12,
    "is_available": true,
    "daily_capacity": 5,
    "eligible_payout_amount": "30.00",
    "currency": "SAR"
  }
}
```

The design's On Duty switch must update `is_available` through `PATCH /feeders/me`.

### 8.3 Operator task list

Existing endpoint to preserve:

```http
GET /feeder/tasks?status=&page=1&page_size=20
```

Task summary fields:

```text
id, request_id, request_reference, status,
program_name, package_name, meal_count,
food_quantity_grams, food_budget, feeder_fee, currency,
zone, instructions, accept_deadline_at,
proof_rejection_reason, can_resubmit
```

The task response must not expose donor name, email, phone number, dedication identity, or other donor personal information.

### 8.4 Operator task detail

New or confirm existing endpoint:

```http
GET /feeder/tasks/{assignment_id}
```

Required fields:

```text
id, request_id, request_reference, status,
program, package, meal_count, food_quantity_grams,
food_budget, feeder_fee, currency,
zone, instructions, accept_deadline_at,
allowed_actions, timeline,
proof_rejection_reason, previous_proof
```

The current operator design contains a map and directions action. If operations assigns a specific approved feeding point, return it only to the assigned operator:

```json
{
  "feeding_location": {
    "label_en": "Approved feeding point",
    "label_ar": "نقطة التغذية المعتمدة",
    "latitude": 21.4105,
    "longitude": 39.8223,
    "navigation_allowed": true
  }
}
```

If the backend supports only a zone and not a precise destination, return `feeding_location: null`. The app will show the zone/instructions and will not show a fake map.

The design also contains a Buy Items checklist. To support it without coupling charity to the marketplace cart, the package/assignment may return optional operational requirements:

```json
{
  "purchase_requirements": [
    {
      "id": "food-target",
      "name_en": "Dry cat food",
      "name_ar": "طعام قطط جاف",
      "quantity": 3,
      "unit": "kg",
      "image_url": null,
      "required": true
    }
  ]
}
```

If this field is absent, the app will display only the food quantity and budget target.

### 8.5 Task actions

Existing endpoints to preserve:

```http
POST /feeder/tasks/{assignment_id}/accept
POST /feeder/tasks/{assignment_id}/decline
POST /feeder/tasks/{assignment_id}/status
```

Decline payload:

```json
{
  "reason": "Unavailable during the required period"
}
```

Status payload:

```json
{
  "status": "purchasing"
}
```

Only `purchasing` and `feeding` are operator-controlled working states. `on_the_way` may be shown as local guidance but must not be stored as a backend status unless the state machine is formally extended.

Responses should return the updated task, including `allowed_actions`, instead of only returning an empty success response.

### 8.6 Media upload

Existing multipart endpoint:

```http
POST /feeder/tasks/{assignment_id}/media
```

Supported `media_type` values:

```text
image, video, receipt
```

Requirements:

- Maximum eight proof files in total.
- Maximum 10 MB per image.
- MP4/MOV video support up to the configured backend limit.
- At least one feeding photo or video is required.
- Receipt media is internal and must never be returned to a donor.
- Return a media record after upload so the app can preview, remove, or retry it.
- Validate content type from file content, not filename only.

Existing/confirm direct-upload endpoints for large videos:

```http
GET  /feeder/tasks/{assignment_id}/media/upload-signature?resource_type=video
POST /feeder/tasks/{assignment_id}/media/register
```

Add or confirm removal before proof submission:

```http
DELETE /feeder/tasks/{assignment_id}/media/{media_id}
```

### 8.7 Submit proof

Existing endpoint to preserve:

```http
POST /feeder/tasks/{assignment_id}/proof
```

Payload:

```json
{
  "latitude": 21.4105,
  "longitude": 39.8223,
  "gps_accuracy_m": 8.0,
  "meal_count": 50,
  "animals_fed_estimate": 35,
  "feeder_note": "Fed the animals and cleaned the area.",
  "receipt_amount": "92.50",
  "media_ids": ["uuid-1", "uuid-2", "uuid-3"]
}
```

Requirements:

- Validate that every media ID belongs to the same assigned operator and task.
- Validate at least one image/video.
- Preserve exact GPS for internal review only.
- Record the device accuracy value.
- Reject impossible state transitions with a machine-readable code.
- On success, return the updated task with `status: proof_submitted`.
- The operator sees an Under Review state and cannot complete the task.

### 8.8 Proof correction and resubmission

When proof is rejected for retry, the operator task response must include:

```json
{
  "status": "proof_rejected",
  "proof_rejection_reason": "Please upload a clearer feeding photo.",
  "can_resubmit": true,
  "previous_proof": {
    "id": "uuid",
    "media": []
  }
}
```

The operator can upload replacements and submit proof again. Reviewer-only internal notes and fraud flags must not be returned.

### 8.9 Operator payouts

Existing/documented endpoint to confirm in the deployed backend:

```http
GET /feeder/payouts?status=&page=1&page_size=20
```

Read-only payout fields:

```text
id, request_id, request_reference, amount, currency,
status, eligible_at, approved_at, paid_at
```

The mobile app does not approve, export, cancel, or mark payouts as paid. Those actions remain in CMS/finance.

## 9. Notifications and deep links

Existing donor endpoints:

```http
GET  /notifications?page=1&page_size=20&unread_only=false
POST /notifications/{notification_id}/read
POST /notifications/read-all
```

Confirm the same list/read behavior for the authenticated operator. A notification must contain:

```text
id, notification_type, title, body,
is_read, created_at, target_type, target_id, deep_link
```

Deep links:

```text
zoovana-charity://donor/request/{request_id}
zoovana-charity://operator/task/{assignment_id}
```

Important events:

- Donor: request accepted, operator assigned, proof submitted when enabled, feeding completed, reassignment, cancellation/refund outcome.
- Operator: new assignment, acceptance deadline reminder, reassignment/cancellation, proof approved, proof rejected for retry, payout eligible, payout paid.

FCM token registration must support login, token refresh, logout, and multiple devices. The API must never reject a valid token because the app and backend use different Firebase projects.

## 10. CMS responsibilities retained

The following existing operations remain outside the Charity mobile app:

```http
GET  /admin/requests
POST /admin/requests/{request_id}/assign
GET  /admin/proofs
GET  /admin/proofs/{proof_id}
POST /admin/proofs/{proof_id}/approve
POST /admin/proofs/{proof_id}/reject
GET  /admin/feeders
GET  /admin/feeders/{feeder_id}
POST /admin/feeders/{feeder_id}/review
GET/POST/PATCH /admin/programs
GET/POST/PATCH /admin/programs/{program_id}/zones
GET/POST/PATCH /admin/programs/{program_id}/packages
GET  /admin/payouts
GET  /admin/reports/summary
```

The CMS remains responsible for:

- Programme, zone, and package configuration.
- Feeder KYC review and approval.
- Request assignment/reassignment.
- Proof review and completion.
- Payout administration.
- Reports, audit, exceptions, and future refunds.

## 11. Privacy and security

### Donor-safe responses

Never expose:

- Operator identity.
- Operator KYC.
- Operator bank information.
- Exact proof GPS.
- Receipt image.
- Internal assignment/review notes.
- Fraud or safety flags.
- Operator earnings or payout data.

### Operator-safe responses

Never expose:

- Donor name unless operations has documented a strict operational need.
- Donor email or phone number.
- Donor account identifiers.
- Payment credentials or transaction details.
- Reviewer identity or internal fraud notes.

### Storage

- KYC, receipts, and proof media must remain private.
- Use signed HTTPS URLs.
- KYC and receipt URLs must be role-protected.
- Log media access where required by policy.
- Do not include production demo passwords or credentials in source control.

## 12. Required error codes

At minimum, support these stable codes:

```text
invalid_credentials
wrong_account_type
token_expired
insufficient_role
feeder_profile_missing
feeder_profile_not_approved
task_not_found
task_not_assigned_to_user
acceptance_deadline_expired
invalid_state_transition
media_limit_exceeded
media_too_large
unsupported_media_type
proof_media_required
gps_required
gps_accuracy_unacceptable
validation_error
rate_limited
```

Validation errors should identify fields in `details.fields`.

## 13. Screen-to-API mapping

### Donor shell

| Mobile screen | Backend dependency |
|---|---|
| Login | Normalized Charity login/session context |
| Charity home | Programmes and approved highlights |
| City/animal selection | Active programme fields |
| Package selection | Programme packages |
| Donor details | Create request |
| Request confirmation | Created request response |
| My charity requests | Donor request list |
| Request status/detail | Donor request detail and timeline |
| Verified impact | Approved donor-safe proof |
| Notifications | Notification list/read/deep link |
| Profile/logout | Auth profile/session/logout |

### Operator shell

| Mobile screen | Backend dependency |
|---|---|
| Login | Normalized Charity login/session context with `feeder` role |
| Application/KYC | Apply endpoint and programme/zone lists |
| Verification status | Feeder profile |
| Operator dashboard | New dashboard summary endpoint |
| Availability/On Duty | Feeder profile PATCH |
| Assigned/active/completed tasks | Paginated task list |
| Task detail | Task-detail endpoint |
| Accept/decline | Accept and decline endpoints |
| Purchase/feeding progress | Status endpoint |
| Proof capture | Media endpoints and device GPS |
| Proof review state | Updated task state |
| Proof correction | Rejection reason and resubmission |
| Payouts | Read-only feeder payout list |
| Notifications | Operator notification list/read/deep link |
| Profile/logout | Feeder profile and auth logout |

## 14. Acceptance criteria

### Authentication and routing

- Donor credentials open the donor shell without displaying operator UI.
- Approved feeder credentials open the operator shell without displaying donor UI.
- Pending/rejected/suspended feeders open only their profile/status experience.
- Admin, reviewer, and finance-only credentials do not expose their CMS tools in the Charity app.
- App restart restores the correct shell from the session endpoint.
- Direct navigation to an unauthorized route is rejected by both client and backend.

### Donor

- Active programmes and packages are entirely API-driven.
- A donor can create a request using one fixed package.
- A created request appears in the donor's request history.
- Status changes are returned from the backend and rendered without client-generated state.
- Unapproved proof is never returned.
- Completed requests contain approved media and donor-safe impact.
- No operator identity, exact GPS, KYC, receipt image, or payout data appears in donor responses.
- English and Arabic content is returned correctly.

### Operator

- Only an approved feeder can load tasks.
- The operator sees only their own assignments.
- Accept/decline and working-state transitions are server validated.
- Acceptance deadline is returned as a real timestamp.
- Availability and daily capacity can be updated.
- The operator can upload allowed media and remove an accidental upload before submission.
- Proof submission records GPS, accuracy, impact values, receipt details, and media.
- Proof submission changes the task to `proof_submitted`, not `completed`.
- A rejected proof contains an operator-safe correction reason and can be resubmitted.
- Reviewer approval in CMS completes the request and creates donor notification and payout eligibility.
- Payout history is read-only in the mobile app.

### Reliability

- List endpoints are paginated.
- Mutating calls reject invalid state transitions consistently.
- Duplicate requests do not create duplicate state transitions or proof records.
- Signed media URLs load on real devices.
- Network, validation, `403`, and `409` responses contain stable machine-readable codes.
- All workflow actions appear in the request audit/event history.

## 15. Backend delivery checklist

### Confirm existing deployment

- [ ] Public programmes, programme details, highlights, and packages.
- [ ] Donor request creation, list, detail, and cancellation.
- [ ] Donor-safe approved proof.
- [ ] Feeder application, profile, and profile update.
- [ ] Feeder task list, accept, decline, status, media, and proof submission.
- [ ] Proof rejection/resubmission behavior.
- [ ] Feeder payout list.
- [ ] Donor and operator notifications.
- [ ] Role isolation and feeder ownership checks.

### New or changed work

- [ ] Unified Charity login and session-context response for automatic routing.
- [ ] Explicit `app_mode` and normalized `roles`/`account_type` fields.
- [ ] Operator dashboard summary endpoint.
- [ ] Operator task-detail endpoint with `allowed_actions`.
- [ ] Optional approved feeding location for the map, or explicit `null`.
- [ ] Optional operational purchase requirements for the design checklist.
- [ ] Proof rejection reason and previous-proof metadata in operator task responses.
- [ ] Media record response and delete-before-submit endpoint.
- [ ] Updated task returned after every operator action.
- [ ] Shared donor/operator notification contract and Charity-app deep links.
- [ ] Stable machine-readable authorization, state, validation, media, and GPS error codes.

## 16. Definition of backend-ready for mobile integration

The backend is ready for the Zoovana Charity app when:

1. A donor and approved feeder can use the same login form and receive an unambiguous `app_mode`.
2. The full donor and operator screen-to-API mapping above can run against a device-reachable staging environment.
3. The operator can submit proof but cannot complete their own task.
4. CMS proof approval completes the request and makes the approved proof visible to the correct donor.
5. Privacy tests prove that donor and operator responses contain only their permitted data.
6. The backend team provides an updated OpenAPI/Postman collection with request/response examples for every endpoint in this document.

