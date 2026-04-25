import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  SellerAvailabilityController() : super(true);

  void setOnline(bool value) => state = value;
}

final sellerAvailabilityProvider =
    StateNotifierProvider<SellerAvailabilityController, bool>(
  (ref) => SellerAvailabilityController(),
);

final searchingOrdersProvider = StreamProvider.autoDispose((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.watchSearchingOrders();
});
