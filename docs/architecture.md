# Zoovana Charity architecture

This project implements the complete Zoovana mobile design set as a local-first
Flutter application while retaining boundaries suitable for remote services.

## Layers

```text
lib/
├── apis/                     Shared HTTP client and endpoint names
└── app/
    ├── core/                 Bootstrap, config, errors, cache, design tokens
    ├── data/
    │   ├── datasources/      Local or remote data implementations
    │   ├── models/           Transport/domain data objects
    │   └── repositories/     Stable interface consumed by features
    ├── modules/              Feature-first UI, state, and route bindings
    ├── routes/               Route names and GetPage definitions
    └── shared/widgets/       Reusable application widgets
```

The preferred dependency direction is `screen -> controller/repository -> data
source`. Charity screens use route-scoped controllers; lightweight local-first
features use repositories registered by `AppBootstrap`. Screens never call Dio
directly.

## State management

GetX is used in a controller/binding style:

- A route binding constructs the controller and injects its repository.
- Each controller owns immutable feature state and calls `update()` after a
  transition.
- Screens use `GetBuilder` and render loading, error, empty, and content states.
- Route arguments carry typed models between the campaign and checkout flows.
- App-wide services are registered once in `AppBootstrap`; feature controllers
  are route-scoped.

Repositories persist sessions, pets, appointments, account collections,
favorites, adoption applications, provider job
completion, and donation history. Form controllers are owned and disposed by
their screens or route controllers.

## Data source strategy

`SeedCharityDataSource` and the local repositories make the current prototype
fully runnable. When the production API contract is ready, add remote data
sources that use `ApiClient` and change their registrations in `AppBootstrap`.
Routes, screens, models, and repository consumers can remain unchanged.

## Verification

Widget tests cover the primary customer, charity, provider, adoption, booking,
account, and session journeys. Golden tests protect the supplied
reference layouts, and a route smoke test renders every registered route at the
393 × 853 reference phone size to catch layout exceptions.

Runtime API configuration belongs in `AppConfig` and can be overridden with:

```shell
flutter run --dart-define=CHARITY_API_BASE_URL=https://your-api.example.com
```

## Adding a feature

1. Add API-facing models/data sources under `app/data`.
2. Expose feature operations through a repository.
3. Add immutable state, controller, binding, and screens under
   `app/modules/<feature>`.
4. Register routes in `AppRoutes` and `AppPages`.
5. Reuse tokens from `app/core/theme` and widgets from `app/shared/widgets`.

Avoid global controllers for page state and avoid accessing `Get.find()` from
repositories. Constructor injection keeps each layer testable.
