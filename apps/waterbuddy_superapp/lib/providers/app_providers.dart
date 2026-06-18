import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../core/services/background/background_service.dart';

import '../core/auth/admin_access_service.dart';
import '../core/auth/app_role.dart';
import '../core/auth/role_session_service.dart';
import '../core/services/auth/auth_service.dart';
import '../core/services/location/driver_location_tracking_service.dart';
import '../core/services/location/seller_location_tracking_service.dart';
import '../core/services/orders/order_service.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/presentation/admin_auth_screen.dart';
import '../features/auth/presentation/consumer_auth_screen.dart';
import '../features/auth/presentation/consumer_login_screen.dart';
import '../features/auth/presentation/consumer_signup_screen.dart';
import '../features/auth/presentation/consumer_otp_screen.dart';
import '../features/auth/presentation/driver_onboarding_screen.dart';
import '../features/auth/presentation/driver_login_screen.dart';
import '../features/auth/presentation/driver_signup_screen.dart';
import '../features/auth/presentation/driver_otp_screen.dart';
import '../features/auth/presentation/password_reset_screen.dart';
import '../features/auth/presentation/seller_onboarding_screen.dart';
import '../features/auth/presentation/seller_login_screen.dart';
import '../features/auth/presentation/seller_signup_screen.dart';
import '../features/auth/presentation/unauthorized_screen.dart';
import '../features/driver/presentation/driver_dashboard_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/location_selection_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/orders/presentation/order_details_screen.dart';
import '../features/orders/presentation/orders_screen.dart';
import '../features/payments/presentation/payments_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/seller/presentation/seller_blocked_screen.dart';
import '../features/seller/presentation/seller_dashboard_screen.dart';
import '../features/seller/presentation/seller_waiting_screen.dart';
import '../features/settings/presentation/app_settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/tracking/presentation/order_complete_screen.dart';
import '../features/tracking/presentation/searching_tankers_screen.dart';
import '../features/tracking/presentation/tracking_screen.dart';
import '../models/order.dart' as app_order;
import '../models/order_offer.dart';
import '../models/system_settings.dart';
import '../models/tank_category.dart';
import '../routes/route_names.dart';
import '../widgets/main_shell.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final cloudFunctionsProvider =
    Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);
final adminAccessServiceProvider =
    Provider<AdminAccessService>((ref) => const AdminAccessService());
final roleSessionServiceProvider =
    Provider<RoleSessionService>((ref) => RoleSessionService());

// ── Background service ────────────────────────────────────────────────────────
final backgroundServiceProvider = Provider<BackgroundService>((ref) {
  final service = BackgroundService(
    firestore: ref.watch(firestoreProvider),
    orderService: ref.watch(orderServiceProvider),
  );
  service.attach();
  ref.onDispose(service.detach);
  return service;
});

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(adminAccessServiceProvider),
  ),
);

final sellerLocationTrackingServiceProvider =
    Provider<SellerLocationTrackingService>(
        (ref) => SellerLocationTrackingService(ref.watch(firestoreProvider)));
final driverLocationTrackingServiceProvider =
    Provider<DriverLocationTrackingService>(
        (ref) => DriverLocationTrackingService(ref.watch(firestoreProvider)));

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authServiceProvider)),
);
final orderServiceProvider =
    Provider<OrderService>((ref) => OrderService(ref.watch(firestoreProvider)));
final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authStateChanges());
final currentUserProvider =
    Provider<User?>((ref) => ref.watch(authStateProvider).value);

final selectedRoleProvider =
    StateNotifierProvider<SelectedRoleController, AppRole?>(
  (ref) =>
      SelectedRoleController(ref.watch(roleSessionServiceProvider))..restore(),
);

class SelectedRoleController extends StateNotifier<AppRole?> {
  SelectedRoleController(this._sessionService) : super(null);
  final RoleSessionService _sessionService;

  Future<void> restore() async =>
      state = await _sessionService.getSelectedRole();

  Future<void> set(AppRole role) async {
    state = role;
    await _sessionService.setSelectedRole(role);
  }

  Future<void> clear() async {
    state = null;
    await _sessionService.clear();
  }
}

final sellerVerificationStatusProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(authServiceProvider).getSellerVerificationStatus(user.uid);
});

