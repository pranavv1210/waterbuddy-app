# WaterBuddy Load Test Report

Date: 2026-06-18

## Target Simulation

- 100 customers
- 50 sellers
- 20 drivers
- Order assignment, payment verification, location updates, and session restoration paths

## Execution Status

No live emulator load run was executed in this pass because the repo does not include a load-test harness for seeded users/orders or concurrent callable execution. Flutter unit and service tests were run separately.

## Code-Level Concurrency Review

| Area | Control | Status |
| --- | --- | --- |
| Duplicate seller acceptance | Firestore transactions validate current order status and empty `sellerId` before assignment | Covered |
| Duplicate driver assignment | Firestore transaction validates assigned seller, status, and empty `driverId` | Covered |
| Stale searching orders | `cancelStaleOrders` batches up to 50 expired orders | Covered |
| Payment verification race | Server verifies Razorpay signature before marking payment successful | Covered |
| Location write pressure | Seller/driver tracking throttles by 5 seconds and 20 meters | Covered |
| FCM listener leaks | FCM stream subscriptions are now stored and disposed | Covered |

## Risks Remaining

- `sellerPendingOffersProvider` performs an order document read per offer snapshot. Under seller load this can multiply reads. Prefer denormalizing offer display fields or resolving related orders server-side.
- Some admin/global providers stream full collections (`users`, `sellers`, `drivers`, `orders`). These should be paginated for thousands of users.
- No automated deadlock/race load harness exists yet, so concurrency behavior is reviewed but not stress-proven.

## Recommended Harness

Create a Node script using Firebase Admin SDK against emulators that:

1. Seeds 100 customers, 50 sellers, 20 drivers.
2. Creates orders concurrently through the `placeOrder` callable.
3. Races multiple seller accept attempts against the same order.
4. Races multiple driver assignment attempts against the same order.
5. Verifies final invariants: exactly one seller, at most one driver, no stale active order older than the configured timeout.

