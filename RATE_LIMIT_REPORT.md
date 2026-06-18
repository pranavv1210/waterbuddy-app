# WaterBuddy Rate Limiting Report

This report outlines the rate-limiting design, configurations, and sliding window checks implemented in Firebase Cloud Functions to prevent API spamming and resource exhaustion.

---

## 1. Rate Limiting Configurations

We enforce strict rate limits per user ID (UID) or IP address across six high-risk operations:

| API Operation | Target Action | Sliding Window | Max Allowed Requests | Enforcement Mechanism |
| --- | --- | --- | --- | --- |
| **OTP Requests** | `otp` | 1 Minute | `3` | Firestore transaction list check (throws `resource-exhausted`). |
| **Booking Creation** | `booking` | 5 Minutes | `5` | Prevents scripts or bots from creating ghost tanker bookings. |
| **Refund Requests** | `refund` | 1 Hour | `2` | Protects settlement channels from excessive transaction updates. |
| **Wallet Topups** | `wallet_topup` | 15 Minutes | `5` | Restricts API replay attacks on wallet payment collections. |
| **Review Spam** | `review` | 5 Minutes | `3` | Filters review and rating updates to block review-bot manipulations. |
| **Notification Spam**| `notification`| 1 Minute | `10` | Restricts client-triggered SMS or Push alert dispatches. |

---

## 2. Technical Implementation details

- **Sliding Window Check:** The `RateLimiterService.checkLimit()` helper uses Firestore transactions to read and update lists of unix timestamps under the document path `/rate_limits/{userId}_{action}`.
- **Auto-Eviction:** Old timestamps falling outside the `windowMs` are evicted from the array during updates, keeping the document sizes low.
- **Graceful Error:** If a client violates the limit, the Cloud Function terminates immediately with the standard gRPC status code `14` (`resource-exhausted`), which maps directly to a clean, user-friendly Toast message on the frontend.
