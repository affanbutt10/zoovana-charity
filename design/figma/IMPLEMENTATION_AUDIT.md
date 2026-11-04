# Zoovana Figma implementation audit

## Source of truth

- Reference frames: `design/figma/frames` — 60 raster frames.
- Exported artwork: `design/figma/figma-assets` — 251 SVG assets.
- Target viewport: 393 px wide. Most frames are 852–853 px high; taller files are scroll captures rather than separate device sizes.
- The raster frames are the visual authority. Existing Flutter behavior should be preserved unless a frame clearly specifies a different state or navigation result.

## Global design language

- Primary teal: approximately `#00A7A7`.
- Accent coral: approximately `#F15C61`.
- Main surfaces are white or very light grey, with large rounded sections and cards.
- Splash and welcome screens use the pale teal repeating animal pattern.
- Teal headers use the same animal pattern at low contrast.
- Typography is condensed throughout the frames. The project currently has no bundled font, so exact text width and line wrapping cannot be achieved until the matching font is bundled and applied globally.
- Most buttons are 52–56 px high with fully rounded ends.
- Customer navigation has five destinations and a raised coral center action. Provider navigation has three destinations.
- The system status bar must switch between dark icons on light screens and light icons on teal headers.

## Frame-to-screen map

### 1. Startup, authentication, and onboarding

| Reference frame | Intended Flutter destination/state | Audit result |
| --- | --- | --- |
| `Splashcreen.jpg` | `AppRoutes.splash` | Structure is implemented; verify exact logo size, vertical centering, typography, and native launch transition. |
| `login.jpg` | `AppRoutes.auth` / welcome landing | Structure is implemented; verify photo grid crops, button geometry, and typography. |
| `Login-1.jpg` | `AppRoutes.signup` | The filename is misleading: this is the signup form, not login. Existing form needs exact sheet height, fields, dividers, and footer copy. |
| `Recover Password.jpg` | `AppRoutes.recoverPassword`, recovery entry | Needs exact hero/sheet geometry and both email/phone recovery controls. |
| `Recover Password-1.jpg` | Recovery route, OTP state | Must remain a state in the recovery flow rather than a duplicate route. |
| `Recover Password-2.jpg` | Recovery route, new-password state | Must remain a state in the recovery flow and match requirements text and bottom CTA. |
| `Onboarding 1.jpg` | `AppRoutes.onboarding`, page 1 | Existing content is close; logo medallion currently uses a generic paw and must use the Zoovana mark. |
| `Onboarding 2.jpg` | Onboarding page 2 | Match image crop, panel curve, indicator, and button placement. |
| `Onboarding 3.jpg` | Onboarding page 3 | Match final image crop and CTA state. |

### 2. Customer home and profile shell

| Reference frame | Intended Flutter destination/state | Audit result |
| --- | --- | --- |
| `Homepage-2.jpg` | `AppRoutes.home`, customer home long capture | Main customer-home baseline. |
| `Homepage-3.jpg` | Customer home viewport/state | Alternate viewport/content state, not a separate route. |
| `Homepage-4.jpg` | Customer home long capture | Uses the cutout quick-service artwork already present in the project; treat this service-card treatment as authoritative. |
| `Homepage-5.jpg` | Customer home viewport/state | Alternate scroll/content state. |
| `Homepage-6.jpg` | Customer home long capture | Alternate dataset/state for donation and content sections. |
| `Homepage-7.jpg` | Customer home viewport/state | Alternate scroll/content state. |
| `Profile Page.jpg` | Profile tab inside the customer shell | Current route/shell must match the menu rows, counts, dividers, and fixed bottom navigation. |

Required shared sections are the patterned header, brand mark, greeting/location, pet selector, quick services, donation content, reminders, offers, advice cards, and five-item bottom navigation.

### 3. Provider dashboard and jobs

