# Donor UI verification

Verified on Oppo CPH2269, Android 12, physical screenshot size 720×1600.

## Actual device captures

- `oppo-home.png`: patterned greeting, active request/progress card, city programme cards, plus action.
- `oppo-requests.png`: compact photographic request list with actual backend status labels.
- `oppo-request-cards.png`: alternate large photographic cards and details action.
- `oppo-request-details.png`: older capture; not evidence of the latest detail redesign.
- `oppo-impact.png`: real account summary and no-approved-proof empty state.
- `oppo-profile.png`: compact account card and grouped settings.
- `oppo-notification-settings.png`: compact preference controls and honest local-only state.
- `oppo-packages-list.png`, `oppo-packages-grid.png`: earlier captures, before the latest quantity-control changes.

Source comparison uses the local Figma exports in the parent folder. Text, dates,
status lengths, money and counts differ from the sample screenshots because live
API values are retained. The signed-in account had no completed requests, so the
filled verified-feeding card was checked in a widget fixture rather than falsely
populated on the live account. No live request/payment mutation was performed.

## Automated checks

- `flutter analyze`: no issues.
- 25 targeted tests passed across `donor_responsive_test.dart`,
  `api_contract_test.dart`, `charity_repository_test.dart`, `route_smoke_test.dart`.
- Responsive checks cover widths 320, 393 and 600; normal and 1.5× text; RTL verified
  proof card; donor settings at 320 px with large text; reduced-motion custom loaders; list/card navigation callbacks.
- Existing Home golden baseline updated for the intentional redesign, then its
  normal comparison passed. Widget goldens use the test font and are layout
  regressions; actual visual inspection uses the Oppo screenshots.
- Existing shared/provider profile implementation was compared against HEAD and
  remains identical. Provider role routing and screens were not redesigned.
- Notification custom loading is explicitly donor-only; other roles retain their
  original loading indicator.

The generated asset manifest was rebuilt after extracting and naming artwork;
final installed assets loaded correctly. SDK constraint remains compatible with
the installed Dart 3.12.2. Oppo debug launch uses `--no-enable-impeller`.

## Backend-dependent differences

See `docs/USER_APP_DESIGN_BACKEND_GAPS.md`. This includes real cover/package images,
avatars, lifetime totals, location, notification synchronization, region/currency,
support tickets, approved legal content, multi-package quantities and payment
contracts. These features are not represented as successfully integrated.

## Latest feeding flow pass

The new build compiled and installed on Oppo. USB disconnected before the final
screenshot pass, so latest physical appearance is not yet verified. The four
`fixture-*.png` images capture synthetic payment/review/pending/completed layouts;
they are not device or live backend evidence. Test captures can omit icon glyphs
and asynchronously decoded artwork; use source assets/device for those checks.

The new feeding tests pass at 320/393/600 logical widths, including increased text
and RTL. `flutter analyze` is clean. Older `charity_flow_test.dart` and
`request_details_test.dart` still fail: they rely on the removed demo flow/cache
and old labels (`Food Packages`, `Request details`, `Verified proof`, `Progress`).
They are not counted as passing integration coverage. Current focused tests use
explicit fixtures and cover all redesigned detail sections and cart guards.
