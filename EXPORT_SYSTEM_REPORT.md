# WaterBuddy Export System Report

This report documents the admin-triggered datasets compiler, which compiles Firestore document records into CSV spreadsheets for offline audits and reporting.

---

## 1. Exportable Collections Catalog

Administrators can trigger compiled exports across seven central business layers:

| Target Domain | Export Fields (Examples) | Output Formats | Purpose |
| --- | --- | --- | --- |
| **Orders** | `orderId`, `customerId`, `sellerId`, `amount`, `status`, `createdAt` | CSV | Matches dispatch volumes and delivery durations. |
| **Users** | `uid`, `name`, `email`, `phone`, `createdAt` | CSV | User registration metrics. |
| **Drivers** | `uid`, `vehicleNumber`, `licenseNumber`, `rating` | CSV | Driver pool statistics and performance. |
| **Sellers** | `uid`, `companyName`, `tankerCapacity`, `verificationStatus` | CSV | Seller availability and licensing logs. |
| **Wallets** | `walletId`, `balance`, `payoutAccount`, `updatedAt` | CSV | Financial ledger payouts verification. |
| **Refunds** | `refundId`, `orderId`, `amount`, `refundStatus`, `approvedAt` | CSV | Financial refund logs and audit trails. |
| **Reviews** | `reviewId`, `orderId`, `rating`, `comment`, `createdAt` | CSV | Feedback quality analysis. |

---

## 2. Serialization and Safety
- **CSV Escaping Rules:** The [exportService.ts](file:///c:/Users/Pranav/Desktop/waterbuddy-app/backend/firebase/functions/src/services/exportService.ts) helper sanitizes commas, returns, and quotes, wrapping objects in doubly-escaped quotes to prevent CSV injection vulnerabilities.
- **Admin Authentication:** Exports are protected via HTTPS admin role checks (`request.auth.token.role == 'admin'`), ensuring data sheets can never be accessed by non-privileged accounts.
