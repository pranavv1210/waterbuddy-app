# WaterBuddy Remote Config Report

This report documents the integration and configuration parameters of Firebase Remote Config, which enables runtime configuration shifts without rebuilding and updating the mobile application.

---

## 1. Configurable Values Matrix

We migrated the following operational constants from compile-time codes into Firebase Remote Config:

| Parameter Key | Data Type | Default Value | Purpose |
| --- | --- | --- | --- |
| `search_radius` | Double | `10.0` | Maximum dispatch and offer search radius (in kilometers) for sellers. |
| `order_timeout_seconds` | Integer | `300` | Expiration countdown window (in seconds) for unaccepted orders. |
| `location_update_interval_ms`| Integer | `5000` | Throttled frequency interval (in milliseconds) for GPS coordinate streaming. |
| `commission_percentage` | Double | `10.0` | System transaction split percentage. |
| `refund_window_minutes` | Integer | `15` | Valid timeframe (in minutes) for customers to request payment refunds after cancellation. |
| `notification_interval_seconds`| Integer| `10` | Frequency delay window between duplicate push alert dispatches. |
| `payment_retry_count` | Integer | `3` | Maximum automatic Razorpay checkout re-entry loop limits. |

---

## 2. Implementation Architecture

- **Fallback Strategy:** If the network is unavailable or Firebase fails during startup initialization, `RemoteConfigService` falls back gracefully to default values loaded from environment configurations (e.g. `.env.dev`, `.env.staging`, `.env.production`).
- **Fetch Settings:** Under debug builds, the fetch cache is bypassed (`minimumFetchInterval` set to `10 seconds`) for immediate iteration. In release mode, standard `1 hour` cache boundaries are enforced to save mobile battery and network resources.
- **Provider Access:** The service is integrated globally via `RemoteConfigService.instance` which guarantees stable parameter bindings.
