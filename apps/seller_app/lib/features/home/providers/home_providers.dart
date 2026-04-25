import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/seller/seller_availability_service.dart';
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

final searchingOrdersProvider = StreamProvider.autoDispose((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.watchSearchingOrders();
});
