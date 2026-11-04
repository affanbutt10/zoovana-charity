# Zoovana Charity — What We Still Need From Backend

**Updated 2 Nov 2026**

Thank you, the full flow is live. The logins, the Makkah and Madinah programmes, automatic assignment, SAR on tasks and payouts, UTC times, the public test payment link and the `program` block in `GET /requests/my` all work with the app.

**Real payment (PayFast) is still not needed yet.**

---

## 1. Push notifications (Firebase)

You asked for our app IDs:

| Platform | ID |
|---|---|
| Android package | `com.bytes.zoovana_charity` |
| iOS bundle ID | `com.bytes.zoovanaCharity` |

Please register both in Firebase project `zoovanamp`, upload the APNs key, and send us:
- `google-services.json` (Android)
- `GoogleService-Info.plist` (iPhone)

---

## 2. Still open

1. **Images:** `image_url` on every programme and package. The app shows a placeholder until then.
2. **Urdu:** `*_ur` text for statuses, programmes, packages, zones and notifications. The app already reads these fields; until they arrive, Urdu users see the server text in English.
3. **Task programme name in Arabic:** `GET /feeder/tasks` sends `program_name` in English only. Please add `title_en` / `title_ar` to the task's `program` block, like `GET /feeders/me` has.
4. **CMS screens** for proof review and operator approval. Until then we use the admin API.
5. **Madinah operators:** none yet, so Madinah donations wait. Please approve at least one before launch.
6. **Security, before launch:**
   - Change the server root password that was shared in chat.
   - Reset the CMS demo account passwords.
   - Change the shared test-account password after the CTO review.
7. **Old demo proofs:** `GET /admin/proofs?review_status=pending` still lists demo proofs from September. Please clear them, so testers can find their own.
8. **Duplicate Makkah zones:** `GET /programs/{makkah_cats}/zones` returns 10 zones, with Al-Aziziyah and Al-Naseem twice (codes `aziziyah` / `al_aziziyah` and `naseem` / `al_naseem`). They look like two seed runs. New operators see both copies in the form. Please keep one set and deactivate the other.
9. **No zone on tasks:** every task has `zone: null`, so the operator only sees "Makkah" and doesn't know which area to feed. Should the request get a zone (from the operator's zones, or chosen by the donor)?

---

## Tested on 2 Nov 2026 (Android, live servers)

Both flows passed:
- **Donation to completion:** donor pays → automatic assignment → operator accepts, buys, feeds and uploads proof → staff reject → operator re-uploads → staff approve → donor sees "completed" with the photo. Notifications arrived on both sides at every step.
- **Become an operator:** form submitted → staff approve → the operator app opens.

We noticed:
- **GPS isn't checked against the city:** a proof sent from Pakistan was accepted. That's handy for testing, but should operators have to be in Makkah or Madinah before launch?
- **Payout:** 45 SAR was eligible for a 12 SAR fee. We think that's the fee plus the 33 SAR food receipt. Please confirm.
- **Test accounts:** `charity.operator.new@` is now an approved operator (set off duty). Please create a fresh "new operator" account when we need to test the form again.

---

## Questions (answer when you can)

1. After the accept time runs out, is the Accept button removed, or does accepting only fail with an error?
2. Is there a way for an operator to change their IBAN after approval?
3. Do push messages include a title and body (needed for iPhone), and always a `deep_link`?
4. Password reset: how many digits is the code, and how long is it valid?
5. Videos over 25 MB upload straight to Cloudinary; smaller files go through the API. Is that OK?