| Reference frame | Intended Flutter destination/state | Audit result |
| --- | --- | --- |
| `Homepage.jpg` | Provider dashboard / new orders | No clear one-to-one top-level route currently exists; this must be added or selected by user role. |
| `Homepage-1.jpg` | Provider dashboard / alternate tab or scroll state | Same provider shell with order-state variation. |
| `Jobs Page.jpg` | `AppRoutes.providerJobs` | Match history tabs, job cards, status chips, and provider bottom navigation. |
| `Job Details.jpg` | `AppRoutes.providerJobDetails`, incoming order | Match map, customer summary, item list, notes, total, and action area. |
| `Job Details-1.jpg` | Provider job step 1: buy items | Stateful job workflow. |
| `Job Details-2.jpg` | Provider job step 2: location | Stateful job workflow. |
| `Job Details-3.jpg` | Provider job step 3: feeding proof | Stateful job workflow, including media and notes. |
| `Job Details-4.jpg` | Provider job step 4: review | Stateful job workflow and finish action. |
| `Charity.jpg` | Provider job accepted result | Despite the filename, this belongs to the provider job flow. |
| `Charity-1.jpg` | Provider job completed result | Despite the filename, this belongs to the provider job flow. |

### 4. Charity support flow

| Reference frame | Intended Flutter destination/state | Audit result |
| --- | --- | --- |
| `Charity-2.jpg` | `AppRoutes.charity`, impact hub | Authoritative charity landing layout. |
| `Charity-3.jpg` | Impact hub duplicate/state | Visually duplicates the same landing composition. |
| `Charity-4.jpg` | `AppRoutes.charitySupport`, support categories | Category-card state. |
| `Charity-5.jpg` | Support categories duplicate/state | Visually duplicates the category composition. |
| `Charity-6.jpg` | `AppRoutes.charityLocation` | Makkah/Madina location selection. |
| `Charity-10.jpg` | `AppRoutes.charityAnimal` | Animal selection using large cutout cards. |
| `Charity-11.jpg` | `AppRoutes.campaign`, step 1 | Food-package selection. |
| `Charity-12.jpg` | `AppRoutes.checkout`, step 2 | Payment method and donor details. |
| `Charity-13.jpg` | Checkout step 2 duplicate/scroll state | Use with `Charity-12.jpg` to validate full content. |
| `Charity-14.jpg` | Checkout step 3 | Review details. |
| `Charity-15.jpg` | Donation success | Authoritative success state. |
| `Charity-16.jpg` | Clipped/corrupt success export | Do not use for geometry; use `Charity-15.jpg`. |

### 5. Shelter discovery and donation

| Reference frame | Intended Flutter destination/state | Audit result |
| --- | --- | --- |
| `Charity-7.jpg` | Shelter-donation hub | Banner, shelter chips, and active campaign card. |
| `Charity-8.jpg` | `AppRoutes.shelters` | Shelter list. |
| `Charity-9.jpg` | `AppRoutes.history` or campaign listing state | Campaign list; route ownership needs consolidation with the charity shell. |
| `Shelter Details.jpg` | `AppRoutes.shelterDetails` | Shelter profile and animals tab. |
| `Shelter Details-1.jpg` | `AppRoutes.shelterInfo` | Shelter information. |
| `Shelter Details-2.jpg` | `AppRoutes.ratings` | Shelter ratings and reviews. |
| `Shelter Details-3.jpg` | Shelter donation step 1 | Select donation items. |
| `Shelter Details-4.jpg` | Shelter donation step 2 | Payment details. |
| `Shelter Details-5.jpg` | Shelter donation step 3 | Review and submit. |

### 6. Marketplace and commerce