final sellerCurrentLocationProvider = StreamProvider<GeoPoint?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('sellers')
      .doc(user.uid)
      .snapshots()
      .map((doc) {
    final location = doc.data()?['currentLocation'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return GeoPoint(lat, lng);
  });
});

class SellerOnlineController extends StateNotifier<bool> {
  SellerOnlineController(
      this._firestore, this._user, this._locationTrackingService)
      : super(false) {
    _watchSelf();
  }
  final FirebaseFirestore _firestore;
  final User? _user;
  final SellerLocationTrackingService _locationTrackingService;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _selfSub;

  void _watchSelf() {
    if (_user == null) return;
    _selfSub = _firestore
        .collection('sellers')
        .doc(_user.uid)
        .snapshots()
        .listen((doc) {
      state = doc.data()?['isOnline'] as bool? ?? false;
    });
  }

  Future<void> setOnline(bool value) async {
    if (_user == null) return;
    await _firestore.collection('sellers').doc(_user.uid).set({
      'uid': _user.uid,
      'isOnline': value,
      'isAvailable': value,
      'lastActiveAt': FieldValue.serverTimestamp(),
      if (!value) 'currentLocation': FieldValue.delete(),
    }, SetOptions(merge: true));
    if (value) {
      await _locationTrackingService.start(sellerId: _user.uid);
    } else {
      await _locationTrackingService.stop();
    }
  }

  @override
  void dispose() {
    _selfSub?.cancel();
    _locationTrackingService.stop();
    super.dispose();
  }
}

final sellerOnlineProvider =
    StateNotifierProvider<SellerOnlineController, bool>(
  (ref) => SellerOnlineController(
    ref.watch(firestoreProvider),
    ref.watch(currentUserProvider),
    ref.watch(sellerLocationTrackingServiceProvider),
  ),
);

class DriverOnlineController extends StateNotifier<bool> {
  DriverOnlineController(this._firestore, this._user, this._trackingService)
      : super(false) {
    _watchSelf();
  }
  final FirebaseFirestore _firestore;
  final User? _user;
  final DriverLocationTrackingService _trackingService;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _selfSub;

  void _watchSelf() {
    if (_user == null) return;
    _selfSub = _firestore
        .collection('drivers')
        .doc(_user.uid)
        .snapshots()
        .listen((doc) {
      state = doc.data()?['isOnline'] as bool? ?? false;
    });
  }

  Future<void> setOnline(bool value) async {
    if (_user == null) return;
    await _firestore.collection('drivers').doc(_user.uid).set({
      'uid': _user.uid,
      'isOnline': value,
      'lastActiveAt': FieldValue.serverTimestamp(),
      if (!value) 'currentLocation': FieldValue.delete(),
    }, SetOptions(merge: true));
    if (value) {
      await _trackingService.start(driverId: _user.uid);
    } else {
      await _trackingService.stop();
    }
  }

  @override
  void dispose() {
    _selfSub?.cancel();
    _trackingService.stop();
    super.dispose();
  }
}

final driverOnlineProvider =
    StateNotifierProvider<DriverOnlineController, bool>(
  (ref) => DriverOnlineController(
    ref.watch(firestoreProvider),
    ref.watch(currentUserProvider),
    ref.watch(driverLocationTrackingServiceProvider),
  ),
);

final onlineSellersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('sellers')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final location = data['currentLocation'] as Map<String, dynamic>?;
            return {
              'id': doc.id,
              'lat': (location?['latitude'] as num?)?.toDouble(),
              'lng': (location?['longitude'] as num?)?.toDouble(),
              'tankerCount': data['tankerCount'] as int? ?? 1,
            };
          }).toList());
});

