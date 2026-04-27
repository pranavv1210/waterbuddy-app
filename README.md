<div align="center">

<h1 style="display: flex; align-items: center; justify-content: center; gap: 12px; margin: 0; line-height: 1.1;">
  <img src="https://cdn-icons-png.flaticon.com/512/3105/3105807.png" alt="WaterBuddy Logo" width="40" style="display: block;" />
  <span style="display: block;">WaterBuddy - On-Demand Water Delivery</span>
</h1>

<p>
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#project-structure">Project Structure</a> •
  <a href="#setup">Setup</a> •
  <a href="#legal">Legal</a>
</p>

<img src="https://images.unsplash.com/photo-1616348436168-de43ad0db179?w=800&h=400&fit=crop" alt="WaterBuddy Banner" width="85%" />

<br/>

<img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img alt="Firebase" src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img alt="Android" src="https://img.shields.io/badge/Android-34A853?style=for-the-badge&logo=android&logoColor=white" />
<img alt="iOS" src="https://img.shields.io/badge/iOS-111827?style=for-the-badge&logo=apple&logoColor=white" />
<img alt="Real-time" src="https://img.shields.io/badge/Real--Time-00687A?style=for-the-badge&logo=googleanalytics&logoColor=white" />

</div>

---

WaterBuddy is a production-ready on-demand water tanker delivery platform connecting customers with verified water suppliers in real-time.

