# Zoovana

A complete local-first Flutter prototype based on the supplied Zoovana Figma
frames. It combines pet profiles, care services, adoption, verified charity contributions, shelters, provider jobs, account
management, and notifications in one responsive mobile application.

The app uses GetX navigation and route bindings, repository-backed local state,
shared design tokens, centralized bootstrapping, Dio-ready network
infrastructure, and persisted customer activity through SharedPreferences.

Implemented journeys include:

- onboarding, validated sign-in/sign-up, recovery, guest sessions, and sign-out;
- pet creation, editing, removal, details, and care timelines;
- service discovery, provider details, three-step booking, and appointments;
- street-animal and shelter donations (item selection with quantities,
  payment, review, and success) with persisted receipts;
- the shelter donation hub, shelter and campaign listings, shelter details,
  ratings, adoption discovery, favorites, and applications;
- the provider dashboard, job history, and the complete proof-of-feeding
  workflow;
- editable profile preferences, addresses, payment methods, favorites, and
  notifications.

See [docs/architecture.md](docs/architecture.md) for the folder map and feature
conventions.

## Run

```shell
flutter pub get
flutter run
```

# zoovana-charity
