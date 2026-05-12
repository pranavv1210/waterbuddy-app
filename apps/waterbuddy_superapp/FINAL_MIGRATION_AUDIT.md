# FINAL_MIGRATION_AUDIT

Date: 2026-05-12

## Migrated
- Unified super app shell with role-based routing (`consumer`, `seller`, `driver`, `admin`)
- Unified auth service and role profile upsert
- Seller location tracking bridge to `sellers/{uid}.currentLocation`
- Driver assignment lifecycle fields and statuses in `orders`
- Seller verification gating via `sellers/{uid}.verificationStatus`
- Dual admin authorization checks (allowlist + Firestore admin doc)
- Firestore security rules unified with legacy `customer` compatibility
- Debug and release APK generation successful

## Pending
- Real-device runtime verification matrix completion (OTP, Google sign-in, Razorpay live scenarios, FCM push delivery)
- Emulator/staging malicious-rule attack tests (spoofing/invalid writes)
- Low-RAM and Android 12+ behavior tests under network constraints
- Legacy seller KYC/doc upload parity in superapp
- Explicit payment idempotency token guard (optional hardening)

## Safe-to-delete (after runtime verification only)
- Old duplicated auth/router/provider logic in `apps/customer_app`
- Old duplicated auth/router/provider logic in `apps/seller_app`
- Legacy duplicate mock repositories already removed in `waterbuddy_superapp`

## Blocked-by-runtime
- Any final deletion of old apps
- Final production sign-off
- Final release promotion

## Remaining duplicate/legacy references in superapp package scaffolding
- Desktop/web/iOS/macOS/windows generated app naming still references `waterbuddy_customer_app` in platform scaffold files.
- Android package id still `com.waterbuddy.customer` in:
  - `android/app/build.gradle.kts`
- These are not runtime blockers for Android verification, but should be normalized before final release branding.

## Remaining dependencies on old apps
- None at Dart import-level for superapp runtime logic.
- Old apps remain as fallback and reference implementation until blocked runtime checks are cleared.