final searchingOrdersProvider = StreamProvider<List<app_order.Order>>((ref) {
  final online = ref.watch(sellerOnlineProvider);
  if (!online) return Stream.value(const <app_order.Order>[]);

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(const <app_order.Order>[]);
  final settings = ref.watch(systemSettingsProvider).valueOrNull ??
      SystemSettings.defaults();
  final currentLocAsync = ref.watch(sellerCurrentLocationProvider);
  final onlineSellersAsync = ref.watch(onlineSellersProvider);

  if (currentLocAsync.isLoading || onlineSellersAsync.isLoading) {
    return Stream.value(const <app_order.Order>[]);
  }

  final currentLoc = currentLocAsync.value;
  final sellers = onlineSellersAsync.value ?? const <Map<String, dynamic>>[];
  if (currentLoc == null) return Stream.value(const <app_order.Order>[]);

  return ref.watch(orderServiceProvider).watchSearchingOrdersNear(
    latitude: currentLoc.latitude,
    longitude: currentLoc.longitude,
    radiusKm: settings.dispatchRadiusKm,
  ).map((orders) {
    return orders.where((order) {
      final orderLat = (order.location['latitude'] as num?)?.toDouble();
      final orderLng = (order.location['longitude'] as num?)?.toDouble();
      if (orderLat == null || orderLng == null) return false;

      final currentDistance = Geolocator.distanceBetween(
          currentLoc.latitude, currentLoc.longitude, orderLat, orderLng);
      if (currentDistance > settings.dispatchRadiusKm * 1000) return false;

      final sellerDistances = sellers
          .map((seller) {
            final lat = seller['lat'] as double?;
            final lng = seller['lng'] as double?;
            if (lat == null || lng == null) return null;
            return {
              'id': seller['id'] as String,
              'distance':
                  Geolocator.distanceBetween(lat, lng, orderLat, orderLng),
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) =>
            (a['distance'] as double).compareTo(b['distance'] as double));

      final top5Ids = sellerDistances.take(5).map((e) => e['id']).toSet();
      return top5Ids.contains(currentUser.uid);
    }).toList();
  });
});

final sellerPendingOffersProvider = StreamProvider<List<OrderOffer>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return Stream.value(const <OrderOffer>[]);

  return ref
      .watch(firestoreProvider)
      .collection('order_offers')
      .where('sellerId', isEqualTo: currentUser.uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .asyncMap((snapshot) async {
    final firestore = ref.read(firestoreProvider);
    final offers = <OrderOffer>[];
    for (final doc in snapshot.docs) {
      final orderId = (doc.data()['orderId'] ?? '').toString();
      if (orderId.isEmpty) continue;
      final orderDoc = await firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) continue;
      offers.add(
        OrderOffer.fromDocument(
          doc,
          order: app_order.Order.fromDocument(orderDoc),
        ),
      );
    }
    offers.sort((a, b) => a.expiresAt == null || b.expiresAt == null
        ? 0
        : a.expiresAt!.compareTo(b.expiresAt!));
    return offers;
  });
});

final activeOrderProvider = StreamProvider<app_order.Order?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(orderServiceProvider)
      .watchCustomerOrders(user.uid)
      .map((orders) {
    for (final order in orders) {
      if (_isActiveOrderStatus(order.status)) {
        return order;
      }
    }
    return null;
  });
});

final sellerActiveOrdersProvider = StreamProvider<List<app_order.Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <app_order.Order>[]);
  return ref
      .watch(orderServiceProvider)
      .watchSellerOrders(user.uid)
      .map((orders) {
    return orders.where((o) => _isActiveOrderStatus(o.status)).toList();
  });
});

final driverAssignedOrdersProvider =
    StreamProvider<List<app_order.Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <app_order.Order>[]);
  return ref
      .watch(orderServiceProvider)
      .watchDriverOrders(user.uid)
      .map((orders) {
    return orders.where((o) => _isActiveOrderStatus(o.status)).toList();
  });
});

bool _isActiveOrderStatus(String status) {
  return const {
    'SEARCHING',
    'OFFER_SENT',
    'ACCEPTED',
    'ASSIGNED',
    'DRIVER_ASSIGNED',
    'EN_ROUTE',
    'ON_THE_WAY',
    'ARRIVED',
    'DELIVERING',
  }.contains(status);
}

final usersProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  (ref) => ref.watch(firestoreProvider).collection('users').snapshots(),
);
final sellersProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  (ref) => ref.watch(firestoreProvider).collection('sellers').snapshots(),
);
final driversProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  (ref) => ref.watch(firestoreProvider).collection('drivers').snapshots(),
);
final allOrdersProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  (ref) => ref.watch(firestoreProvider).collection('orders').snapshots(),
);

final currentSellerProfileProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('sellers')
      .doc(user.uid)
      .snapshots();
});

final currentDriverProfileProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .collection('drivers')
      .doc(user.uid)
      .snapshots();
});

