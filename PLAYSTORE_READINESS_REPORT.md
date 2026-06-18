# WaterBuddy App Store & Play Store Readiness Report

This report outlines the required metadata, legal policies, and permissions justifications required to deploy the WaterBuddy Superapp to Google Play and the Apple App Store.

---

## 1. App Metadata Descriptions

### Short Description (Google Play - max 80 chars)
Get clean drinking water delivered to your doorstep. Quick tankers, smart tracking.

### Full Description (max 4000 chars)
WaterBuddy is the ultimate drinking water delivery application designed to bridge the gap between customers, local water tanker sellers, and delivery drivers. Whether you need water for household use, commercial purposes, or emergency refills, WaterBuddy connects you with verified suppliers instantly.

**Features:**
- **Role-Based Experience:** Unified application tailored for Consumers (Customers), Tanker Sellers (Vendors), and Delivery Drivers.
- **On-Demand Dispatching:** Fast, automated matchmaking based on distance, capacity (in Litres), and availability.
- **Real-Time GPS Tracking:** Know exactly where your water tanker is with accurate, live ETA calculations and route updates.
- **Secure Ledger Wallet:** Dedicated digital wallet for drivers and sellers with transparent payouts, commission calculations, and immutable transaction histories.
- **Digital Payments & Verification:** Seamless online payment processing via Razorpay (including cash-on-delivery fallback), verified by secure webhook handlers.
- **Rating & Reviews:** Rate drivers, sellers, and overall delivery quality to ensure the highest standards.

Get started today and never run out of clean drinking water again!

---

## 2. Permissions Justification (Critical for Review Approval)

### Location Access (Foreground & Background)
- **Background Location (`ACCESS_BACKGROUND_LOCATION`)**: Required for **Sellers** and **Drivers** to broadcast their live location to customers during an active delivery run, ensuring customers have accurate ETA updates. Background tracking shuts off automatically once the order is COMPLETED or CANCELLED.
- **Foreground Location (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`)**: Used by **Consumers** to specify their exact delivery address pin on the map.

### Push Notifications (`POST_NOTIFICATIONS`)
- Used to alert users about critical order state changes (e.g., "Order Accepted", "Driver Arrived", "Payment Success"), and dispatching new offers to offline/online sellers.

---

## 3. Legal and Compliance Policies

### Support Email
- `support@waterbuddy.app`

### Privacy Policy
Available at: `https://waterbuddy.app/privacy`
- **Data Collection:** We collect user account details (name, email, phone number, vehicle number), location data (GPS coordinates), and payment transaction history.
- **Location Use:** GPS coordinates are tracked in the background solely to facilitate delivery dispatching and routing.
- **Third-Party Services:** We share transaction data with Razorpay (payment processing) and use Google Maps APIs for geocoding and routing.

### Terms of Service
Available at: `https://waterbuddy.app/terms`
- **Usage Rules:** All tanker sellers must possess valid licenses and commercial vehicle registration certificates (RC) to operate.
- **Booking Policy:** Cancelled orders are subject to cancellation charges determined by system settings.
- **Account Termination:** We reserve the right to suspend accounts engaged in spoofing, fraudulent activities, or privilege escalation.

### Refund Policy
Available at: `https://waterbuddy.app/refunds`
- **Eligibility:** Full refunds are issued if no seller/driver is assigned within the dispatch timeout.
- **Cancellation Charge:** If an order is accepted by a seller and subsequently cancelled by the consumer, a fixed cancellation charge is deducted from the refund amount.
- **Wallet Credits:** Backend approved refunds are credited back to the customer's wallet or original source of payment within 5-7 business days.

### User Data Deletion Policy
Available at: `https://waterbuddy.app/delete-account`
- Users can request complete account deletion via the App Profile page. Deleting the account permanently removes user credentials, active locations, and FCM tokens. Transactional ledgers (payouts, settlements) are archived securely to comply with financial auditing guidelines.

---

## 4. Production Release Instructions

### Build Command (Google Play AAB)
```bash
flutter clean
flutter pub get
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Build Command (Android APK)
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

### Build Command (iOS IPA)
```bash
flutter build ipa --release
```

---

## 5. Versioning & Release Notes (Version 1.8.0+8)
- **Version Name:** `1.8.0`
- **Build Number:** `8`
- **Release Notes:**
  - Enhanced background location reporting resilience across network transitions.
  - Implemented client-side bounding box query optimization to minimize Firestore read overhead.
  - Added strict state transition validation to prevent race conditions during concurrent driver assignments.
  - Deployed automatic database cleanup functions for expired dispatch logs and stale sessions.