| Reference frame | Intended Flutter destination/state | Audit result |
| --- | --- | --- |
| `Marketplcae.jpg` | Marketplace tab/home | Long authoritative marketplace capture; filename typo is retained in the export. |
| `Food.jpg` | `AppRoutes.marketCategories` | Product categories. |
| `Food-1.jpg` | `AppRoutes.marketCatalog` | Standard product catalog. |
| `Food-2.jpg` | Market catalog, offers state | Promotional banner and discounted product state. |
| `Stores.jpg` | `AppRoutes.stores` | Store listing. |
| `Store Details.jpg` | `AppRoutes.storeDetails` | Store profile and products. |
| `Store Details-1.jpg` | `AppRoutes.storeInfo` | Store information. |
| `Store Details-2.jpg` | `AppRoutes.ratings` with store context | Store ratings. |
| `Store Details-3.jpg` | Store product catalog | Full catalog state under the selected store. |
| `Product Details.jpg` | `AppRoutes.productDetails` | Standard product details. |
| `Product Details-1.jpg` | Product details, discounted variant | State variant, not a separate route. |
| `Cart page.jpg` | `AppRoutes.cart` | Cart rows, quantity controls, summary, and CTA. |
| `Checkout.jpg` | `AppRoutes.marketCheckout` | Address step shown in Figma; later steps must follow the same visual system where no frame exists. |

## Current implementation gaps

1. **Typography:** no project font is declared. The current Material typography produces visibly wider headings and different line breaks than the frames.
2. **Shared shell consistency:** app bars, patterned headers, safe-area handling, and bottom navigation are implemented separately and drift in spacing and icon treatment.
3. **Icon fidelity:** several screens substitute generic Material icons for exported Figma artwork, including the onboarding brand medallion.
4. **Provider entry point:** the provider dashboard frames do not currently have an unambiguous route selected from authenticated role state.
5. **Screen-state modeling:** OTP, password reset, product offers, donation steps, provider job steps, and success screens should be states within their flows, not disconnected visual copies.
6. **Scrollable-frame interpretation:** tall frames must be implemented as scrollable content beneath fixed or sticky navigation; their pixel height must not be treated as a device height.
7. **Visual regression coverage:** current widget tests verify behavior but do not provide a 393×852 reference comparison for all 60 states.
8. **Unspecified screens:** pets, adoption, account details, services, appointments, payments, favorites, and addresses exist in code but have no matching frame in this export. They can be made design-system-consistent, but cannot be claimed pixel-exact without references.

## Implementation order

### Phase 0 — fidelity foundation

- Bundle and apply the matching condensed font.
- Centralize exact colors, radii, text styles, elevation, spacing, and button dimensions.
- Build reusable patterned light/teal backgrounds, app headers, section titles, cards, and both bottom-navigation variants.
- Establish deterministic 393×852 screenshot capture with animations and network data disabled.

### Phase 1 — startup and authentication

- Finish splash/native launch alignment.
- Match welcome, signup, recovery, OTP, new-password, and all onboarding pages.
- Validate keyboard, small-screen scrolling, and back navigation without changing the reference resting state.

### Phase 2 — customer shell

- Match the shared customer header and navigation.
- Implement the authoritative customer-home composition and its alternate data states.
- Match the profile tab.

### Phase 3 — marketplace

- Marketplace home, categories, catalogs, stores, store details, product details, cart, and checkout.
- Reuse one product/store design system so state variants remain geometrically identical.

### Phase 4 — charity and shelters

- Impact hub, support selection, city/animal/package selection, payment, review, and success.
- Shelter hub, listings, details, information, ratings, and three-step donation flow.

### Phase 5 — provider flow

- Add the provider dashboard entry point.
- Match jobs/history, four job-detail steps, and accepted/completed results.

### Phase 6 — final visual QA

- Compare every state at 393×852 against its frame.
- Check long scroll captures section by section.
- Test narrower and wider phones for overflow while preserving the 393 px baseline.
- Run analyzer, widget tests, and Android/iOS release builds.

## Per-screen acceptance criteria

- Correct asset and crop, not a visually similar placeholder.
- Matching safe areas, section positions, widths, heights, radii, colors, and shadows.
- Matching text content, weight, line height, letter spacing, wrapping, and truncation.
- Matching selected/unselected icon and navigation states.
- Correct fixed-versus-scroll behavior.
- Functional interactions and state transitions.
- No overflow at the reference viewport or common smaller phone widths.
- Screenshot comparison completed before the screen is marked finished.
