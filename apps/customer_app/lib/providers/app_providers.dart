import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart' as app_order;
import '../core/services/auth/auth_service.dart';
import '../core/services/orders/order_service.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/orders/presentation/order_details_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/payments/presentation/payments_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/tracking/presentation/order_complete_screen.dart';
import '../features/tracking/presentation/searching_tankers_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import '../routes/route_names.dart';
import '../widgets/main_shell.dart';

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

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final activeOrderProvider = StreamProvider<app_order.Order?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);

  return ref.watch(orderServiceProvider).watchCustomerOrders(user.uid).map((orders) {
    // Find first order that is NOT in a terminal state
    try {
      return orders.firstWhere((o) {
        if (o.status == 'ASSIGNED' || o.status == 'ON_THE_WAY') return true;
        if (o.status == 'SEARCHING') {
          if (o.createdAt == null) return true; // Just created, waiting for server timestamp
          final diff = DateTime.now().difference(o.createdAt!.toDate());
          if (diff.inMinutes < 2) return true;
        }
        return false;
      });
    } catch (_) {
      return null;
    }
  });
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      // ── Standalone screens (no nav bar) ────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        builder: (_, __) => const AuthGate(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (_, __) => const OtpScreen(),
      ),
      GoRoute(
        path: RouteNames.searching,
        builder: (_, __) => const SearchingTankersScreen(),
      ),
      GoRoute(
        path: RouteNames.tracking,
        builder: (_, __) => const TrackingScreen(),
      ),
      GoRoute(
        path: RouteNames.orderComplete,
        builder: (_, __) => const OrderCompleteScreen(),
      ),
      GoRoute(
        path: RouteNames.orderDetails,
        builder: (_, __) => const OrderDetailsScreen(),
      ),
      GoRoute(
        path: RouteNames.payments,
        builder: (_, __) => const PaymentsScreen(),
      ),

      // ── Main tabs wrapped with bottom nav bar ───────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: RouteNames.orders,
            builder: (_, __) => const OrdersScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
