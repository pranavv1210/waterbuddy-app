# WaterBuddy Security Audit Report

Date: 2026-06-18

## Scope

Reviewed Firestore rules in `backend/firebase/firestore_rules/firestore.rules`, callable payment verification, and backend-owned metric/payment collections.

## Attack Scenarios

| Scenario | Expected Result | Rule / Control | Status |
| --- | --- | --- | --- |
| Customer reads foreign order | Rejected | `/orders/{orderId}` read requires `customerId == request.auth.uid` unless seller, driver, or admin owns the order | Pass by rules review |
| Customer modifies foreign order | Rejected | Customer update requires `resource.data.customerId == request.auth.uid` and status `CANCELLED` only | Pass by rules review |
| Customer changes payment fields | Rejected | Customer cancel path blocks `paymentStatus`, `paymentId`, `razorpayOrderId`, `razorpaySignature` | Pass by rules review |
| Seller becomes admin | Rejected | `/admins` write requires admin claim; `/users` role changes are not sufficient to grant custom claims | Pass by rules review |
| Seller changes `verificationStatus` | Rejected | Seller self-update preserves existing `verificationStatus` | Pass by rules review |
| Driver modifies payment docs | Rejected | `/payment_events/{eventId}` `allow write: if false` | Pass by rules review |
| Anonymous writes | Rejected | All write paths require owner/admin/signed-in role except backend-only paths that are false | Pass by rules review |
| Admin spoofing through document fields | Rejected | Admin authorization uses `request.auth.token.role == 'admin'`, not document data | Pass by rules review |
| Client writes system metrics | Rejected | `/system_metrics/{docId}` `allow write: if false` | Pass by rules review |

## Emulator Execution

Not executed in this pass. The repository has Firebase rules and Functions build scripts, but no committed emulator attack test harness or npm test script. Recommended follow-up: add `@firebase/rules-unit-testing` tests for each scenario above and wire them to `backend/firebase/functions/package.json`.

## Findings

- Strong backend ownership exists for payment events, ratings, dispatch logs, and system metrics.
- Seller location writes now target `seller_locations`, matching Firestore rules.
- Admin dashboard and several presentation screens still contain direct Firestore access. This is an architecture concern, not a rules bypass, but it increases the chance of future unsafe client writes.

