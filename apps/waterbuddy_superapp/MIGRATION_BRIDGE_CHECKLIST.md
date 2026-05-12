# WaterBuddy SuperApp Phase 1.5 Migration Bridge Checklist

## Features migrated
- [x] Unified role routing for `consumer`, `seller`, `driver`, `admin`
- [x] Seller online/offline state in `sellers/{uid}.isOnline`
- [x] Seller live location writes in `sellers/{uid}.currentLocation`
- [x] Top-5 nearest seller dispatch filtering (within 5km)
- [x] Driver assignment lifecycle fields on `orders/{orderId}`
- [x] Seller verification gate with `verificationStatus`
- [x] Admin dual authorization (allowlist + Firestore admin doc)
- [x] Backward-compatible Firestore rules for legacy `customer`

## Providers migrated
- [x] Core auth/router providers centralized in `lib/providers/app_providers.dart`
- [x] Seller location/dispatch providers
- [x] Driver assigned-order stream provider
- [x] Seller verification status provider

## Services migrated
- [x] Unified auth service with role-aware profile upsert
- [x] Unified order service with extended statuses and timestamps
- [x] Seller location tracking service with throttled writes

## Routes migrated
- [x] Role selection/auth/otp root flow
- [x] Consumer shell routes
- [x] Seller dashboard/waiting/blocked routes
- [x] Driver dashboard route
- [x] Admin dashboard route
- [x] Unauthorized route

## Firebase integrations migrated
- [x] Shared Firestore collections for users/sellers/drivers/admins/orders
- [x] Existing consumer booking/tracking/payment flow kept
- [x] Existing notification/token plumbing kept in superapp

## Remaining dependencies on old apps
- [ ] Seller KYC doc upload flow parity not yet migrated into superapp
- [ ] Seller earnings/profile editing parity not yet migrated into superapp
- [ ] Dedicated driver live location push into order `tracking` from driver app flow not yet added
- [ ] Legacy `seller_app` UI-specific map/ops components still only in old app

## Remaining duplicate logic to remove after final verification
- [ ] `apps/customer_app` duplicated auth/router/providers
- [ ] `apps/seller_app` duplicated auth/router/providers
- [ ] Old app-specific route constants/services

## Runtime verification gates before deletion
- [ ] OTP login + Google sign-in on real device
- [ ] Consumer end-to-end booking to delivery completion
- [ ] Seller online → receive feed → accept → assign driver
- [ ] Driver order progression `DRIVER_ASSIGNED` → `ON_THE_WAY` → `ARRIVED` → `DELIVERED`
- [ ] Admin approval/reject/suspend and access lock validation
- [ ] FCM and Razorpay smoke tests in superapp
