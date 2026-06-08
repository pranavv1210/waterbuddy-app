# WaterBuddy Real-Time Dispatch Engine Report

This report documents the architecture and implementation details of the real-time dispatch and tracking system in WaterBuddy.

## 1. Firestore Database Schema
We structured our Firestore collections to model a classic dispatch platform (similar to ride-sharing apps):

- **`/orders/{orderId}`:** Contains the primary order details, delivery address, geolocation, selected tanker category, payment status, active status (`SEARCHING`, `DRIVER_ASSIGNED`, `DELIVERED`, etc.), and assigned driver profile.
- **`/order_offers/{offerId}`:** Track dispatched offers to tanker owners, including `orderId`, `sellerId`, `status` (`PENDING`, `ACCEPTED`, `EXPIRED`), distance, and `expiresAt` (30-second TTL).
- **`/driver_locations/{driverId}`:** Stores live geohashed latitude and longitude of active drivers.
- **`/system_settings/app` & `/configs/platform`:** Platform configs (bookings toggle, dispatch radius, support contacts, base delivery/cancellation fees).

## 2. Geohash Indexing & Dispatch Logic
- **Driver Querying:** The dispatch engine retrieves all online, available drivers from `driver_locations/`.
- **Sorting & Dispatches:** Drivers are filtered within the dispatch radius (configured in Admin) and sorted by distance.
- **Offer Loop:**
  - An offer document is created in `order_offers/` and a push notification is sent to the nearest tanker owner.
  - If rejected or expired (30 seconds), the engine moves to the next closest tanker.
  - When accepted, a Firestore transaction is used to safely assign the driver, preventing multiple drivers from claiming the same order.

## 3. Real-Time Status & Location Tracking
- **Order State Machine:** Real-time listeners on the `/orders` collection instantly update the consumer UI as the order changes from `SEARCHING` to `ACCEPTED`, `DRIVER_ASSIGNED`, `ON_THE_WAY`, `ARRIVED`, and `DELIVERED`.
- **Live Tracking Map:** The tracking screen subscribes to coordinates inside `driver_locations/{driverId}` and animates the map marker and camera position smoothly using `google_maps_flutter` controllers.
- **Cancellation Flow:** Consumers can cancel bookings while searching or after assignment. The cancel screen allows selecting a cancellation reason, triggers cancellation fees, and releases driver availability.
