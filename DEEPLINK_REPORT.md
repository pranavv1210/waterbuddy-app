# WaterBuddy Deep Linking Report

This report documents the deep link mapping schemas, GoRouter configurations, and custom FCM notification routing integrations.

---

## 1. Deep Link Mappings Schema

We support the custom URL scheme `waterbuddy://` for target routing:

| Deep Link URL | Target Routing Path | User Interface / Feature |
| --- | --- | --- |
| `waterbuddy://tracking/{orderId}` | `/consumer/tracking?orderId={orderId}` | Live GPS tanker tracking screen for the customer. |
| `waterbuddy://orders` | `/consumer/orders` | Customer order history panel. |
| `waterbuddy://wallet` | `/consumer/payments` | Ledger transactions, topups, and Razorpay logs. |
| `waterbuddy://profile` | `/consumer/profile` | Customer user account profile and settings. |
| `waterbuddy://refunds` | `/consumer/payments` | Payout refunds list status. |
| `waterbuddy://reviews` | `/consumer/orders` | Delivery ratings and feedback screen. |

---

## 2. Notification Integration

- **FCM Click Actions:** Push notifications sent via Firebase Cloud Functions include a custom data field `click_action` containing a deep link (e.g. `waterbuddy://tracking/WB-ORD-12345`).
- **App Foreground/Background Resolution:**
  - In the foreground, tapping on a system banner routes the user instantly via `DeeplinkService.handleLink()`.
  - When the app is in the background or terminated, Firebase Messaging SDK handles the click action, launches the application shell, and triggers the `DeeplinkService.handleFcmNotificationPayload()` callback at boot.