final sellerCompletedOrdersProvider =
    StreamProvider<List<app_order.Order>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <app_order.Order>[]);
  return ref.watch(orderServiceProvider).watchSellerOrders(user.uid).map(
      (orders) => orders
          .where((order) =>
              order.status == 'COMPLETED' || order.status == 'DELIVERED')
          .toList());
});

final tankCategoriesProvider = StreamProvider<List<TankCategory>>((ref) {
  debugPrint(
    'TANK_CATEGORIES: Starting stream from collection=tank_categories',
  );
  return ref
      .watch(firestoreProvider)
      .collection('tank_categories')
      .snapshots()
      .map(
    (snapshot) {
      debugPrint(
        'TANK_CATEGORIES: Snapshot received with ${snapshot.docs.length} docs',
      );
      for (final doc in snapshot.docs) {
        debugPrint(
          'TANK_CATEGORIES: doc=$doc id=${doc.id} data=${doc.data()}',
        );
      }
      final categories = snapshot.docs.map(TankCategory.fromDocument).toList()
        ..sort((a, b) => a.litres.compareTo(b.litres));
      debugPrint(
        'TANK_CATEGORIES: Deserialized ${categories.length} categories: '
        '${categories.map((c) => "${c.displayName}(id=${c.id}, active=${c.active})").join(', ')}',
      );
      return categories;
    },
  );
});

/// Synchronous provider that filters active categories from the stream.
/// Must NOT be a StreamProvider itself to avoid async-value confusion.
final activeTankCategoriesProvider = Provider<List<TankCategory>>((ref) {
  final categoriesAsync = ref.watch(tankCategoriesProvider);
  final categories = categoriesAsync.valueOrNull ?? const [];
  final active = categories.where((category) => category.active).toList();
  debugPrint(
    'ACTIVE_TANK_CATEGORIES: ${active.length} active out of ${categories.length} total: '
    '${active.map((c) => "${c.displayName}(id=${c.id}, active=${c.active}, isActive=${c.active})").join(', ')}',
  );
  return active;
});

final platformConfigProvider =
    StreamProvider<DocumentSnapshot<Map<String, dynamic>>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('system_settings')
      .doc('config')
      .snapshots(),
);

