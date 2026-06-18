# WaterBuddy Feature Flags Report

This report outlines the runtime feature toggling system, allowing administrators to disable or enable premium modules without modifying code.

---

## 1. Feature Toggles Catalog

The following feature flags are registered inside `RemoteConfigService` and are backed by environment-specific defaults (`.env.dev`, `.env.staging`, `.env.production`):

| Feature Key | Development Default | Staging Default | Production Default | Description |
| --- | --- | --- | --- | --- |
| `feature_wallets` | `true` | `true` | `true` | Enables driver/seller ledger wallets & balance withdrawal consoles. |
| `feature_reviews` | `true` | `true` | `true` | Toggles feedback submission screens after delivery completes. |
| `feature_ratings` | `true` | `true` | `true` | Enables visual rating stars on profiles and tankers. |
| `feature_referrals` | `true` | `true` | `true` | Enables peer invite reward programs. |
| `feature_promotions` | `false` | `true` | `true` | Enables promotional coupon code applications. |
| `feature_surge_pricing`| `false` | `true` | `true` | Activates dynamic multipliers during high-demand/low-tanker hours. |
| `feature_subscriptions`| `false` | `false` | `true` | Enables monthly automated supply contracts. |
| `feature_driver_incentives`| `false` | `false` | `true` | Activates bonus payout modifiers for high-volume drivers. |

---

## 2. Dynamic Evaluator Usage

- **Local Override:** Feature flags query `dotenv` flags during initialization, ensuring that local offline test runners maintain predictable outputs.
- **Client Resolution:** Screen routes evaluate flag methods before mounting. For example, if `isWalletEnabled` returns `false`, go_router intercepts the redirect and blocks entry, degrading the app interface gracefully.
