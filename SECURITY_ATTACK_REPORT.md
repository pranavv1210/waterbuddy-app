# WaterBuddy Security Attack Report

This report documents the security audit and validation of the Firestore Security Rules under six distinct real-world attack scenarios.

---

## Audit Summary

| Attack Scenario | Target Collection | Verification Metric | Status |
| --- | --- | --- | --- |
| 1. Customer reads another customer's orders | `/orders/{orderId}` | Check `resource.data.customerId == request.auth.uid` | **PASSED (Rejected)** |
| 2. Customer modifies another order | `/orders/{orderId}` | Check `resource.data.customerId == request.auth.uid` | **PASSED (Rejected)** |
| 3. Driver modifies payment documents | `/payment_events/*`, `/wallets/*` | Check `allow write: if false;` | **PASSED (Rejected)** |
| 4. Seller escalates privileges | `/sellers/{sellerId}` | Check `!request.resource.data.diff(resource.data).affectedKeys().hasAny([...])` | **PASSED (Rejected)** |
| 5. Anonymous writes | Any collection | Check `request.auth != null` | **PASSED (Rejected)** |
| 6. Admin spoof attempts | `/admins/*`, `/dispatch_logs/*` | Check `request.auth.token.role == 'admin'` | **PASSED (Rejected)** |

---

## Scenario Details & Rules Enforcement

### Scenario 1: Customer reads another customer's orders
- **Attack Vector:** An authenticated customer tries to fetch an order document belonging to another customer by guessing or scraping the order ID.
- **Enforcement Rule:**
  ```javascript
  match /orders/{orderId} {
    allow read: if isAdminRole()
      || (isConsumerRole() && resource.data.customerId == request.auth.uid)
      || (isSellerRole() && resource.data.sellerId == request.auth.uid)
      || (isDriverRole() && resource.data.driverId == request.auth.uid);
  }
  ```
- **Result:** Access denied. Only the owning customer, the assigned seller, the assigned driver, or an admin can read the order.

### Scenario 2: Customer modifies another order
- **Attack Vector:** A customer tries to cancel or alter fields on another customer's order.
- **Enforcement Rule:**
  ```javascript
  allow update: if isAdminRole()
    || (isConsumerRole()
      && resource.data.customerId == request.auth.uid
      && request.resource.data.status == 'CANCELLED'
      && !request.resource.data.diff(resource.data).affectedKeys()
          .hasAny(['paymentStatus', 'paymentId', 'razorpayOrderId', 'razorpaySignature']));
  ```
- **Result:** Access denied. A consumer can only update their own order, and only to mark it as `CANCELLED` without changing payment metadata.

### Scenario 3: Driver modifies payment documents
- **Attack Vector:** A driver attempts to bypass the commission settlement by directly writing to their wallet, payouts, or payment webhook collections.
- **Enforcement Rule:**
  ```javascript
  match /payment_events/{eventId} { allow write: if false; }
  match /wallets/{walletId} { allow write: if false; }
  match /wallet_transactions/{transactionId} { allow write: if false; }
  match /driver_payouts/{payoutId} { allow write: if false; }
  ```
- **Result:** Access denied. All ledger-related collections are locked (`allow write: if false;`) and can only be updated server-side by Firebase Admin SDK via Cloud Functions.

### Scenario 4: Seller escalates privileges
- **Attack Vector:** A seller tries to self-approve their pending registration or inflate their rating metadata.
- **Enforcement Rule:**
  ```javascript
  match /sellers/{sellerId} {
    allow update: if isAdminRole()
      || (isOwner(sellerId)
        && request.resource.data.verificationStatus == resource.data.verificationStatus
        && !request.resource.data.diff(resource.data).affectedKeys()
            .hasAny(['averageRating', 'ratingCount']));
  }
  ```
- **Result:** Access denied. While sellers can update their online status or vehicle info, any attempt to modify `verificationStatus` or rating statistics is blocked.

### Scenario 5: Anonymous writes
- **Attack Vector:** Unauthenticated clients attempt to read system settings or inject spam records.
- **Enforcement Rule:**
  ```javascript
  function isSignedIn() {
    return request.auth != null;
  }
  ```
- **Result:** Access denied. Every collection matching core data checks `isSignedIn()` or specific role tokens.

### Scenario 6: Admin spoof attempts
- **Attack Vector:** A regular driver or seller adds a claim in their client auth state or tries to read centralized admin logs.
- **Enforcement Rule:**
  ```javascript
  function role() {
    return isSignedIn() ? request.auth.token.role : null;
  }
  function isAdminRole() {
    return role() == 'admin';
  }
  ```
- **Result:** Access denied. Custom claims like `role: 'admin'` are set exclusively server-side via the `setRoleClaims` Cloud Function, and Firestore checks this custom claim token before allowing access to `/admins` or admin-only collections.
