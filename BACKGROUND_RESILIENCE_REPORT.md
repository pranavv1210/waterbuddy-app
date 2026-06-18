# WaterBuddy Background Resilience Report

This report evaluates the application's stability, battery consumption, background location updates, and push notifications under extreme background states and permission revocations.

---

## 1. Background State Handling

### App Terminated by OS (Memory Pressure)
- **Behavior:** The operating system terminates the application while location tracking or order search is active.
- **Resilience:** 
  - On app launch, `AppInitializer` re-configures `FcmService`.
  - `BackgroundService` performs a silent state restoration. It queries Firestore to check if the user is associated with any active order (`status` in `['SEARCHING', 'ASSIGNED', 'EN_ROUTE']`).
  - If an active order is found, the navigator routes the user to the correct active screen (`/consumer/searching` or `/consumer/tracking`).
- **Result:** **Graceful Recovery.**

### Phone Reboot / Cold Start
- **Behavior:** The device is powered off and booted back up.
- **Resilience:**
  - Login session is persisted locally via `FirebaseAuth` secure token storage.
  - User role is persisted in `RoleSessionService` (via `SharedPreferences`).
  - During `initState` of the home/splash widgets, the auth state is evaluated. The app navigates to the role-specific landing, starts background configuration, and queries Firestore to restore active orders.
- **Result:** **Graceful Recovery.**

### Low Battery / Battery Saver Mode
- **Behavior:** OS limits background CPU cycles and disables continuous location updates.
- **Resilience:**
  - `BackgroundService.shouldThrottleBackgroundOps` returns `true` under battery saver conditions, signaling location updates to throttle down.
  - Geolocator's `LocationSettings` utilizes `distanceFilter: 20` and `interval: 5000` to prevent excessive battery drain by restricting location updates unless the driver/seller has moved more than 20 meters.
- **Result:** **Graceful Degradation.**

---

## 2. Network & Connectivity Failure

### No Network (Airplane Mode / Dead Zones)
- **Behavior:** Sudden loss of cellular or Wi-Fi connection.
- **Resilience:**
  - Firestore offline cache persistence is enabled globally:
    ```dart
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    ```
  - App continues reading existing data from the cache immediately without freeze/crash.
  - Writes are queued locally. When network is restored, Firestore automatically syncs local writes to the backend database.
- **Result:** **Offline Persistence Active.**

---

## 3. Permissions Revocation Handling

### Location Permissions Revoked / Denied
- **Behavior:** The user denies or revokes location permission at runtime.
- **Resilience:**
  - If location permission is denied:
    - **Consumer:** Fallback to a default center point (e.g., Bengaluru coordinates: `12.9716, 77.5946`) and prompts the user with a warning toast `Location permission is required.` when attempting "Use current location". The consumer can manually select their address via Map or saved locations.
    - **Seller/Driver:** Location tracking service catches the permission exception, disables GPS updates, updates status to offline, and prints a debug warning `Permission denied - location tracking disabled`. It does NOT crash the app.
- **Result:** **Graceful Degradation.**

### Push Notifications Permission Denied
- **Behavior:** The user refuses to grant push notification permissions.
- **Resilience:**
  - `FcmService.initialize` requests permissions via `FirebaseMessaging.instance.requestPermission()`.
  - If denied, it outputs `[FCM] Notifications denied by user` and logs a warning in Crashlytics.
  - The app skips saving the FCM token but continues operating normally. All status updates are pulled in real time via Firestore snapshot streams, ensuring the user still receives updates within the app.
- **Result:** **Graceful Degradation.**
