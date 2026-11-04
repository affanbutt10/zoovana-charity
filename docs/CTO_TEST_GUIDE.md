# Zoovana Charity: how to test the donor and operator flows

**2 Nov 2026.** The app runs on the live servers. Payment is a **test page**, so no real money moves.

**Install:** the Android APK we send you (`app-release.apk`). You may need to allow "install from unknown sources".

## Your logins

The operator and staff accounts share one password; we send it to you separately.

| Use it for | Email |
|---|---|
| **Donor** | `charity.cto.donor@zoovana.com` (own password, sent separately), or sign up in the app with any email |
| **Operator** (approved, Makkah cats and birds) | `charity.operator.cto@zoovana.com` |
| **New operator** (for the "become an operator" form) | `charity.operator.new2@zoovana.com` |
| **Staff** (approve proof and operators) | `charity.cms.test@zoovana.com`, through the API below. The CMS has no screens for this yet. |

One phone works: sign out and sign in as the other account. Two phones are easier.

## Flow 1: donation to proof

1. **Donor:** Home → **Makkah** → **Cats** → pick a package → pay on the test page → back in the app the request shows **"Finding a local operator"** or **"Assigned"**.
2. **Operator:** the new task appears under **Tasks** (with a notification in the bell). Open it → **Accept** → **Buying food** → **Feeding**.
   - The donor's request follows each step.
   - The task shows the food budget and your fee in **SAR**.
3. **Operator:** add photos → **Submit proof**. The donor sees **"Proof is being reviewed"**.
   - The phone asks for location the first time. Allow it, or the proof can't be sent.
   - Testing from Pakistan is fine; the location isn't checked against Makkah yet.
4. **Staff:** reject the proof once, then approve it (calls below).
   - After the reject, the operator sees the reason and uploads again.
   - After the approve, the donor sees **Completed** with the photos.
5. **Operator:** **Payouts** shows the amount in SAR: the fee plus the food receipt amount.

**Note:** donations go to whichever of the two Makkah test operators has fewer open tasks. If your task doesn't appear, check with us, or ask the other operator to decline it. Use **Makkah**; Madinah has no operators yet.

## Flow 2: become an operator

1. Sign in as `charity.operator.new2@zoovana.com`. The app opens the application form.
2. Pick **Feed the cats of Makkah** and **all its zones**, add ID photos and bank details (any test IBAN starting with `SA`), and submit. The app shows **"Under review"**.
3. **Staff:** approve the application (call below).
4. Tap **Check again** on the "Under review" screen: the operator app opens.

## Flow 3: languages

**Profile → Language → العربية or اردو.** The app switches right to left.
- Arabic: the server text (programmes, packages, statuses) is in Arabic too.
- Urdu: the app text is in Urdu, but the server text stays in English for now. The backend hasn't added Urdu yet.

## Staff steps (API)

```bash
AUTH=https://api.auth.zoovana.net/api/v1
F=https://api.market.zoovana.net/api/v1/feeding

# Sign in as staff and keep the token
T=$(curl -s -X POST $AUTH/charity/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"charity.cms.test@zoovana.com","password":"<password>"}' \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["data"]["access_token"])')

# Proofs waiting for review (copy the "id" of yours; check request_id / submitted_at)
curl -s "$F/admin/proofs?review_status=pending" -H "Authorization: Bearer $T"

# Reject: the same operator uploads again
curl -s -X POST $F/admin/proofs/<proof_id>/reject -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' -d '{"reason_feeder":"Please show the food bowl","action":"retry"}'

# Approve
curl -s -X POST $F/admin/proofs/<proof_id>/approve -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' -d '{}'

# Operator applications waiting, then approve one
curl -s "$F/admin/feeders?status=pending_review" -H "Authorization: Bearer $T"
curl -s -X POST $F/admin/feeders/<feeder_id>/review -H "Authorization: Bearer $T" \
  -H 'Content-Type: application/json' -d '{"decision":"approved"}'
```

The pending proof list may also hold old demo proofs from September, so pick the one with today's `submitted_at`.

## Known gaps (not bugs in the app)

- **Push notifications:** they don't arrive yet while the app is closed, because the Firebase setup is still pending. The **bell** inside the app shows every notification.
- **Pictures:** programmes and packages show placeholder photos until the backend adds images.
- **Payment:** test page only; PayFast comes later.