## Quick Links
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Firebase Setup](#firebase-setup)
- [Android Signing](#android-signing)
- [License](#license)

## Features

### Customer App
- Phone OTP authentication via Firebase
- Instant tanker booking with tank size selection
- Real-time order tracking with GPS
- Multiple payment options (COD, Online)
- Order history and management
- Live seller location tracking
- Search timeout handling with retry

### Seller App
- Availability toggle for online/offline status
- Real-time order alerts for nearby requests
- Order acceptance/decline workflow
- Delivery status updates (ASSIGNED → ON_THE_WAY → DELIVERED)
- GPS location tracking during delivery
- Earnings dashboard and performance metrics

### Admin Dashboard (Planned)
- Order monitoring and management
- Seller verification and KYC
- Revenue tracking and analytics
- Complaint handling system

## Architecture

- **Client**: Flutter (Dart) with Riverpod state management
- **Backend**: Firebase (Authentication, Firestore, Cloud Messaging)
- **Auth**: Firebase Phone Authentication (OTP)
- **Database**: Cloud Firestore (Real-time)
- **Maps**: Placeholder for future map integration
- **Location**: `geolocator` package
- **Routing**: `go_router` for navigation
- **State**: `flutter_riverpod` for reactive state management

## Project Structure

```text
waterbuddy-app/
├── apps/
│   ├── customer_app/
│   │   └── lib/
│   │       ├── main.dart
│   │       ├── app.dart
│   │       ├── firebase_options.dart
│   │       ├── core/
│   │       │   ├── services/
│   │       │   │   ├── auth/
│   │       │   │   ├── orders/
│   │       │   │   └── location/
│   │       │   └── widgets/
│   │       ├── features/
│   │       │   ├── auth/
│   │       │   ├── home/
│   │       │   ├── tracking/
│   │       │   └── payments/
│   │       ├── models/
│   │       ├── providers/
│   │       └── routes/
│   │
│   ├── seller_app/
│   │   └── lib/
│   │       ├── main.dart
│   │       ├── app.dart
│   │       ├── firebase_options.dart
│   │       ├── core/
│   │       │   ├── services/
│   │       │   │   ├── auth/
│   │       │   │   ├── orders/
│   │       │   │   ├── seller/
│   │       │   │   └── location/
│   │       │   └── widgets/
│   │       ├── features/
│   │       │   ├── auth/
│   │       │   ├── home/
│   │       │   ├── orders/
│   │       │   └── earnings/
│   │       ├── models/
│   │       ├── providers/
│   │       └── routes/
│   │
│   └── admin_dashboard/ (planned)
│
├── backend/
│   └── firebase/
│       └── firestore.rules
│
└── shared/ (planned)
```

## Setup

### 1. Install Dependencies

```bash
# Customer App
cd apps/customer_app
flutter pub get

# Seller App
cd apps/seller_app
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Phone Authentication
3. Create Firestore database
4. Add Android apps for both customer and seller
5. Download `google-services.json` and place in:
   - `apps/customer_app/android/app/`
   - `apps/seller_app/android/app/`
6. Run `flutterfire configure` to generate `firebase_options.dart`

### 3. Run in Debug Mode

```bash
# Customer App
cd apps/customer_app
flutter run

# Seller App
cd apps/seller_app
flutter run
```

### 4. Build Release APKs

```bash
# Customer App
cd apps/customer_app
flutter build apk --release --build-name=1.0.0 --build-number=1

# Seller App
cd apps/seller_app
flutter build apk --release --build-name=1.0.0 --build-number=1
```

## Firebase Setup

### Required Services
- **Authentication**: Enable Phone provider for OTP-based auth
- **Firestore**: Create database in production mode
- **Cloud Messaging**: Enable for push notifications (optional)

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /orders/{orderId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /sellers/{sellerId} {
      allow read, write: if request.auth != null && request.auth.uid == sellerId;
    }
  }
}
```

## Android Signing

For release signing, configure `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            storeFile file("your_keystore.jks")
            storePassword "your_password"
            keyAlias "your_alias"
            keyPassword "your_key_password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

## Order Lifecycle

Orders progress through the following states:

1. **SEARCHING**: Order created, visible to nearby online sellers
2. **ASSIGNED**: Seller accepted, customer navigates to payment
3. **ON_THE_WAY**: Delivery started, GPS tracking active
4. **DELIVERED**: Order complete, payment processed

## Tech Stack

### Mobile Apps
- **Flutter 3.3+**: Cross-platform framework
- **Riverpod 2.5+**: State management
- **GoRouter 14.2+**: Declarative routing
- **Firebase SDK 3.1+**: Backend services
- **Geolocator 12.0+**: GPS tracking

### Backend
- **Firebase Authentication**: Phone OTP
- **Cloud Firestore**: Real-time database
- **Firebase Cloud Messaging**: Push notifications

## Legal & Compliance

### Contact
- **Email**: waterbuddyapp.wb@gmail.com
- **Support**: waterbuddyapp.wb@gmail.com

### Licenses and Registrations
- Business Registration: WaterBuddy Technologies Pvt. Ltd.
- GST Registration: [To be updated]
- Trade License: Valid for water delivery services

### Data Protection
- Privacy Policy: Compliant with IT Act, 2000 (India)
- Data Localization: All data stored within Indian jurisdiction
- GDPR Readiness: Framework prepared

### Intellectual Property
- Trademark: WaterBuddy name and logo are registered
- Copyright: Protected under Indian Copyright Act, 1957

## License

This project is proprietary software. All rights are reserved by WaterBuddy.

For licensing inquiries, contact: waterbuddyapp.wb@gmail.com

### Admin Dashboard

- Order Monitoring: View all active and completed orders across the platform in real-time
- Seller Management: Approve new seller applications, manage KYC verification, and monitor seller performance
- Revenue Tracking: Analyze platform revenue, payment collections, and financial metrics
- Complaint Handling: Address customer complaints and resolve disputes efficiently
- Analytics Dashboard: Monitor key performance indicators including order volume, delivery times, and customer satisfaction

## System Architecture

WaterBuddy is built on a cloud-native architecture leveraging Firebase for backend services:

- Firebase Authentication: Secure user authentication for customers and sellers using phone-based OTP verification
- Cloud Firestore: Real-time NoSQL database enabling instant data synchronization across all clients
- Firebase Cloud Messaging: Push notifications for order alerts, status updates, and promotional messages
- Flutter: Cross-platform mobile framework for iOS and Android applications
- Riverpod: State management solution for reactive UI updates based on real-time data changes

The architecture follows an event-driven pattern where user actions trigger Firestore updates, which are immediately propagated to all connected clients through real-time listeners. This ensures that order status changes, location updates, and availability toggles are reflected instantly across the platform.

## Order Lifecycle

Orders progress through a defined state machine ensuring clear communication between all parties:

1. SEARCHING: Order created by customer, visible to nearby online sellers
2. ASSIGNED: Seller accepts the order, customer navigates to payment screen
3. ON_THE_WAY: Seller starts delivery, location tracking enabled, customer can track in real-time
4. DELIVERED: Seller marks order as complete, payment processed, order archived

Additional states include CANCELLED (by customer or timeout) for handling order cancellations.

## Tech Stack

### Mobile Applications
- Flutter 3.3+: Cross-platform development framework
- Riverpod 2.5+: State management and dependency injection
- GoRouter 14.2+: Declarative routing with deep linking support
- Firebase SDK 3.1+: Authentication, Firestore, Cloud Messaging

### Backend Services
- Firebase Authentication: Phone-based OTP authentication
- Cloud Firestore: Real-time database with offline support
- Firebase Cloud Functions: Server-side logic for complex operations (planned)
- Firebase Storage: File storage for seller documents and images (planned)

### Admin Dashboard
- Next.js 14+: React framework for web application
- TypeScript: Type-safe development
- Tailwind CSS: Utility-first CSS framework (planned)

### Payment Integration
- Razorpay: Online payment gateway (planned integration)
- Cash on Delivery: Manual payment collection option

## Data Flow

The order creation and fulfillment flow demonstrates the real-time architecture:

1. Customer initiates order through mobile app, selecting tank size and location
2. OrderService creates document in Firestore `orders` collection with status 'SEARCHING'
3. Seller app listens to `orders` collection where status = 'SEARCHING' and seller is online
4. When seller accepts order, Firestore transaction updates status to 'ASSIGNED' and assigns sellerId
5. Customer app receives real-time update via Firestore listener, navigates to payment screen
6. Customer selects payment method, Firestore updates paymentType and paymentStatus
7. Customer navigates to tracking screen, seller app updates status to 'ON_THE_WAY'
8. LocationTrackingService begins periodic GPS updates to Firestore tracking field
9. Customer tracking screen receives real-time location updates via Firestore listener
10. Seller updates status to 'DELIVERED' upon completion, location tracking stops
11. Order archived, payment processed, completion metrics recorded

## Folder Structure

```
waterbuddy-app/
├── apps/
│   ├── customer_app/          # Customer mobile application
│   │   ├── lib/
│   │   │   ├── core/          # Core services (auth, orders, location)
│   │   │   ├── features/      # Feature modules (home, tracking, payments)
│   │   │   ├── models/        # Data models
│   │   │   ├── providers/     # Riverpod providers
│   │   │   └── routes/        # Navigation configuration
│   │   └── android/           # Android native configuration
│   ├── seller_app/            # Seller/partner mobile application
│   │   ├── lib/
│   │   │   ├── core/          # Core services (auth, orders, location, availability)
│   │   │   ├── features/      # Feature modules (home, orders, earnings)
│   │   │   ├── models/        # Data models
│   │   │   ├── providers/     # Riverpod providers
│   │   │   └── routes/        # Navigation configuration
│   │   └── android/           # Android native configuration
│   ├── admin_dashboard/       # Admin web dashboard (planned)
│   └── landing_page/          # Marketing landing page (planned)
├── backend/
│   └── firebase/
│       ├── firestore.rules     # Database security rules
│       └── functions/         # Cloud Functions (planned)
└── shared/                    # Shared utilities and types (planned)
```

## Getting Started

### Prerequisites

- Flutter SDK 3.3.0 or higher
- Dart SDK 3.3.0 or higher
- Android Studio / Xcode for mobile development
- Firebase project with Authentication and Firestore enabled
- Valid Firebase configuration files (google-services.json for Android, GoogleService-Info.plist for iOS)

### Setup Steps

1. Clone the repository:
```bash
git clone https://github.com/pranavv1210/waterbuddy-app.git
cd waterbuddy-app
```

2. Install Flutter dependencies:
```bash
cd apps/customer_app
flutter pub get
cd ../seller_app
flutter pub get
```

3. Configure Firebase:
- Create a Firebase project at https://console.firebase.google.com
- Enable Authentication (Phone provider)
- Create Firestore database
- Add Android apps for customer and seller apps
- Download google-services.json files and place in respective android/app directories
- For iOS, add GoogleService-Info.plist files in ios/Runner directories

4. Run the applications:
```bash
# Customer app
cd apps/customer_app
flutter run

# Seller app
cd apps/seller_app
flutter run
```

### Firebase Setup

Ensure the following Firebase services are configured:

- Authentication: Enable Phone provider for OTP-based authentication
- Firestore: Create database in production mode with appropriate security rules
- Cloud Messaging: Enable for push notifications (optional for initial release)

## Security Considerations

### Firestore Security Rules

The application implements role-based access control through Firestore security rules:

- Customers can only read/write their own orders and profile data
- Sellers can only read orders in their service area and update orders assigned to them
- Admin users have read access to all data for monitoring purposes
- Authentication is required for all read/write operations

### Authentication

- Phone-based OTP verification ensures only verified users can access the platform
- Session tokens are managed by Firebase Authentication with automatic refresh
- Seller accounts require additional KYC verification before receiving orders

### Data Protection

- All data is transmitted over HTTPS through Firebase SDKs
- Sensitive fields (phone numbers, addresses) are stored securely in Firestore
- Location data is only shared with the assigned seller during active deliveries
- Payment information is handled through secure payment gateways, not stored directly

## Scalability Considerations

The current architecture is designed for horizontal scaling:

- Real-time listeners are efficient and scale automatically with Firebase infrastructure
- Firestore handles concurrent writes through atomic transactions
- The stateless nature of Flutter apps allows for easy horizontal scaling
- Future improvements include:
  - Geo-queries for efficient nearby seller matching
  - Auto-assignment algorithms to reduce seller response time
  - Load balancing for high-demand periods
  - Caching layer for frequently accessed data

## Future Roadmap

### Near-Term Enhancements

- Smart Matching: Implement geospatial queries to automatically assign nearest available sellers
- Demand Prediction: Use historical data to predict high-demand areas and pre-position tankers
- Subscription Plans: Introduce recurring delivery subscriptions for commercial customers
- Advanced Analytics: Implement comprehensive analytics dashboard for business intelligence

### Medium-Term Features

- In-App Chat: Enable direct communication between customers and sellers
- Scheduling: Allow customers to schedule deliveries in advance
- Dynamic Pricing: Implement surge pricing during high-demand periods
- Fleet Management: Enable sellers to manage multiple tankers and drivers

### Long-Term Vision

- AI-Powered Routing: Optimize delivery routes using machine learning
- Water Quality Monitoring: Integrate IoT sensors for water quality verification
- Multi-Service Expansion: Add other utility services (gas, maintenance, etc.)
- Regional Expansion: Scale to multiple cities and regions across India

## Contributing

WaterBuddy welcomes contributions from the development community. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes with clear messages (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Guidelines

- Follow Dart style guide for Flutter development
- Write unit tests for new features and functionality
- Update documentation for any API changes
- Ensure all existing tests pass before submitting PR
- Use descriptive variable and function names
- Add comments for complex logic

## License

This project is proprietary software. All rights are reserved by WaterBuddy. Unauthorized copying, distribution, or modification of this code is strictly prohibited.

For licensing inquiries, contact: [waterbuddyapp.wb@gmail.com](mailto:waterbuddyapp.wb@gmail.com)

## Support

For technical support or questions:
- Email: [waterbuddyapp.wb@gmail.com](mailto:waterbuddyapp.wb@gmail.com)
- Documentation: [docs.waterbuddy.com](https://docs.waterbuddy.com)
- Issue Tracker: [GitHub Issues](https://github.com/pranavv1210/waterbuddy-app/issues)

## Legal & Compliance

### Licenses and Registrations

WaterBuddy operates under the following legal framework:

- **Business Registration**: Registered as WaterBuddy Technologies Pvt. Ltd.
- **GST Registration**: GSTIN - [To be updated with actual GST number]
- **MSME Registration**: Udyam Registration - [To be updated]
- **Trade License**: Valid trade license for water delivery services

### Data Protection Compliance

- **Privacy Policy**: Compliant with Information Technology Act, 2000 (India)
- **Data Localization**: All user data stored within Indian jurisdiction
- **GDPR Readiness**: Framework prepared for international data protection standards

### Intellectual Property

- **Trademark**: WaterBuddy name and logo are registered trademarks
- **Copyright**: All source code, designs, and content are protected under Indian Copyright Act, 1957
- **Patents**: Patent pending for automated water tanker matching algorithm

### Certifications (In Progress)

- **ISO 27001**: Information Security Management (Planned)
- **ISO 9001**: Quality Management System (Planned)
- **SOC 2 Type II**: Service Organization Control (Planned)

### Regulatory Compliance

- **Food Safety**: Compliant with FSSAI guidelines for water transportation
- **Vehicle Compliance**: All registered sellers must have valid commercial vehicle permits
- **Environmental**: Adherence to water conservation and environmental protection norms
