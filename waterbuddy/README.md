# WaterBuddy MVP Monorepo

Phase 1 scaffold for a scalable on-demand water delivery platform.

## Structure

```text
waterbuddy/
  apps/
    customer_app/
    seller_app/
    admin_dashboard/
    landing_page/
  backend/
    firebase/
      functions/
      firestore_rules/
      models/
  shared/
    constants/
    utils/
    types/
```

## Principles

- No UI business data is hardcoded.
- UI state is driven by providers, services, or database-backed repositories.
- Firebase is the source of truth for auth, Firestore, functions, and push notifications.
- Business logic is separated from presentation across all clients.

## Phase 1 Deliverables

- Monorepo structure
- Firebase base integration
- Core domain models
- Base auth and order service contracts
- Initial navigation and placeholder screens
- Admin and landing web shells
- Backend order orchestration skeleton

## Setup Notes

- Add Firebase configuration values in each app's `.env` or platform config.
- Replace placeholder Firebase options in Flutter with generated values from `flutterfire configure`.
- Install each app's dependencies independently.
- Deploy Firestore rules and Cloud Functions from `backend/firebase`.
