# Zoovana Charity — Scope Cleanup Report

Target scope, from [CHARITY_BACKEND_REQUIREMENTS.md §2–3](CHARITY_BACKEND_REQUIREMENTS.md):

- **Donor:** feeding programmes (city → animal) → fixed package → donor details → request → status / proof / impact history, notifications, profile.
- **Operator (feeder):** dashboard + On Duty, assigned tasks, accept/decline, buy → feed → submit proof, proof correction, read-only payouts, profile/KYC status.
- **Excluded:** pets, pet-care services and bookings, adoption, shelter item donations, marketplace/cart/delivery, any role switch. Card/Apple Pay/Google Pay entry is **deferred**.

Legend: **KEEP** · **KEEP + FIX** (in scope, but wrong copy/data) · **COMMENT OUT**

---

## 1. Module / screen inventory

| Module | Screen / route | Verdict | Notes |
|---|---|---|---|
| splash | `SplashScreen` `/splash` | KEEP | |
| onboarding | `OnboardingScreen` `/onboarding` | KEEP + FIX | All 3 pages are pet-care copy ("Track your pet's health…", "Shop trusted brands, book pet care services"). Rewrite for feeding/charity. [onboarding_screen.dart:46-68](../lib/app/modules/onboarding/screens/onboarding_screen.dart#L46-L68) |
| auth | `AuthLandingScreen`, `LoginScreen`, `RecoverPasswordScreen` | KEEP | Guest button "You're Guest donate now" — decide; the backend doc assumes an authenticated donor. |
| auth | `SignupScreen` | KEEP (donor only) | |
| auth | `SetupProfileScreen` | KEEP + FIX | After "Next" it pushes `AppRoutes.addPet` — must go to `AppRoutes.home` instead. [setup_profile_screen.dart:66](../lib/app/modules/auth/screens/setup_profile_screen.dart#L66) |
| home | `CustomerShellScreen` `/home` | KEEP + FIX | See §2 and §3 |
| pets | `AddPetScreen` `/pets/add`, `PetDetailsScreen` `/pets/details` | **COMMENT OUT** | Whole module ([pet_screens.dart](../lib/app/modules/pets/screens/pet_screens.dart)) |
| services | `ServicesScreen` `/services`, `ServiceDetailsScreen`, `BookServiceScreen` | **COMMENT OUT** | Whole module ([service_screens.dart](../lib/app/modules/services/screens/service_screens.dart)) |
| adoption | `AdoptionBrowseScreen`, `AdoptionShelterScreen`, `AdoptionPetDetailsScreen`, `AdoptionApplicationScreen` | **COMMENT OUT** | Whole module ([adoption_screens.dart](../lib/app/modules/adoption/screens/adoption_screens.dart)) |
| charity | `CharityHomeScreen` `/charity` ("Impact Charity hub") | **COMMENT OUT** | Only offers "Support and donation" vs "Adopt Animals". With adoption gone it's a one-option screen. |
| charity | `CharitySupportScreen` `/charity/support` | **COMMENT OUT** | Only offers "Street Animals" vs "Shelters and Campaigns". With shelters gone it's a one-option screen. |
| charity | `CharityLocationScreen` `/charity/location` | KEEP | Becomes the **entry point** of the donate flow (centre button + home CTA go here). Cities are hardcoded; the backend doc says derive them from `/programs`. |
| charity | `CharityAnimalScreen` `/charity/animal` | KEEP | |
| charity | `CharityCampaignScreen` `/charity/campaign` | KEEP + FIX | Remove the `isShelter` branches (categories, "Select Items for donation"). Doc: **one** package per request, but the screen uses quantities per item. |
| charity | `CharityCheckoutScreen` `/charity/checkout` | KEEP + FIX | Comment out `_PaymentStep` + card/Apple/Google Pay widgets (payment deferred) and `_ShelterReview`. Keep donor details/dedication + review + success. |
| charity | `ShelterHubScreen`, `SheltersScreen`, `ShelterCampaignsScreen`, `ShelterDetailsScreen`, `ShelterInfoScreen` | **COMMENT OUT** | Shelter donations are excluded ([shelter_screens.dart](../lib/app/modules/charity/screens/shelter_screens.dart)) |
| charity | `RatingsScreen` `/ratings` | **COMMENT OUT** | Shelter/provider reviews. It lives in shelter_screens.dart. |
| history | `DonationHistoryScreen` `/charity/history` | KEEP + FIX | This is "My charity requests". Needs a status per receipt (see §5). |
| notifications | `NotificationsScreen` | KEEP + FIX | Seed items are pet content ("140 gr dry food at 7:00", "New lab result uploaded", "Appointment booked"). [notifications_screen.dart:36-80](../lib/app/modules/notifications/screens/notifications_screen.dart#L36-L80) |
| account | `ProfileDetailsScreen` `/account/profile` | KEEP + FIX | Preference subtitles mention appointments and pet-care tips. |
| account | `AccountCollectionScreen` → **My Orders** `/account/orders` | KEEP (or drop) | It just wraps donation history; could point straight to `/charity/history`. |
| account | `AccountCollectionScreen` → My Address, My Appointments, My Payments, Favorites | **COMMENT OUT** | Routes `/account/addresses`, `/account/appointments`, `/account/payments`, `/account/favorites` and the `_addresses/_appointments/_payments/_favorites` sections + sheets in [account_screens.dart](../lib/app/modules/account/screens/account_screens.dart) |
| provider | `ProviderShellScreen` `/provider`, `ProviderJobsScreen`, `ProviderJobDetailsScreen` | KEEP + FIX | This is the operator app. See §4. |

### Data layer

| File | Verdict |
|---|---|
| `PetRepository`, `pet_profile.dart` | COMMENT OUT (and its `Get.put` in [app_bootstrap.dart:21](../lib/app/core/bootstrap/app_bootstrap.dart#L21)) |
| `AppointmentRepository`, `pet_appointment.dart` | COMMENT OUT ([app_bootstrap.dart:28-31](../lib/app/core/bootstrap/app_bootstrap.dart#L28-L31)) |
| `CommunityRepository` | Partial: adoption applications are out; `providerJobCompleted` is used by the operator dashboard |
| `AccountRepository` | Addresses, payment methods and favorites are all out of scope |
| `CharityRepository`, `SeedCharityDataSource` | KEEP; remove the `contains('shelter')` package branch and `CampaignKind.shelter` |

---

## 2. Donor shell: current tabs and nav

[app_bottom_nav.dart:207-214](../lib/app/shared/widgets/app_bottom_nav.dart#L207-L214) — `CustomerNav.destinations`:

| Tab | Verdict |
|---|---|
| Home | KEEP (rebuild contents, see §3) |
| My Pets | **COMMENT OUT** (`_MyPetsTab`, `_PetStat`, `_PetProfileCard`) |
| Services | **COMMENT OUT** (it is not even a tab — it pushes `/services`) |
| Profile | KEEP + FIX |
| Centre siren button (`onCenterTap`) | KEEP, but point it at `/charity/location` instead of `/charity` |

**Proposed nav** (the centre button splits the list in half, so 4 destinations keep the current symmetric layout):

```
Home · My Requests · [ Donate ] · Notifications · Profile
```

Things in [customer_shell_screen.dart](../lib/app/modules/home/screens/customer_shell_screen.dart) to update with the nav:
- `CustomerTab` constants and `CustomerTab.open` special-case for services (lines 23-37)
- `_select` services special-case (lines 87-93)
- `IndexedStack(index: _index == CustomerTab.profile ? 2 : _index)` hack (line 100)
- `_loadPets`, `_addPet`, `_openPet`, `_pets` state (lines 48, 60-80)
- `CharityNavBar` in [charity_setup_screens.dart:14-28](../lib/app/modules/charity/screens/charity_setup_screens.dart#L14-L28) reuses the same destinations

### Profile tab (donor)

[customer_shell_screen.dart:1061-1468](../lib/app/modules/home/screens/customer_shell_screen.dart#L1061-L1468)

| Item | Verdict |
|---|---|
| Header subtitle "Manage your pets, activity & settings" | FIX copy |
| Role badge "Pet Parent" (line 1352) | FIX → "Donor" / "Supporter" |
| Stats: My Pets / Donations / Appointments (lines 1393-1420) | Replace with **Requests · Meals funded · Completed** |
| My Orders | KEEP → rename "My Requests" |
| My Address | COMMENT OUT |
| My Appointment | COMMENT OUT |
| Favorites | COMMENT OUT |
| My Profile | KEEP |
| My Payment | COMMENT OUT (payment deferred) |
| Notifications | KEEP |
| **Switch to Provider Mode** (lines 1137-1143) | **COMMENT OUT** — doc §3 forbids a role switch; role comes from login |
| Sign out | KEEP |

---

## 3. Donor Home tab: section by section

Current `_CustomerHome.build` ([customer_shell_screen.dart:194-308](../lib/app/modules/home/screens/customer_shell_screen.dart#L194-L308)):

| Lines | Section | Verdict | Widget classes to comment out |
|---|---|---|---|
| 200-207 | Header "Hi Ahmad!" / "Syria-Damascus Baghdad street" + Charity + Bell buttons | KEEP + FIX | Use the session name; drop the street address; the Charity heart button is redundant once Home *is* charity |
| 216-237 | **My Pets** avatars + "Add a pet" | COMMENT OUT | `_AvatarItem`, `_PetAvatar`, `_AddPet` (336-397) |
| 239-247 | **Quick Services for you** grid | COMMENT OUT | `_ServiceGrid` (399-453) |
| 249-255 | Donate banner / "Cases you donate to it" | KEEP + FIX | `_DonateBanner` body says "Order your free paw collar today to track the movements of your pet" (line 489) — wrong copy. `_DonationCases` hardcodes the "Active" badge (line 597). |
| 257-268 | **Reminders** (Veterinary Dentist) | COMMENT OUT | `_Reminders` (635-698) |
| 270 | **Today's Offer** / View Plan | COMMENT OUT | `_TodaysOffer`, `_OfferCurvesPainter` (700-845) |
| 272-299 | **Vet's Daily Advice** + promo cards | COMMENT OUT | `_showAdvice` (310-332), `PromoCard` usage |

### Proposed Home tab (donor), built from data that already exists

1. **Header**: "Assalamu alaikum, {name}" + notification bell. Optional subtitle: "Feeding street animals in Makkah & Madinah".
2. **Primary CTA card**: reuse `_DonateBanner` with new copy ("Feed street animals today — your package becomes a verified feeding round"), button → `/charity/location`.
3. **Impact summary strip** (3 stat tiles), computed from `CharityRepository.getDonationHistory()`:
   - Requests made (`receipts.length`)
   - Total given (sum of `amount`)
   - Meals funded (from package `impact` / later `meal_count`)
4. **Active requests**: reuse `_DonationCases` horizontally, but show the real status ("Finding an operator", "Feeding in progress", "Proof under review", "Completed" — the donor mapping in doc §7.4) instead of the hardcoded "Active". "See all" → `/charity/history`.
5. **Feeding programmes**: one card per campaign from `CharityRepository.getCampaigns()` (Feed Cats in Makkah · Feed Birds in Al-Madinah · Feed Cats in Al-Madinah) with `supporters` count; tap → `/charity/campaign` with that campaign, skipping the city/animal pickers.
6. **Verified impact / Recent feedings**: a placeholder for `GET /programs/{id}/highlights` (approved, anonymised proof: zone, meals, animals fed, photo). Ship it as an empty state until the backend is ready.
7. **How it works** (static, replaces Vet's Advice): 1) Choose a package → 2) A local operator buys food and feeds the animals → 3) You receive verified photo proof.

When there are no donations, sections 3-4 collapse and the CTA (2) is the first thing on the page.

---

## 4. Operator shell (provider module)

[provider_screens.dart](../lib/app/modules/provider/screens/provider_screens.dart)

| Item | Verdict |
|---|---|
| Naming "Provider", "Orders", "Customer" everywhere | FIX → "Operator", "Tasks" |
| Dashboard header "Hi Ahmad!" / "Makkah zone" (137-141) | FIX → session name + assigned zone |
| Overview "New Orders / Active Orders / Completed" (164-191) | KEEP → "New / Active / Completed tasks". Add an **Eligible payout** tile (`eligible_payout_amount` in doc §8.2). |
| On Duty switch (204-209) | KEEP (maps to `PATCH /feeders/me is_available`) |
| Filter pills with hardcoded counts `'All ( 16)', 'Active (1)', 'Done (24)'` (215) | FIX: compute counts |
| `_JobStatus` buying / onTheWay / feeding / completed / canceled (19-24) | FIX → match backend: assigned, accepted, purchasing, feeding, proof_submitted, proof_rejected, completed |
| Job details steps: Buy Items → Location → Feeding → Review → "Complete the job" (663, 827) | KEEP flow; FIX final action → "**Submit proof**" (doc: operator never marks completed); result screen "Job Completed" → "Proof submitted — under review" |
| "Accept in 02:23" (717) | FIX later → `accept_deadline_at` |
| Jobs search matches `'... ahmad Bahsas'` (365) | Check: tasks must not expose donor names |
| Profile → Jobs History | KEEP |
| Profile → **Customer Reviews** / Rating stat | COMMENT OUT (no ratings in scope) |
| Profile → **Service Areas** (opens My Address) | COMMENT OUT, or later a read-only zone view |
| Profile → **Payout Methods** (opens card/payment screen) | COMMENT OUT → replace later with a read-only **Payouts** list (doc §8.9) |
| Profile → Provider Profile | KEEP → "Operator Profile"; add verification status |
| Profile → **Switch to Customer Mode** (622-628) | **COMMENT OUT** |
| Profile → Sign out | KEEP |

**Proposed operator Home tab:** greeting + On Duty switch at the top → stat tiles (New · Active · Completed · Eligible payout) → "Needs your action" (new tasks with an accept countdown, rejected proofs to resubmit) → "In progress" tasks. Rejected-proof tasks should sit at the top with the rejection reason.

---

## 5. Gaps worth noting (not commenting-out work)

- `DonationReceipt` has no `status` field, so neither Home nor History can show request progress. Add `status` (+ `expectedCompletionAt`, `hasProof`) before building the Home "Active requests" section.
- Splash routes logged-in users to `/home` only; there is no operator routing from the login result yet (doc §3).
- `CharityCampaign.kind` / `CampaignKind.shelter` and the shelter packages in `SeedCharityDataSource` become dead once shelters are out.

---

## 6. How to comment out safely (Dart compiles everything that's imported)

Do each feature as one unit, or the build breaks:

1. **Routes**: comment the `GetPage` entries in [app_pages.dart](../lib/app/routes/app_pages.dart), their imports at the top, and the constants in [app_routes.dart](../lib/app/routes/app_routes.dart).
2. **Call sites**: grep for every `AppRoutes.<name>` you removed. Current hits:
   - `addPet` / `petDetails`: customer_shell, setup_profile_screen
   - `services` / `serviceDetails` / `bookService`: customer_shell (tabs, `_ServiceGrid`, `_TodaysOffer`)
   - `adoption*`: charity_home_screen, shelter_screens, account_screens (favorites)
   - `shelterHub` / `shelters` / `shelterDetails` / `shelterInfo` / `ratings`: charity_setup_screens, shelter_screens, account_screens, provider profile menu
   - `appointments` / `addresses` / `payments` / `favorites`: customer_shell (home + profile menu), provider profile menu
   - `charity` / `charitySupport`: customer_shell `_openCharity`, `CharityNavBar`, account_screens "Donate now", checkout "Back To Charity"
3. **Bootstrap**: remove the `Get.put`s for removed repositories only after no screen calls `Get.find` on them (`ProfileMenu` calls `AppointmentRepository`).
4. **Tests**: most of the suite mentions pets, services, adoption, shelters or appointments: `expanded_flows_test`, `remaining_flows_test`, `route_smoke_test`, `widget_test`, `charity_repository_test`, `splash_startup_test`, `onboarding_motion_test`, plus the goldens. Expect failures until you update them.
5. Leave the asset files alone for now; unused assets only cost bundle size.

---

## 7. Applied (2026-10-29)

Done:
- Donor nav is now `Home · Requests · [Donate] · Impact · Profile` (the Impact tab is the doc's "Verified impact" screen); the notification bell stays in the header.
- New Home tab: donate banner, recent requests with status, feeding programme cards (city + animal artwork), how it works. Impact stats live on the Impact tab and Profile.
- Profile (donor and operator) is one compact menu card and fits a 393×853 screen without scrolling.
- New My Requests tab; `DonationReceipt` carries a backend `status` (donor labels from §7.4).
- Pets, services, adoption, shelters, ratings, the charity hub/support pickers, and the addresses/appointments/payments/favorites routes are commented out in `AppPages`. Their screen files are untouched and their `AppRoutes` constants are marked `// unregistered`.
- Both "Switch to … Mode" items, donor My Address/My Appointment/Favorites/My Payment, and operator Customer Reviews/Service Areas/Payout Methods/Rating are commented out.
- Setup profile goes to Home instead of pet setup; checkout success opens the Requests tab.
- Tests: out-of-scope tests are `skip: true`; `customer_home.png` golden re-baselined.

Still open: onboarding and notification copy (pet content), the payment step in checkout, operator naming/statuses/"Submit proof" (§4), the guest entry, and real request status from the API.
