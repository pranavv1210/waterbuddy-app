# Firestore Schema

## users

- `id`
- `name`
- `phone`
- `role`
- `createdAt`

## sellers

- `id`
- `kycStatus`
- `isOnline`
- `tankSizes`
- `pricing`
- `serviceArea`

## orders

- `id`
- `customerId`
- `sellerId`
- `tankSize`
- `status`
- `paymentType`
- `paymentStatus`
- `location`
- `candidateSellerIds`
- `rejectedSellerIds`
- `createdAt`
- `updatedAt`

## tracking

- `orderId`
- `lat`
- `lng`
- `timestamp`

## complaints

- `id`
- `orderId`
- `userId`
- `status`
- `createdAt`
