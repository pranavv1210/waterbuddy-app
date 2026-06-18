# WaterBuddy Memory Audit Report

This report documents the memory profiling and resource cleanup audit conducted across the WaterBuddy Superapp components.

---

## 1. StreamSubscriptions Audit

| Service / Controller | Stream Source | Lifecycle Management / Disposal | Status |
| --- | --- | --- | --- |
| **FcmService** | `onTokenRefresh`, `onMessage`, `onMessageOpenedApp` | Subscriptions `_tokenRefreshSub`, `_foregroundMessageSub`, `_messageOpenedSub` are cancelled in `FcmService.dispose()`. Called by `AppInitializerState.dispose()`. | **SECURE** |
| **BackgroundService** | `system_settings/app` snapshots | Subscription `_connectivitySub` is cancelled in `BackgroundService.detach()`. Called via Riverpod `ref.onDispose()`. | **SECURE** |
| **SellerOnlineController** | `/sellers/{uid}` snapshots | Subscription `_selfSub` is cancelled in `dispose()`. | **SECURE** |
| **DriverOnlineController** | `/drivers/{uid}` snapshots | Subscription `_selfSub` is cancelled in `dispose()`. | **SECURE** |
| **Seller Location Tracking** | Geolocator position updates | Subscription `_subscription` is cancelled in `stop()`. | **SECURE** |
| **Driver Location Tracking** | Geolocator position updates | Subscription `_subscription` is cancelled in `stop()`. | **SECURE** |

---

## 2. Timers Audit

| Component / Controller | Timer Function | Disposal Mechanism | Status |
| --- | --- | --- | --- |
| **LocationSelectionScreen** | Search debounce (280ms) | `_debounce?.cancel()` invoked in `dispose()`. | **SECURE** |
| **SearchingTankersScreen** | Status switcher (2s) | `_statusTimer?.cancel()` invoked in `dispose()`. | **SECURE** |
| **PasswordResetScreen** | OTP countdown timer (1s) | `_timer?.cancel()` invoked in `dispose()`. | **SECURE** |
| **DriverOtpScreen** | OTP countdown timer (1s) | `_timer?.cancel()` invoked in `dispose()`. | **SECURE** |
| **ConsumerOtpScreen** | OTP countdown timer (1s) | `_timer?.cancel()` invoked in `dispose()`. | **SECURE** |

---

## 3. TextEditingControllers Audit

- **Audit Findings:** All TextEditingControllers are declared inside State classes of StatefulWidgets / ConsumerStatefulWidgets and are explicitly disposed in their `dispose` methods:
  - `LocationSelectionScreen`: `_searchController.dispose()` (Verified).
  - `SellerDashboardScreen` (`_FleetViewState`): `_vehicle.dispose()`, `_capacity.dispose()`, `_rcNumber.dispose()` (Verified).
  - `SellerDashboardScreen` (`_ProfileViewState`): `_name.dispose()`, `_phone.dispose()`, `_email.dispose()`, `_license.dispose()`, `_emergency.dispose()`, `_address.dispose()` (Verified).
  - `SellerSignupScreen`: all registration controllers disposed.
  - `DriverSignupScreen`: all registration controllers disposed.
  - `PasswordResetScreen`: all OTP controllers disposed.
- **Disposal Verification:** Complete. No dangling controllers were found.

---

## 4. AnimationControllers Audit

- **Radar Animation:** Inside `SearchingTankersScreen`, `_radarController` is declared with `SingleTickerProviderStateMixin` and is properly closed via `_radarController.dispose()` inside the widget's `dispose()` method.
- **Micro-Animations:** Verified that all animation controller references have a matching `.dispose()` call inside widget disposes to avoid leaking Tickers.

---

## 5. Provider Lifecycles (Riverpod)

- **AutoDispose Providers:** Providers that listen to Firestore streams (like `searchingOrdersProvider`, `sellerPendingOffersProvider`, `activeOrderProvider`) utilize `StreamProvider` or Riverpod autoDispose mechanisms so that their streams automatically cancel and unsubscribe from Firestore when the matching UI screen is closed or unmounted.
- **OnDispose Callbacks:** In `app_providers.dart`, the `backgroundServiceProvider` registers `ref.onDispose(service.detach)`, ensuring that when the provider is destroyed, the background connectivity listeners are cleanly cancelled.
