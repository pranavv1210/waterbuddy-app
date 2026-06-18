# WaterBuddy Human-Readable ID System Report

This report documents the structured ID prefixing rules implemented across Core collections to replace standard random Firestore keys with recognizable human-readable formats.

---

## 1. ID Prefix Formatting Schemas

We enforce the following key prefix formats across all created documents:

| Entity / Collection | ID Format | Example | Generation Layer |
| --- | --- | --- | --- |
| **Orders** | `WB-ORD-XXXXXXXX` | `WB-ORD-X8K9L2P4` | Client-Side / OrderService. |
| **Refunds** | `WB-RFD-XXXXXXXX` | `WB-RFD-Y7J2N9K1` | Server-Side / RefundService. |
| **Payments** | `WB-PAY-XXXXXXXX` | `WB-PAY-T6E3H1W0` | Client-Side / RazorpayService. |
| **Wallets** | `WB-WAL-XXXXXXXX` | `WB-WAL-A2V4C9R8` | Server-Side / WalletService. |
| **Drivers** | `WB-DRV-XXXXXXXX` | `WB-DRV-M5L1O3T9` | Client-Side / Registration. |
| **Sellers** | `WB-SEL-XXXXXXXX` | `WB-SEL-P9W8E7Q1` | Client-Side / Registration. |

*Where `XXXXXXXX` represents a cryptographically secure 8-character uppercase alphanumeric random string.*

---

## 2. Benefits of Structured IDs
- **Enhanced Debugging:** Telemetry logs matching `[ORDER]` or `[PAYMENT]` display the precise entity type instantly, speeding up troubleshooting in production tools like Crashlytics.
- **Improved Customer Support:** Users can reference clean, short order IDs (`WB-ORD-F3X8`) instead of guessing standard 20-character Firestore hash strings.
