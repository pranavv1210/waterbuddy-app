# WaterBuddy

On-demand water tanker delivery platform connecting customers with verified water suppliers in real-time.

## Overview

WaterBuddy is a two-sided marketplace platform that revolutionizes water delivery services in India. The platform enables customers to book water tankers instantly through a mobile application, while connecting them with nearby verified tanker providers (sellers). Built on a real-time architecture, WaterBuddy eliminates the inefficiencies of traditional water booking through automated matching, live tracking, and transparent pricing.

The system operates as a complete ecosystem comprising a customer mobile app, a seller/partner mobile app, and an administrative web dashboard. All components are synchronized through Firebase's real-time database, ensuring instant updates across the platform.

## Problem Statement

Traditional water delivery in India faces significant operational challenges:

- Manual Coordination: Customers must call multiple suppliers to check availability and negotiate prices, leading to time-consuming processes and uncertainty.
- Price Opacity: Lack of standardized pricing creates confusion and potential overcharging, with customers unable to compare rates across providers.
- Unreliable Delivery: No guaranteed delivery windows or real-time tracking, leaving customers uncertain about arrival times.
- Limited Visibility: Customers cannot verify supplier credentials or track delivery progress, reducing trust in the service.
- Operational Inefficiency: Suppliers struggle with manual order management, leading to missed opportunities and poor resource utilization.

## Solution

WaterBuddy addresses these challenges through a comprehensive digital platform:

- Automated Booking: Customers can book water tankers in seconds through the mobile app, eliminating manual calls and negotiations.
- Transparent Pricing: Standardized rates based on tank size and distance are displayed upfront, ensuring price transparency and fairness.
- Real-Time Tracking: GPS-enabled tracking allows customers to monitor their delivery in real-time, providing accurate arrival estimates.
- Verified Suppliers: All sellers undergo KYC verification and quality checks, ensuring reliable service delivery.
- Smart Matching: The system automatically matches customers with nearby available sellers, optimizing delivery times and reducing wait times.
- Digital Payments: Multiple payment options including Cash on Delivery and online payments provide flexibility and convenience.

## Key Features

### Customer Mobile App

- Instant Booking: Book water tankers with a few taps, selecting tank size and delivery location
- Tank Size Selection: Choose from multiple tank capacities (500L, 1000L, 2000L, 5000L) based on requirements
- Real-Time Tracking: Monitor delivery progress with live GPS tracking and estimated arrival times
- Payment Options: Pay securely via Cash on Delivery or online payment methods
- Order History: View past orders, track current orders, and manage bookings
- Seller Ratings: Rate and review sellers based on delivery experience

### Seller Mobile App

- Availability Toggle: Go online/offline to control order availability based on schedule
- Real-Time Order Alerts: Receive instant notifications when orders are available in the service area
- Order Acceptance System: Review order details and accept or decline requests based on availability
- Delivery Status Updates: Update order status through delivery stages (Assigned, On the Way, Delivered)
- Earnings Dashboard: Track daily earnings, completed orders, and performance metrics
- Location Tracking: Automatic GPS updates provide customers with real-time delivery tracking

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
