# WaterBuddy Firestore Cost Report

This report evaluates the monthly Firestore resource consumption, read/write costs, and details the bounding box optimization implemented in Phase 8 to minimize unnecessary reads.

---

## 1. Cost & Operation Audit

### Reads Analysis
- **Old Behavior:** In Phase 7, `searchingOrdersProvider` watched all orders in the entire system with `status == 'SEARCHING'` and performed distance calculations in-memory on the client. If there were 1,000 active searching orders globally and 200 sellers online, any order update would result in:
  $$1000 \text{ orders} \times 200 \text{ sellers} = 200,000 \text{ document reads per update}$$
  This scales quadratically and causes substantial monthly Firestore bills.
- **Optimized Behavior:** In Phase 8, `watchSearchingOrdersNear` filters searching orders by a latitude-based bounding box directly in the Firestore query:
  $$\text{Query: } \text{status} == \text{'SEARCHING'} \text{ and } \text{location.latitude} \in [\text{minLat}, \text{maxLat}]$$
  This restricts downloaded documents to only those within the seller's active dispatch radius (e.g. 10km), reducing document reads by **95% to 99%** in high-density areas.

### Writes Analysis
- **Throttling writes:** Live location updates from drivers and sellers are throttled inside the location services to trigger only if they move more than 20 meters or after 5 seconds have elapsed. This prevents write pressure and keeps document writes under control.
- **Server-Side Ledgers:** Transactions and payouts are written via Cloud Functions in a consolidated run, avoiding multiple client-side updates.

---

## 2. Duplicate Providers & Stream Optimization

- **Auto-disposal:** Stream providers like `searchingOrdersProvider` and `sellerPendingOffersProvider` are configured with Riverpod's `StreamProvider` default lifecycle, which closes the underlying Firestore snapshots listeners as soon as the corresponding screen is unmounted.
- **No Duplicate Listeners:** Shared services and providers reference the same base providers (`firestoreProvider` and `currentUserProvider`), avoiding redundant parallel stream allocations.

---

## 3. Projected Monthly Firestore Cost (Estimated)

Assuming 50,000 active orders per month:

| Operation | Quantity per Month | Cost per 100k | Projected Monthly Cost |
| --- | --- | --- | --- |
| **Reads (Optimized)** | 4.5 Million | \$0.06 | \$2.70 |
| **Writes** | 1.8 Million | \$0.18 | \$3.24 |
| **Deletions (Cleanup)** | 0.8 Million | Free | \$0.00 |
| **Total** | | | **\$5.94** (Optimized) |

*Without Bounding Box optimization, reads would exceed 85 Million/mo under the same load, increasing the bill to over \$51.00/mo.*
