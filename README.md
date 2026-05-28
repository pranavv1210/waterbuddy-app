# WaterBuddy

WaterBuddy is a unified Flutter superapp for on-demand water tanker delivery. It connects consumers, tank owners, drivers, and administrators through a real-time Firebase-backed logistics workflow.

The app is built for operational use: admins configure available tank categories and service rules, consumers book water from active categories, sellers and drivers manage delivery execution, and all roles receive live state updates through Firestore streams.

## Contents

- [Product Overview](#product-overview)
- [Role-Based Apps](#role-based-apps)
- [Core Features](#core-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Firestore Schema](#firestore-schema)
- [Order Lifecycle](#order-lifecycle)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Firebase Configuration](#firebase-configuration)
- [Run Locally](#run-locally)
- [Build APKs](#build-apks)
- [Quality Checks](#quality-checks)
- [Security Notes](#security-notes)
- [Roadmap](#roadmap)
- [Support](#support)
- [License](#license)

## Product Overview

WaterBuddy provides a marketplace-style delivery flow for water tanker services:

1. Admin creates tank categories and controls platform settings.
2. Consumers choose a delivery location and active tank category.
3. The app creates an order in Firestore.
4. Nearby online tank owners see matching orders within dispatch radius.
5. Tank owner accepts the order and assigns delivery execution.
6. Consumer tracks the order status until delivery completion.

The current repository contains the unified role-based Flutter mobile app under `apps/waterbuddy_superapp`.

## Role-Based Apps

### Consumer

- Sign in and access the consumer home screen.
- Select or confirm delivery location on map.
- View active tank categories configured by admin.
- Book water using COD or online payment depending on admin settings.
- Track active orders.
- View order history and order details.
- Cancel eligible orders with configured cancellation charge applied.
- Access profile, support, payments, saved addresses, and settings.

### Admin

- Manage operational dashboard.
- Create, edit, enable, disable, and delete tank categories.
- Configure bookings, COD, cancellation charge, delivery charge, dispatch radius, city, support email, and support number.
- Review orders.
- Manage consumers, tank owners, drivers, approvals, support tickets, payments, and notifications.
- Persist configuration in Firestore so consumer and partner flows update in real time.

### Tank Owner / Seller

- Maintain online/offline availability.
- Receive nearby searching orders based on dispatch radius.
- Accept available orders.
- Manage active deliveries and seller profile state.
- Participate in approval and suspension workflows controlled by admin.

### Driver

- Access assigned delivery workflow.
- Update status during delivery.
- Use location-enabled operational screens.

## Core Features

- Unified Flutter app with role selection.
- Firebase Authentication integration.
- Cloud Firestore real-time streams.
- Firebase Cloud Messaging service foundation.
- Admin-configured tank categories.
- Admin-configured runtime platform settings.
- Map-based consumer booking flow using `flutter_map`.
- GPS/location support through `geolocator` and `geocoding`.
- Order creation, cancellation, status updates, and live tracking.
- Razorpay service foundation with COD support.
- Role-aware routing using `go_router`.
- Riverpod providers for app state and Firestore streams.
- Android debug and release APK build support.

## Tech Stack

| Layer | Technology |
| --- | --- |
| App framework | Flutter |
| Language | Dart |
| State management | Riverpod |
| Routing | GoRouter |
| Authentication | Firebase Authentication |
| Database | Cloud Firestore |
| Notifications | Firebase Cloud Messaging |
| Maps | flutter_map, OpenStreetMap tiles |
| Location | geolocator, geocoding |
| Payments | Razorpay integration foundation |
| Local preferences | shared_preferences |
| Platforms | Android, iOS-ready Flutter project structure |

## Architecture

WaterBuddy uses a Firebase-first, real-time architecture.

```text
Flutter UI
  -> Riverpod providers
  -> Services and controllers
  -> Firebase Authentication
  -> Cloud Firestore streams and transactions
  -> Role-specific UI updates
```

Important architecture points:

- Admin configuration is stored in Firestore and consumed by runtime flows.
- Tank category streams drive the consumer booking UI.
- Orders are stored centrally in Firestore and observed by consumers, sellers, drivers, and admins.
- Seller matching uses order location, seller location, online state, and dispatch radius.
- Navigation is role-aware and protected through app route guards.

## Firestore Schema

### `tank_categories`

Admin-created tank categories available for consumer booking.

```text
tank_categories/{categoryId}
  id: string
  name: string
  litres: number
  price: number
  iconType: "drop" | "tanker" | "water"
  isActive: boolean
  createdAt: timestamp
  updatedAt: timestamp
```

Compatibility fields are also written for older app code and existing data:

```text
displayName: string
basePrice: number
iconKey: string
active: boolean
```

Icon usage:

- `drop`: basic domestic water service.
- `tanker`: large commercial tanker category.
- `water`: premium, bulk, or emergency water service.

### `system_settings`

Runtime platform configuration used across admin and consumer flows.

```text
system_settings/app
  bookingsEnabled: boolean
  codEnabled: boolean
  cancellationCharge: number
  deliveryCharge: number
  dispatchRadiusKm: number
  supportNumber: string
  supportEmail: string
  serviceCity: string
  maintenanceMode: boolean
  updatedAt: timestamp
```

### `orders`

Consumer bookings and delivery state.

```text
orders/{orderId}
  customerId: string
  customerName: string
  customerPhone: string
  tankSize: number
  tankLabel: string
  tankId: string
  amount: number
  pricingSnapshot: map
  location: map
  status: string
  paymentType: "COD" | "ONLINE"
  paymentStatus: string
  sellerId: string | null
  driverId: string | null
  cancellationReason: string
  cancellationCharge: number
  createdAt: timestamp
  updatedAt: timestamp
```

### User and Partner Collections

```text
users/{uid}
sellers/{uid}
drivers/{uid}
admin_notifications/{notificationId}
support_tickets/{ticketId}
complaints/{complaintId}
```

## Order Lifecycle

Orders move through a controlled state flow:

```text
SEARCHING
  -> ACCEPTED
  -> DRIVER_ASSIGNED
  -> ON_THE_WAY
  -> ARRIVED
  -> DELIVERED
```

Cancellation is allowed from active states when valid:

```text
SEARCHING -> CANCELLED
ACCEPTED -> CANCELLED
ASSIGNED -> CANCELLED
DRIVER_ASSIGNED -> CANCELLED
ON_THE_WAY -> CANCELLED
ARRIVED -> CANCELLED
```

Invalid transitions are rejected by the order service.

## Project Structure

```text
waterbuddy-app/
  apps/
    waterbuddy_superapp/
      android/
      ios/
      lib/
        app.dart
        main.dart
        firebase_options.dart
        core/
          auth/
          constants/
          services/
          theme/
          widgets/
        features/
          admin/
          auth/
          driver/
          home/
          onboarding/
          orders/
          payments/
          profile/
          seller/
          settings/
          splash/
          tracking/
        models/
        providers/
        routes/
        widgets/
      pubspec.yaml
    admin_dashboard/
    landing_page/
  assets/
  backend/
  shared/
  google-services.json
```

## Setup

### Prerequisites

- Flutter SDK compatible with Dart `>=3.3.0 <4.0.0`.
- Android Studio or Android SDK command-line tools.
- Java 17 for Android builds.
- Firebase project with Authentication and Firestore enabled.
- Android device or emulator.

Check your local Flutter environment:

```bash
flutter doctor
```

Install dependencies:

```bash
cd apps/waterbuddy_superapp
flutter pub get
```

## Firebase Configuration

Required Firebase services:

- Authentication
- Cloud Firestore
- Cloud Messaging

Recommended setup:

1. Create a Firebase project.
2. Add an Android app with the package name used by the Flutter Android project.
3. Download `google-services.json`.
4. Place it in:

```text
apps/waterbuddy_superapp/android/app/google-services.json
```

5. Ensure `lib/firebase_options.dart` matches the Firebase project.
6. Enable required sign-in providers in Firebase Authentication.
7. Create Firestore collections as the app writes them, or allow the app to create them during usage.

## Run Locally

From the superapp directory:

```bash
cd apps/waterbuddy_superapp
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

## Build APKs

Debug APK:

```bash
cd apps/waterbuddy_superapp
flutter build apk --debug
```

Release APK:

```bash
cd apps/waterbuddy_superapp
flutter build apk --release
```

Build outputs:

```text
apps/waterbuddy_superapp/build/app/outputs/flutter-apk/app-debug.apk
apps/waterbuddy_superapp/build/app/outputs/flutter-apk/app-release.apk
```

## Quality Checks

Format code:

```bash
dart format lib
```

Analyze code:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Current note: the project may contain analyzer warnings for style, deprecated Flutter APIs, or unused imports. Compile-blocking analyzer errors should be fixed before release.

## Security Notes

- Do not commit production secrets, keystores, or private API keys.
- Keep Firebase security rules aligned with role access.
- Consumer users should only access their own orders and profile data.
- Sellers should only update their own seller state and assigned orders.
- Admin-only operations should be protected by role checks and Firestore rules.
- Payment credentials should be kept outside source control.
- Location data should only be shared for active order and dispatch use cases.

## Roadmap

Planned improvements:

- Harden Firestore security rules for each role.
- Add production admin audit logs.
- Add Firebase Storage for documents and operational attachments.
- Improve seller matching with geospatial indexing.
- Add richer payment reconciliation.
- Add scheduled bookings.
- Add in-app support ticket creation.
- Add admin screenshot or screen recording capture if operational audit requires it.
- Add automated tests for order lifecycle and configuration flows.

## Support

Project support contact:

- Email: [waterbuddyapp.wb@gmail.com](mailto:waterbuddyapp.wb@gmail.com)

Repository:

- GitHub: [pranavv1210/waterbuddy-app](https://github.com/pranavv1210/waterbuddy-app)

## License

This project is proprietary software for WaterBuddy. All rights are reserved.

Unauthorized copying, distribution, sublicensing, or commercial use is not permitted without written approval from the project owner.
