# WaterBuddy Analytics Events Report

This report outlines the custom telemetry event tracking setup designed to capture user activities, booking lifecycles, and financial metrics in production.

---

## 1. Analytics Events Schema

We track 14 critical custom events mapped through `AnalyticsService`:

| Event Name | Parameter Keys | Trigger Condition |
| --- | --- | --- |
| `login` | `user_id`, `role` | User completes auth flow and logs into their profile. |
| `signup` | `user_id`, `role` | New account registration completed successfully. |
| `booking_created` | `order_id`, `amount`, `tank_size` | Consumer requests a new tanker order. |
| `booking_cancelled`| `order_id`, `reason`, `cancelled_by` | Order state changes to CANCELLED. |
| `booking_completed`| `order_id` | Tanker is delivered and pin verification matches. |
| `payment_success` | `order_id`, `payment_id` | Razorpay order succeeds and signature validates. |
| `payment_failure` | `order_id`, `error_code`, `error_message` | Razorpay checkout error or signature verification fails. |
| `refund_requested` | `order_id`, `amount` | Cancellation triggers a server-side refund process. |
| `refund_approved` | `order_id`, `amount` | Admin approves payout release of refund amount. |
| `wallet_topup` | `user_id`, `amount` | Driver/Seller successfully adds credit/adjusts ledger. |
| `seller_online` | `seller_id`, `online` | Seller toggles active status. |
| `driver_online` | `driver_id`, `online` | Driver toggles active status. |
| `review_submitted` | `order_id`, `rating` | Feedback questionnaire submitted. |
| `order_timeout` | `order_id` | System cancels search after 5 minutes of inactivity. |

---

## 2. Telemetry and Logging Connection
All events are piped immediately to the standard `FirebaseAnalytics` engine. In development/staging builds, events are also logged locally to [observability_service.dart](file:///c:/Users/Pranav/Desktop/waterbuddy-app/apps/waterbuddy_superapp/lib/core/services/observability/observability_service.dart) for quick debugging and verification.
