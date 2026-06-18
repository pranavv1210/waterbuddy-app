# WaterBuddy Retry System Report

This report documents the design and math model of the Exponential Backoff + Jitter retry policy implemented in Phase 9.

---

## 1. Retry Algorithm Design

High-risk operations (location updates, cloud function invocations, payment checks) utilize `RetryPolicy.executeWithRetry` to automatically recover from transient network glitches.

### A. Exponential Backoff Formula
For each failed attempt $n$, the sleep duration $D_n$ scales exponentially:
$$D_n = \text{min}(D_{\text{max}}, D_{\text{initial}} \times M^{n-1})$$
- $D_{\text{initial}} = 500\text{ ms}$ (initial delay)
- $D_{\text{max}} = 5000\text{ ms}$ (maximum delay cap)
- $M = 2.0$ (exponential multiplier)

### B. Random Jitter Formula
To prevent the "thundering herd" problem (where all disconnected clients reconnect and hit the database simultaneously), we apply a randomized jitter coefficient:
$$J \in [0.9, 1.1]$$
$$\text{Sleep Time} = D_n \times J$$
This randomizes sleep timings within $\pm 10\%$, spreading request loads evenly across server instances.

---

## 2. Protected APIs and Operations
- **Location Syncs:** Recovers background location update streams after short cellular drops.
- **Razorpay Payments:** Retries server-side order checks if Razorpay's API experiences temporary connection delays.
- **Cloud Functions callable dispatches:** Retries function execution up to 3 times before failing the action in UI.