final systemSettingsProvider = StreamProvider<SystemSettings>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('system_settings')
      .doc('config')
      .snapshots()
      .map((doc) => SystemSettings.fromMap(doc.data()));
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      FocusManager.instance.primaryFocus?.unfocus();
      final auth = ref.read(authStateProvider);
      final user = auth.value;
      final role = ref.read(selectedRoleProvider);
      final path = state.matchedLocation;
      final signedIn = user != null;

      if (path == RouteNames.splash) return null;
      final authPaths = <String>{
        RouteNames.authConsumer,
        RouteNames.authConsumerLogin,
        RouteNames.authConsumerSignup,
        RouteNames.authConsumerOtp,
        RouteNames.authSeller,
        RouteNames.authSellerLogin,
        RouteNames.authSellerSignup,
        RouteNames.authDriver,
        RouteNames.authDriverLogin,
        RouteNames.authDriverSignup,
        RouteNames.authDriverOtp,
        RouteNames.authAdmin,
        RouteNames.passwordReset,
      };

      if (!signedIn &&
          path != RouteNames.roleSelection &&
          !authPaths.contains(path)) {
        return RouteNames.roleSelection;
      }
      if (!signedIn) return null;
      if (role == null) return RouteNames.roleSelection;

      if (path == RouteNames.roleSelection || authPaths.contains(path)) {
        switch (role) {
          case AppRole.consumer:
            return RouteNames.consumerHome;
          case AppRole.seller:
            if (user.email == AuthService.testSellerEmail) {
              return RouteNames.sellerDashboard;
            }
            final verification =
                ref.read(sellerVerificationStatusProvider).value ?? 'pending';
            if (verification == 'approved') return RouteNames.sellerDashboard;
            if (verification == 'pending') return RouteNames.sellerWaiting;
            return RouteNames.sellerBlocked;
          case AppRole.driver:
            return RouteNames.driverDashboard;
          case AppRole.admin:
            return RouteNames.adminDashboard;
        }
      }

      if (path.startsWith('/admin') && role != AppRole.admin) {
        return RouteNames.unauthorized;
      }
      if (path.startsWith('/seller')) {
        if (role != AppRole.seller) return RouteNames.unauthorized;
        if (user.email == AuthService.testSellerEmail) {
          return null;
        }
        final verification =
            ref.read(sellerVerificationStatusProvider).value ?? 'pending';
        if (verification == 'approved' && path != RouteNames.sellerDashboard) {
          return RouteNames.sellerDashboard;
        }
        if (verification == 'pending' && path != RouteNames.sellerWaiting) {
          return RouteNames.sellerWaiting;
        }
        if ((verification == 'rejected' || verification == 'suspended') &&
            path != RouteNames.sellerBlocked) {
          return RouteNames.sellerBlocked;
        }
      }
      if (path.startsWith('/driver') && role != AppRole.driver) {
        return RouteNames.unauthorized;
      }
      if (path.startsWith('/consumer') && role != AppRole.consumer) {
        return RouteNames.unauthorized;
      }
      return null;
    },
    routes: [
      GoRoute(
          path: RouteNames.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: RouteNames.roleSelection,
          builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(
          path: RouteNames.authConsumer,
          builder: (_, __) => const ConsumerAuthLandingScreen()),
      GoRoute(
          path: RouteNames.authConsumerLogin,
          builder: (_, __) => const ConsumerLoginScreen()),
      GoRoute(
          path: RouteNames.authConsumerSignup,
          builder: (_, __) => const ConsumerSignupScreen()),
      GoRoute(
          path: RouteNames.authConsumerOtp,
          builder: (_, __) => const ConsumerOtpScreen()),
      GoRoute(
          path: RouteNames.authSeller,
          builder: (_, __) => const SellerAuthLandingScreen()),
      GoRoute(
          path: RouteNames.authSellerLogin,
          builder: (_, __) => const SellerLoginScreen()),
      GoRoute(
          path: RouteNames.authSellerSignup,
          builder: (_, __) => const SellerSignupScreen()),
      GoRoute(
          path: RouteNames.authDriver,
          builder: (_, __) => const DriverAuthLandingScreen()),
      GoRoute(
          path: RouteNames.authDriverLogin,
          builder: (_, __) => const DriverLoginScreen()),
      GoRoute(
          path: RouteNames.authDriverSignup,
          builder: (_, __) => const DriverSignupScreen()),
      GoRoute(
          path: RouteNames.authDriverOtp,
          builder: (_, __) => const DriverOtpScreen()),
      GoRoute(
          path: RouteNames.authAdmin,
          builder: (_, __) => const AdminAuthScreen()),
      GoRoute(
          path: RouteNames.passwordReset,
          builder: (_, __) => const PasswordResetScreen()),
      GoRoute(
          path: RouteNames.sellerDashboard,
          builder: (_, __) => const SellerDashboardScreen()),
      GoRoute(
          path: RouteNames.sellerWaiting,
          builder: (_, __) => const SellerWaitingScreen()),
      GoRoute(
          path: RouteNames.sellerBlocked,
          builder: (_, __) => const SellerBlockedScreen()),
      GoRoute(
          path: RouteNames.driverDashboard,
          builder: (_, __) => const DriverDashboardScreen()),
      GoRoute(
          path: RouteNames.adminDashboard,
          builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(
          path: RouteNames.unauthorized,
          builder: (_, __) => const UnauthorizedScreen()),
      GoRoute(
          path: RouteNames.searching,
          builder: (_, __) => const SearchingTankersScreen()),
      GoRoute(
          path: RouteNames.tracking,
          builder: (_, __) => const TrackingScreen()),
      GoRoute(
          path: RouteNames.orderComplete,
          builder: (_, __) => const OrderCompleteScreen()),
      GoRoute(
          path: RouteNames.orderDetails,
          builder: (_, __) => const OrderDetailsScreen()),
      GoRoute(
          path: RouteNames.payments,
          builder: (_, __) => const PaymentsScreen()),
      GoRoute(
          path: RouteNames.appSettings,
          builder: (_, __) => const AppSettingsScreen()),
      GoRoute(
        path: RouteNames.locationSelection,
        builder: (_, state) =>
            LocationSelectionScreen(pickupAddress: state.extra as String?),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            MainShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(
              path: RouteNames.consumerHome,
              builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: RouteNames.consumerOrders,
              builder: (_, __) => const OrdersScreen()),
          GoRoute(
              path: RouteNames.consumerProfile,
              builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});
