# Premier PayFast — Payment Integration Plan

**For:** CTO / backend lead
**From:** Mobile team
**Last updated:** 30 Oct 2026

---

## 1. Summary

- The app launches in **Pakistan**. Donors pay in **PKR**.
- We use **Premier PayFast** ([premierpayfast.com](https://premierpayfast.com/)), a Pakistani payment gateway licensed by the State Bank of Pakistan.
- Donors can pay **any way they like**: card, JazzCash, Easypaisa, bank account or Raast.
- **Android:** the donor pays **inside the app**.
- **iPhone:** the donor pays **outside the app, in Safari**, then comes back to the app. Apple requires this for charity apps (see §3).
- The app never sees PayFast's secret keys. Only our backend talks to PayFast, and only the backend decides whether a payment succeeded.

---

## 2. How a donor pays

### 2.1 Steps both phones share

1. The donor chooses a city, an animal and a package.
2. They enter their name, email and phone, then tap **"Continue to secure payment"**.
3. The app creates the request (status: unpaid) and asks our backend for a **payment link**.
4. The donor pays on **PayFast's payment page**, choosing any method.
5. PayFast tells our backend the result. The backend double-checks with PayFast, then marks the request **paid**.
6. The donor is back in the app and sees **"Paid — finding a local feeder"**.

### 2.2 Android: inside the app

```
App ──▶ PayFast page opens inside the app ──▶ donor pays ──▶ page closes by itself ──▶ app shows "Paid"
```

The donor never leaves the app.

### 2.3 iPhone: outside the app, in Safari

```
App ──▶ Safari opens PayFast page ──▶ donor pays ──▶ "Payment received" page
    ──▶ donor taps "Back to Zoovana" ──▶ app opens on their request ──▶ shows "Paid"
```

If the donor doesn't tap "Back to Zoovana", nothing is lost:

- the payment is already recorded by our backend;
- the donor gets a **"Payment received"** push notification;
- the app refreshes the request the next time it opens.

### 2.4 If something goes wrong

| Situation | What the donor sees |
|---|---|
| Payment declined (wrong OTP, low balance, …) | "Payment failed" with the reason, and a **Try again** button. They can pick a different method. |
| Donor closes the page without paying | The request stays **unpaid**. A **Complete payment** button appears on it in My Requests. |
| Wallet or bank approval takes a while | "Confirming your payment…" in the app. If it takes longer than about a minute: "We'll notify you when it's confirmed." |

---

## 3. Why iPhone pays in Safari

Apple's App Store rules for charity apps:

- **Guideline 3.2.2(iv):** apps that raise money for charity *"must be free on the App Store and may only collect funds outside of the app, such as via Safari or SMS."*
- **Guideline 3.2.1(vi):** the only exception is an **Apple-approved nonprofit that offers Apple Pay**.

We can't use that exception:

- **Apple Pay isn't available in Pakistan.** It's not on [Apple's country list](https://support.apple.com/en-us/102775) (updated 27 Oct 2026).
- Apple's [nonprofit approval](https://developer.apple.com/apple-pay/nonprofits/) for non-US charities goes through Benevity, and doesn't say whether Pakistani organisations qualify.

So on iPhone the payment page **must open in Safari**, not inside the app. Opening it inside the app risks the app being rejected.

We should not try to describe donations as "buying a service" to get around this. The app is clearly a charity app, so Apple would apply the charity rule.

**Android:** Google Play allows charity donations through a payment provider such as PayFast. We need to declare it correctly in the Play Console. The CTO should confirm Zoovana qualifies under Google's donation policy.

> The guideline quotes above come from a summary of Apple's page, because it was too long to read in full. Check them on the [live guidelines page](https://developer.apple.com/app-store/review/guidelines/) before submitting. Apple makes the final decision during review.

---

## 4. Payment methods

PayFast supports all of these in PKR ([FAQs](https://premierpayfast.com/faqs/), [OneCheckout](https://premierpayfast.com/onecheckout/)):

| Method | How the donor approves |
|---|---|
| Debit or credit card (Visa, Mastercard, UnionPay, PayPak) | Card details, then a one-time code from their bank |
| Cards issued abroad (overseas Pakistanis) | Same as above. Their bank converts to PKR. |
| JazzCash, Easypaisa | Wallet number, then a code or PIN in their wallet app |
| Bank account (Bank Alfalah, JS Bank, Askari, Habib Metro, …) | Bank and account details, then a one-time code |
| Raast | Scan a QR or approve a request in their banking app |

**Not supported:** Apple Pay. It isn't offered by PayFast or available in Pakistan.

We use **PayFast's own payment page** (called OneCheckout), which shows every method in one place. Benefits:

- **All methods, no extra app screens.** New methods appear without an app update.
- **Card details never touch our servers.** We avoid the heavy card-security audit (PCI DSS) that handling card numbers ourselves would bring.

---

## 5. PayFast at a glance

| | |
|---|---|
| Company | Avanza Premier Payment Services (Pvt) Ltd, Pakistan |
| Licence | State Bank of Pakistan |
| Currency | PKR |
| Setup fee | **PKR 20,000**, one-time, non-refundable |
| Monthly or annual fee | None |
| Per-transaction fee | Not published. Ask PayFast. |
| Money reaches our bank | 2 working days after payment (T+2) |
| Refunds | Full or partial. The donor's bank takes 7–21 working days. |
| Sign-up time | 3–4 working days after documents |
| Requirement | Pakistani business with a valid **NTN**. NGOs, societies and trusts can apply. |
| Test environment | Available |
| Contact | +92 21 37133278 · WhatsApp +92 300 8231674 · [sign-up form](https://premierpayfast.com/signup/) |

**PayFast does not publish:**
- the hosted payment page's setup details;
- its test and live server addresses;
- webhook details;
- per-transaction fees.

These are the questions in §10.

---

## 6. Behind the scenes: backend work

### 6.1 The rules

1. **Only the backend talks to PayFast.** The app never holds `merchant_id`, `secured_key` or the signing key.
2. **Only PayFast's answer counts.** The backend marks a request paid only after asking PayFast for the transaction status, never because the app or a redirect says so.
3. **Every try is recorded.** Each payment attempt gets its own record, so donors can retry and support can investigate.

### 6.2 What the backend builds

| Piece | What it does |
|---|---|
| **Payment link** (`POST /requests/{id}/payment-intent`, already in the app's contract) | Creates a PayFast checkout for the request's PKR amount and returns the page link. Marks the request "payment pending". |
| **"Payment done" page** | Where PayFast sends the donor after paying. It checks the result with PayFast, updates the request, and shows a **"Back to Zoovana"** button. On Android the app closes the page itself. |
| **PayFast notifications** (webhook) | If PayFast offers them: receives the result directly, verifies it's really from PayFast, and ignores duplicates. |
| **Safety-net job** | Every few minutes, checks attempts still "pending" with PayFast. Wallet and Raast approvals can be slow, and some donors close the page early. Gives up after about 30 minutes. |
| **Refunds** | A button in the CMS for finance. Calls PayFast's refund API, marks the request refunded and notifies the donor. |
| **Notifications to the donor** | `payment_received` and `payment_failed` push notifications, which the app already supports. |

### 6.3 What to store per attempt

| Field | Example |
|---|---|
| Request | which feeding request |
| `basket_id` | `ZF-1042-2`: request reference plus attempt number, unique per try |
| Amount | `2500.00 PKR` |
| Method | card, JazzCash, Easypaisa, bank or Raast |
| PayFast transaction ID | from PayFast |
| Status | created, pending, succeeded, failed, expired, refunded |
| PayFast result code | e.g. `00` (success), `97` (low balance) |

**Never store or log** card numbers, CVV, one-time codes or wallet PINs.

### 6.4 Result codes

| PayFast code | Meaning | Request becomes |
|---|---|---|
| `00`, `79` | Success | **paid**, then "finding a feeder" |
| `001`, `002` | Pending or timeout | still pending, so check again |
| anything else | Failed (e.g. `97` low balance, `55` wrong OTP) | **payment failed**, and the donor can retry |

### 6.5 Security checklist

- PayFast keys go in a secret manager (e.g. AWS Secrets Manager or Vault), never in code or the app.
- Use separate **test** and **live** keys.
- Send the donor's real IP address to PayFast. PayFast requires it and uses it for fraud checks.
- Before marking a request paid, check that the amount PayFast reports matches the request.

**Estimate:** about **1–1.5 weeks** of backend work.

---

## 7. Mobile app work (our side)

| Task | Detail |
|---|---|
| Payment button | "Continue to secure payment" after the donor's details |
| Android checkout | PayFast page inside the app. Closes itself when payment finishes. Allows the JazzCash, Easypaisa or banking app to open for approval. |
| iPhone checkout | PayFast page opens in **Safari** |
| Return to app | The "Back to Zoovana" link opens the app straight on the request |
| "Confirming payment" screen | The app checks the request status every few seconds. It never decides success itself. |
| Failed or unpaid requests | "Try again" and "Complete payment" buttons |
| PKR display | Amounts shown in PKR (e.g. `PKR 2,500`). Leftover SAR test values switched to PKR. |

**Estimate:** about **4–6 working days**, once the backend payment link works in the test environment.

### What the app needs back from the payment-link endpoint

```json
{
  "success": true,
  "data": {
    "attempt_id": "uuid",
    "amount": "2500.00",
    "currency": "PKR",
    "client_payload": {
      "checkout_url": "https://…PayFast payment page…",
      "return_url": "https://zoovana.app/pay/done/{request_id}",
      "expires_at": "2026-11-01T12:30:00+05:00"
    }
  }
}
```

| Error | When |
|---|---|
| `409 invalid_state_transition` | Request already paid or cancelled |
| `503 payment_provider_unavailable` | PayFast is down |
| `429 rate_limited` | Too many attempts |

---

## 8. What I need from you (CTO)

### Decisions

- [ ] PKR price for each package, and the operator food budget and fee for each.
- [ ] Refund policy: who approves refunds, and in which cases.
- [ ] Confirm the store approach: iPhone pays in Safari, Android pays in the app.

### Sign up with PayFast

- [ ] Fill in the [sign-up form](https://premierpayfast.com/signup/). Choose "NGO, Society or Trust" if that's our legal form, and the product "Merchant Payment Gateway".
- [ ] Provide the **NTN** and the business documents PayFast asks for.
- [ ] Provide the Pakistani bank account that will receive the money.
- [ ] Put **privacy policy**, **refund policy** and **terms** pages on our website. PayFast and the app stores both check these.
- [ ] Pay the **PKR 20,000** setup fee and agree per-transaction fees.
- [ ] Ask PayFast to turn on **all methods**: cards, JazzCash, Easypaisa, bank accounts and Raast.

### From PayFast, for developers

- [ ] **Test** keys (`merchant_id`, `secured_key`, signing key) and the test server address.
- [ ] **Live** keys and server address, for launch day.
- [ ] Answers to the questions in §10.
- [ ] Test cards, wallet numbers and bank accounts.

### Infrastructure

- [ ] A backend developer for about 1–1.5 weeks.
- [ ] A secret manager for the PayFast keys.
- [ ] Public HTTPS addresses for the "payment done" page and PayFast notifications, on test and live.
- [ ] **Universal Links** for iPhone: a file called `apple-app-site-association` on our domain (e.g. `zoovana.app`). This lets "Back to Zoovana" open the app directly instead of showing a browser prompt. Android needs the equivalent `assetlinks.json` file.
- [ ] A fixed server IP address, if PayFast requires it.
- [ ] Alerts when payments fail often or stay pending.

### App store submission

- [ ] Keep the app **free** on the App Store.
- [ ] In the App Review notes, explain: *"Donations are collected outside the app in Safari via Premier PayFast, in line with Guideline 3.2.2(iv)."*
- [ ] Complete the Google Play payments and donations declaration.

---

## 9. Timeline

| Step | Who | Done when |
|---|---|---|
| 1. Sign up and KYC with PayFast | CTO / finance | Test keys received (about 3–4 working days after documents) |
| 2. Get answers to §10 | Backend | Payment page, notification and signing details in hand |
| 3. Set PKR prices | Backend and product | API returns `PKR` everywhere |
| 4. Build the backend (§6) | Backend | A test payment marks a request paid |
| 5. Build the app flow (§7) | Mobile | Test payments work on Android and iPhone |
| 6. Test every method | QA | For each method: success, wrong code, low balance, closed page, refund |
| 7. Go live | All | First real donation for each method appears correctly in PayFast's settlement report |

---

## 10. Questions to send to PayFast

1. **Payment page:** does OneCheckout give us a hosted payment page we can use from our own backend (not a Shopify or WooCommerce plugin)? Please send the setup details and how we set the success, failure and cancel return addresses.
2. **Server addresses:** what are the test and live API addresses?
3. **Notifications:** can PayFast notify our server when a payment finishes? What does the message look like, and how do we verify it came from you?
4. **Signing:** is the signing key the same as `secured_key` or a separate key? Hex or base64? Please send a worked example.
5. **Methods:** will cards, JazzCash, Easypaisa, bank accounts and Raast all show on one page?
6. **Wallets and Raast:** do they open the customer's app to approve? How long can they stay pending?
7. **Mobile:** do you have an app SDK, or is opening the payment page in a browser the recommended way? Any known issues on iPhone Safari or Android?
8. **Fees:** per-transaction fee for each method, plus refund and chargeback fees.
9. **Documents:** the full KYC checklist for our business type.
10. **Testing:** test cards, wallet numbers, bank accounts and codes for success and each failure.
11. **Limits:** minimum and maximum amount per payment and per day, for each method.
12. **Cards issued abroad:** are they charged in PKR, and are there extra fees?
13. **Network:** do you need our server IP addresses whitelisted?

---

## Appendix: PayFast API reference (for the backend developer)

From [premierpayfast.com/developers](https://premierpayfast.com/developers/) (API v2.3). The base URL is not published (question 2).

| Step | Endpoint | Notes |
|---|---|---|
| Get access token | `POST /token` | Form fields: `merchant_id`, `secured_key`, `grant_type=client_credentials`, `customer_ip`. Returns `token`, `refresh_token`, `expiry`. Send `Authorization: Bearer <token>` on every later call. Reuse the token until it expires. |
| Refresh token | `POST /refreshtoken` | |
| Check status | `GET /transaction/{transaction_id}` or `GET /transaction/basket_id/{basket_id}` | **The source of truth for every payment** |
| Refund | `POST /transaction/refund/{transaction_id}` | `txnamt`, `refund_reason` |
| List banks | `GET /list/banks` | |
| Direct charge (only if no hosted page) | `POST /customer/validate`, then `POST /transaction` | Means collecting payment details ourselves. Avoid it for cards. |
| Saved cards and recurring (later, for monthly giving) | `/user/instruments`, `/transaction/token`, `/transaction/tokenized`, `/transaction/recurring` | |

**Signing:** the listed fields are joined with `+` and signed with HMAC-SHA256 into `secured_hash`.
