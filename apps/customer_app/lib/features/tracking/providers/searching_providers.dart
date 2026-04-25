import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/orders/order_service.dart';
import '../../../providers/app_providers.dart';
import '../models/searching_tankers_state.dart';

class SearchingState {
  const SearchingState({
    this.isLoading = false,
    this.orderId,
    this.orderStatus = 'SEARCHING',
    this.errorMessage,
  });

  final bool isLoading;
  final String? orderId;
  final String orderStatus;
  final String? errorMessage;

  SearchingState copyWith({
    bool? isLoading,
    String? orderId,
    String? orderStatus,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchingState(
      isLoading: isLoading ?? this.isLoading,
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class SearchingController extends StateNotifier<SearchingState> {
  SearchingController(this._orderService)
      : super(const SearchingState());

  final OrderService _orderService;

  void startWatchingOrder(String orderId) {
    state = state.copyWith(orderId: orderId, isLoading: true, clearError: true);

    _orderService.watchOrder(orderId).listen(
      (order) {
        if (order != null) {
          state = state.copyWith(
            orderStatus: order.status,
            isLoading: false,
            clearError: true,
          );
        }
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final searchingControllerProvider =
    StateNotifierProvider<SearchingController, SearchingState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return SearchingController(orderService);
});

final searchingTankersProvider = Provider<SearchingTankersState>((ref) {
  // Return mock state for now - will be updated with real order data
  return const SearchingTankersState(
    title: 'Finding nearby tankers...',
    userAvatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAXWUaWZFNV98FIY16-sdNiUnUEhXz1-cluIthuk7cllfLy3FWue5hFUcn0eVWzu40Z-8mfa2SQDWMtmTm_UpwrRXh7bIykblaserGx25nvMHWQoybNlyc5jTwoBrKcxKwHORSOSt25KsIfZFgZG6ezST5I_GvK60QZRRwRYIgWTE3qOT8pGYb1IktY0g4pnMaY0DQQHz1UfZMGZoXcbLQLxZkYadOVr5VvUtP8y1dIBNt9cQ8hXSpL7Lud4lfnHEat_gwFD4nT9A0',
    mapImageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAE1_PMH3SRT0O6ll8cWGfmgYpy0eYo57aFcoLss3RFUD57xz1d_xpop0iiPMHqrjLK94QJDoueNzrV2PKCByqgKc59f50x-3qArfyzXpM0KXTZ8VFjETJI785GZiNSjbL_s26MujVsNmYB6AFenfbAWuTUZN88q91TBqUgzgmBVkipUUX-2guNJMDxrisjMGh8H8uYB51WFrf3vKLOsHGXmLvStkDoNVam5IxS7cUaffbXJ4ARbTthhVT-IkagXq5iYZiGuMeuSTs',
    mapLocationLabel: 'San Francisco',
    vehicleDistances: ['4.2km', '1.8km'],
    scanTitle: 'Scanning Grid B-12',
    scanSubtitle: 'Identifying 4 active vehicles nearby',
    connectionLabel: 'Connecting to server...',
    connectionBadge: 'ENCRYPTED',
    footerMessage:
        'Please wait while we secure the best pricing for your delivery location.',
    cancelLabel: 'Cancel Search',
  );
});
