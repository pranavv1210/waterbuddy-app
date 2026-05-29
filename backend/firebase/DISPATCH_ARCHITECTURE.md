# WaterBuddy Realtime Dispatch Architecture

This backend implements the production dispatch foundation for WaterBuddy.

## Flow

```text
Consumer creates orders/{orderId} with status SEARCHING
  -> onOrderCreated Cloud Function starts dispatch
  -> DispatchService finds nearest eligible online sellers
  -> order_offers/{offerId} is created for the nearest seller
  -> order status becomes OFFER_SENT
  -> FCM notification is sent to the seller
  -> seller accepts or rejects the offer
  -> onOfferUpdated Cloud Function finalizes accept/retry
  -> accepted offer assigns order and locks seller availability
  -> rejected/expired offer retries the next nearest seller
```

## Required Collections

```text
orders
order_offers
sellers
drivers
users
notifications
dispatch_logs
system_settings
seller_locations
driver_locations
tank_categories
```

## Required Seller Fields

```text
sellers/{sellerId}
  isOnline: boolean
  isAvailable: boolean
  verificationStatus: "approved" | "active"
  currentLocation:
    latitude: number
    longitude: number
    heading: number
    updatedAt: timestamp
  tankSizes: number[]
  tankerVehicles: array
```

## Required Settings

```text
system_settings/app
  bookingsEnabled: boolean
  maintenanceMode: boolean
  dispatchRadiusKm: number
  offerTimeoutSeconds: number
  maxDispatchAttempts: number
```

Defaults are applied in Cloud Functions when fields are missing.

## Deployment

```bash
cd backend/firebase
npm --prefix functions install
npm --prefix functions run build
firebase deploy --only firestore,functions
```

## Production Notes

- `expireOffers` runs every minute and expires pending offers whose `expiresAt` has passed.
- For strict 30-second retries at high scale, replace the scheduled expiry with Cloud Tasks.
- The current discovery service calculates distance from approved online sellers in Firestore. For large cities, move seller discovery to geohash query bounds or Cloud Run with a geospatial index.
- FCM tokens should be saved under `users/{uid}/fcmTokens/{token}`. The backend also checks seller and driver token subcollections.
