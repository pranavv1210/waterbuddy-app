import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/auth/auth_service.dart';
import '../core/services/orders/order_service.dart';
import '../core/services/seller/seller_availability_service.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/auth/otp_screen.dart';
import '../features/earnings/presentation/earnings_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import '../routes/route_names.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authServiceProvider)),
);

final orderServiceProvider =
    Provider<OrderService>((ref) => OrderService(ref.watch(firestoreProvider)));

final sellerAvailabilityServiceProvider = Provider<SellerAvailabilityService>(
  (ref) => SellerAvailabilityService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.auth,
    routes: [
      GoRoute(
        path: RouteNames.auth,
        builder: (_, __) => const AuthGate(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (_, __) => const OtpScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.orders,
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.earnings,
        builder: (_, __) => const EarningsScreen(),
      ),
      GoRoute(
        path: RouteNames.tracking,
        builder: (_, __) => const TrackingScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  );
});
