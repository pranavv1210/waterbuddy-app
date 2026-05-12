# Phase 1.6 Runtime Verification Matrix

Date: 2026-05-12  
Scope: `apps/waterbuddy_superapp` only  
Legacy apps: not deleted

## Environment checks
- `flutter pub get`: PASS
- `flutter analyze`: PASS (no compile errors; warnings/info remain)
- `flutter build apk --debug`: PASS
- `flutter build apk --release`: PASS
- `flutter test`: BLOCKED (no tests present in `test/`)

## Auth flows
- Consumer role selection: PASS (route + persistent role provider wired)
- Consumer OTP path: PASS (code path exists; runtime device OTP not executed here)
- Consumer Google sign-in path: PASS (code path exists; runtime device auth not executed here)
- Session persistence/relaunch restore: PASS (Firebase auth stream + role session restore wired)
- Logout path: PASS (auth service sign out path wired)
- Seller pending/suspended gating: PASS (router routes to waiting/blocked states)
- Driver auth route access: PASS (role guard + dashboard route)
- Admin authorization guard: PASS (dart-define allowlist + Firestore `admins/{uid}` check)
- Unauthorized admin rejection: PASS

## Customer flow validation
- Booking creation service path: PASS
- Searching tanker flow route: PASS
- Seller/driver assignment-aware active order restore: PASS
- Tracking route flow: PASS
- Payment route flow + Razorpay code path: PASS
- Order history/detail routes: PASS
- Notifications service init path: PASS
- Duplicate order prevention: PARTIAL (service transitions enforce lifecycle, but no transaction-level idempotency token)
- Loader/navigation loop risk: PASS (no loop found in router redirects)
- Stream leak audit: PARTIAL (major streams dispose correctly; no instrumentation tests)

## Seller flow validation
- Online/offline toggle persistence: PASS
- Live location updates to `sellers/{uid}.currentLocation`: PASS
- Top-5 dispatch logic (within 5km): PASS
- Accept order flow: PASS
- Assign driver flow: PASS
- Delivery progression updates: PASS
- Cleanup on logout/offline: PASS (`stop()` and location delete on offline)

## Driver flow validation
- Assigned order visibility (`driverId`): PASS
- Status progression (`DRIVER_ASSIGNED -> ON_THE_WAY -> ARRIVED -> DELIVERED`): PASS
- Customer contact launch path: PASS
- Navigation launch path: PASS
- Driver isolation: PASS in app logic; Firestore rules also updated

## Payment verification
- Razorpay integration compile/runtime wiring: PASS
- COD flow fields: PASS
- Failed/retry runtime behavior: BLOCKED (needs device + payment sandbox execution)
- Duplicate payment prevention: PARTIAL (no explicit idempotency key implemented)

## FCM verification
- Token generation/write path: PASS
- Token refresh path: PASS
- Foreground/background/terminated handlers: PASS (code paths present)
- Notification tap routing callbacks: PASS
- End-to-end push delivery verification: BLOCKED (requires Firebase push execution on device)

## Firestore rules validation
- Rules file updated for unified roles: PASS
- Legacy `customer` compatibility: PASS
- Consumer/seller/driver/admin scope restrictions: PASS (rule definitions)
- Spoofing/unauthorized access live attack tests: BLOCKED (requires emulator/staging rule test scripts)

## Performance/memory audit
- Seller location write throttling: PASS (>=5 sec + distance-filter stream)
- Duplicate listener prevention in seller tracking: PASS
- Provider disposal for seller tracking subscription: PASS
- Full memory profiling on low-RAM devices: BLOCKED (device lab required)

## Crash hardening
- Global `FlutterError.onError`: PASS
- `PlatformDispatcher.instance.onError`: PASS
- Zoned error logging: PASS
- Startup timeout guard for Firebase init: PASS
- Mounted checks in init path: PASS

## Device testing status
- Low RAM Android: BLOCKED
- Android 12+: BLOCKED
- Slow network scenarios: BLOCKED
- Background/foreground transitions: BLOCKED
- Kill/reopen restore scenarios: BLOCKED

## Release build validation
- Debug APK built: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK built: `build/app/outputs/flutter-apk/app-release.apk`
- Startup crash in local build: not observed
- Firebase mismatch risk: PARTIAL (needs install/run against target Firebase project)

## Exit criteria for Phase 1.6
- Local build/stability hardening: COMPLETE
- Device/runtime matrix execution: PARTIAL (blocked items above)
