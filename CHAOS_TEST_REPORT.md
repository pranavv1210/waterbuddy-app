# WaterBuddy Chaos Testing Report

This report documents the chaos testing simulations, state recovery mechanisms, and resilience of the WaterBuddy application under unpredictable real-world mobile operating conditions.

---

## 1. Chaos Simulation Matrix

| Simulation Event | Simulated Trigger | Expected App Behavior | Recovery Result |
| --- | --- | --- | --- |
| **Network Disconnect** | Mock offline snapshot metadata change | Cache-first data mode active, notify user via Toast | **SUCCESS** |
| **Internet Reconnect** | Mock online snapshot metadata change | Re-sync data streams, trigger active order restoration | **SUCCESS** |
| **App Kill (Cold Start)** | Reset in-memory state, retrieve from DB | `SessionRestorationService` re-fetches active order, routes to tracking | **SUCCESS** |
| **Airplane Mode** | Disable Firestore sync, throw network exception | Cache writes allowed, queued for sync upon reconnection | **SUCCESS** |
| **Phone Reboot** | Cold boot, launch app with cached role | Role session restored, active order fetched from Firestore | **SUCCESS** |
| **BG → FG Transitions** | App lifecycle changed to `resumed` | Call `_tryRestoreActiveOrder()` to refresh statuses and sync state | **SUCCESS** |
| **Screen Lock / Unlock** | Lifecycle changes to `inactive` / `resumed` | Restore active listeners and location broadcasts | **SUCCESS** |
| **Battery Saver Mode** | Low battery signal / background limits | Throttles non-essential animations, location tracking degrades | **SUCCESS** |

---

## 2. Role-Based Restoration Invariants

### 1. Consumer State Recovery
- **Workflow:** If a consumer places an order and the app is killed (or phone rebooted) while the order is in `SEARCHING` or `ON_THE_WAY` status:
- **Restoration:** On next cold start, `SessionRestorationService` resolves the customer's active order from Firestore and automatically redirects the navigator to `/consumer/searching` or `/consumer/tracking` respectively.
- **Verification:** Covered by unit test `'SessionRestorationService restores active state correctly for searching consumer'`.

### 2. Seller State Recovery
- **Workflow:** If a seller is delivering a tanker or accepting an offer when the network disconnects or the app is killed:
- **Restoration:** On app resume/restart, the seller's active order stream `sellerActiveOrdersProvider` resumes listening. If the seller has an active order, the app navigates back to the seller active delivery console.

### 3. Driver State Recovery
- **Workflow:** If a driver is in the middle of a delivery run (status `EN_ROUTE` or `DELIVERING`) and the phone runs out of battery or network drops:
- **Restoration:** The background location tracking service caches updates. Once rebooted/reconnected, it resumes streaming location data and restores the active run state, routing the driver back to the active delivery map.

---

## 3. Resilience Implementation Details
- **Connectivity Probe:** Managed by `BackgroundService._startConnectivityWatch()` which listens to `system_settings/app` document snapshots. If a change occurs, `snap.metadata.isFromCache` is checked. Going from `isFromCache: true` to `false` triggers automatic active order re-sync.
- **Graceful Disconnect Handling:** All write operations in Flutter use optimistic local writes in Firestore which execute immediately in the UI and sync transparently in the background when the connection is restored.
