# WaterBuddy Phase 11 Report

Date: 2026-06-19

## Files Modified

- `apps/waterbuddy_superapp/lib/core/services/auth/auth_service.dart`
- `apps/waterbuddy_superapp/lib/features/auth/auth_controller.dart`
- `apps/waterbuddy_superapp/lib/features/auth/presentation/*otp*`
- `apps/waterbuddy_superapp/lib/features/auth/presentation/password_reset_screen.dart`
- `apps/waterbuddy_superapp/lib/features/auth/presentation/seller_login_screen.dart`
- `apps/waterbuddy_superapp/lib/core/services/location/google_maps_service.dart`
- `apps/waterbuddy_superapp/lib/features/home/presentation/home_screen.dart`
- `apps/waterbuddy_superapp/lib/features/tracking/presentation/tracking_screen.dart`
- `apps/waterbuddy_superapp/lib/widgets/document_upload_field.dart`
- `apps/waterbuddy_superapp/lib/core/services/payments/razorpay_service.dart`
- `apps/waterbuddy_superapp/lib/features/payments/providers/payment_providers.dart`
- `apps/waterbuddy_superapp/lib/core/services/notifications/notification_service.dart`
- `apps/waterbuddy_superapp/lib/core/services/location/*tracking_service.dart`
- `apps/waterbuddy_superapp/lib/core/widgets/app_initializer.dart`
- `apps/waterbuddy_superapp/lib/core/services/crashlytics/crashlytics_service.dart`
- `apps/waterbuddy_superapp/android/**`
- `apps/waterbuddy_superapp/ios/Runner/**`
- `backend/firebase/firebase.json`
- `backend/firebase/storage.rules`

## Services Integrated

- Firebase Phone Authentication for OTP.
- Google Maps SDK configuration for Android and iOS.
- Google Places, Directions, Distance Matrix, and Geocoding API helpers.
- Razorpay live key enforcement through Firebase Secret Manager function response.
- Firebase Cloud Messaging foreground/background/terminated-state handling.
- Firebase Storage document uploads for seller and driver verification files.
- Platform-aware seller/driver foreground/background location tracking settings.

## Firebase Console Settings Needed

- Enable Firebase Authentication phone provider.
- Enable Google sign-in provider and configure Android/iOS OAuth clients.
- Configure Firebase Storage bucket and deploy `backend/firebase/storage.rules`.
- Configure FCM APNs key/certificate for iOS notifications.
- Configure Firebase Functions secrets:
  - `RAZORPAY_KEY_ID`
  - `RAZORPAY_KEY_SECRET`
  - `RAZORPAY_WEBHOOK_SECRET`

## Google Cloud Settings Needed

- Enable Maps SDK for Android.
- Enable Maps SDK for iOS.
- Enable Places API.
- Enable Directions API.
- Enable Distance Matrix API.
- Enable Geocoding API.
- Restrict API keys by platform/package/bundle and enabled APIs.

## API Keys Needed

- `GOOGLE_MAPS_API_KEY`
- `RAZORPAY_KEY_ID` with `rzp_live_` prefix
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`

## Urgent Fixes After Device/CI Failure

- Fixed `[core/no-app] No Firebase App '[DEFAULT]' has been created` startup failure by ensuring `Firebase.initializeApp()` runs before Firebase Performance tracing.
- Added a Firebase initialization guard in `CrashlyticsService` so pre-init error handlers cannot throw `[core/no-app]`.
- Updated Android build tooling for CI metadata failures:
  - Android Gradle Plugin: `8.11.1`
  - Kotlin Gradle Plugin: `2.2.20`
  - Gradle wrapper: `8.14.3-bin`
  - NDK: `28.2.13676358`

## Testing Evidence

- `flutter clean`: passed after running outside the sandbox.
- `flutter pub get`: passed.
- `npm run build` in `backend/firebase/functions`: passed.
- `flutter build apk --release --flavor production`: passed before the final Android toolchain bump.
- `dart analyze`, `flutter analyze`, and `flutter test`: timed out locally due Dart tooling hang.
- Rebuild after Android toolchain bump: blocked locally because this machine cannot reach the network to download the new Gradle wrapper distribution. CI should download it normally.

## Build Outputs

- APK path from successful production build before final CI toolchain bump:
  - `apps/waterbuddy_superapp/build/app/outputs/flutter-apk/app-production-release.apk`
- AAB path expected after CI build:
  - `apps/waterbuddy_superapp/build/app/outputs/bundle/productionRelease/app-production-release.aab`

## Notes

- No backend architecture, state machines, collections, wallet flow, payout flow, refund flow, security model, or analytics model was intentionally changed.
- Storage rules were added because Phase 11 requires Firebase Storage document uploads.
