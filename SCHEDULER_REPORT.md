# WaterBuddy Scheduled Jobs Report

This report documents the serverless cron scheduling configured in Firebase Cloud Functions to automate database maintenance, aggregates compiling, and ledger reconciliations.

---

## 1. Cron Maintenance Matrix

We support ten scheduled tasks running via Firebase Scheduler v2:

| Function Name | Cron / Frequency | Target Action | Scope |
| --- | --- | --- | --- |
| `cleanupExpiredOffers` | `every 5 minutes` | Evict expired pending dispatcher offers. | Realtime Offer Lifecycle. |
| `cleanupStaleOrders` | `every 15 minutes`| Cancel orders stuck in SEARCHING state. | Customer dispatch fallback. |
| `cleanupOrphanNotifications`| `every 30 minutes`| Delete read notifications older than 7 days. | Database cleanup. |
| `cleanupInactiveLocations`| `every 60 minutes`| Prune driver location updates for offline users. | Geolocation optimization. |
| `cleanupOrphanSessions` | `every 60 minutes`| Force-fail orders stuck active for > 24 hours. | Abandoned orders protection. |
| `cleanupOldDispatchLogs` | `0 0 * * *` (Daily) | Delete dispatch history documents older than 30 days. | Log retention policy. |
| `cleanupOldMetrics` | `0 1 * * *` (Daily) | Delete telemetry metrics older than 90 days. | Storage optimization. |
| `dailyMaintenanceJobs` | `0 2 * * *` (Daily) | Runs daily metrics aggregation, wallet reconciliation, and rating updates. | Business Intelligence. |
| `monthlyReportingJobs` | `0 0 1 * *` (Monthly) | Generates commission reports and compiles driver/seller statistics. | Invoicing & Audits. |

---

## 2. Invariant Reconciliation Checks
- **Wallet Reconciliation:** Calculates current wallet balances against the sum of settled order payouts to verify audit compliance and prevent double-withdrawal glitches.
- **Log Retention Policy:** Purging historical locations and telemetry logs prevents storage bloat, keeping monthly Firebase billing to minimum levels.
