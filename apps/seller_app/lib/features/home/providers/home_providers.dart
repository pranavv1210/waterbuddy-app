import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../profile/data/seller_availability_service.dart';
import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../data/mock_seller_dashboard_repository.dart';
import '../models/seller_dashboard.dart';

final sellerDashboardRepositoryProvider =
    Provider<MockSellerDashboardRepository>(
  (ref) => const MockSellerDashboardRepository(),
);

final sellerDashboardProvider = FutureProvider<SellerDashboard>((ref) {
  return ref.watch(sellerDashboardRepositoryProvider).fetchDashboard();
});

class SellerAvailabilityController extends StateNotifier<bool> {
  SellerAvailabilityController(this._auth, this._availabilityService)
      : super(false) {
    _init();
  }

  final FirebaseAuth _auth;
  final SellerAvailabilityService _availabilityService;

  void _init() {
    final user = _auth.currentUser;
    if (user != null) {
      _availabilityService.watchAvailability(user.uid).listen((isOnline) {
        state = isOnline;
      });
    }
  }

  Future<void> setOnline(bool value) async {
    state = value;
    await _availabilityService.setAvailability(value);
  }
}

final sellerAvailabilityProvider =
    StateNotifierProvider<SellerAvailabilityController, bool>(
  (ref) => SellerAvailabilityController(
    ref.watch(firebaseAuthProvider),
    ref.watch(sellerAvailabilityServiceProvider),
  ),
);

final sellerLocationProvider = StreamProvider.autoDispose((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final sellerId = auth.currentUser?.uid;
  if (sellerId == null) return const Stream.empty();

  return ref.watch(firestoreProvider).collection('sellers').doc(sellerId).snapshots().map((doc) {
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return (data['latitude'] as double?, data['longitude'] as double?);
  });
});

final onlineSellersProvider = StreamProvider.autoDispose((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('sellers')
      .where('isOnline', isEqualTo: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'lat': data['latitude'] as double?,
              'lng': data['longitude'] as double?,
            };
          }).toList());
});

final searchingOrdersProvider = StreamProvider.autoDispose((ref) {
  final isOnline = ref.watch(sellerAvailabilityProvider);

  if (!isOnline) {
    return Stream.value(<Order>[]);
  }

  final locationAsync = ref.watch(sellerLocationProvider);
  final onlineSellersAsync = ref.watch(onlineSellersProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final currentSellerId = auth.currentUser?.uid;

  if (currentSellerId == null) return Stream.value(<Order>[]);

  // We need both the current seller's location and the list of all online sellers
  if (locationAsync.isLoading || onlineSellersAsync.isLoading) {
    return const Stream.empty();
  }

  final location = locationAsync.value;
  final allSellers = onlineSellersAsync.value ?? [];

  if (location == null || location.$1 == null || location.$2 == null) {
    debugPrint('Error: Current seller location missing');
    return Stream.value(<Order>[]);
  }

  final sellerLat = location.$1!;
  final sellerLng = location.$2!;

  return ref.watch(orderServiceProvider).watchSearchingOrders().map((orders) {
    return orders.where((order) {
      final orderLat = order.location['latitude'] as double?;
      final orderLng = order.location['longitude'] as double?;

      if (orderLat == null || orderLng == null) return false;

      // 1. Calculate distance for this seller
      final currentSellerDistance = Geolocator.distanceBetween(
        sellerLat,
        sellerLng,
        orderLat,
        orderLng,
      );

      // 2. Initial distance check (5km) - existing rule
      if (currentSellerDistance > 5000) return false;

      // 3. COMPETITIVE DISPATCH: Is this seller in the top 5 closest?
      // First, calculate distances for ALL online sellers to this specific order
      final sellerDistances = allSellers
          .map((s) {
            final lat = s['lat'] as double?;
            final lng = s['lng'] as double?;
            if (lat == null || lng == null) return null;

            return {
              'id': s['id'] as String,
              'distance': Geolocator.distanceBetween(lat, lng, orderLat, orderLng),
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

      // Sort sellers by distance to this order
      sellerDistances.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      // Get top 5 closest sellers
      final topSellerIds = sellerDistances.take(5).map((s) => s['id']).toList();

      // Only show if current seller is in that top list
      return topSellerIds.contains(currentSellerId);
    }).toList();
  });
});

final activeOrdersProvider = StreamProvider.autoDispose((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final sellerId = auth.currentUser?.uid;

  if (sellerId == null) {
    return Stream.value(<Order>[]);
  }

  final orderService = ref.watch(orderServiceProvider);
  return orderService.watchSellerOrders(sellerId).map((orders) {
    return orders.where((order) {
      return order.status == 'ASSIGNED' || order.status == 'ON_THE_WAY';
    }).toList();
  });
});
