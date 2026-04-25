import 'dart:async';
import 'package:flutter/foundation.dart';
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
    this.hasTimedOut = false,
  });

  final bool isLoading;
  final String? orderId;
  final String orderStatus;
  final String? errorMessage;
  final bool hasTimedOut;

  SearchingState copyWith({
    bool? isLoading,
    String? orderId,
    String? orderStatus,
    String? errorMessage,
    bool clearError = false,
    bool? hasTimedOut,
  }) {
    return SearchingState(
      isLoading: isLoading ?? this.isLoading,
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasTimedOut: hasTimedOut ?? this.hasTimedOut,
    );
  }
}

class SearchingController extends StateNotifier<SearchingState> {
  SearchingController(this._orderService)
      : super(const SearchingState());

  final OrderService _orderService;
  Timer? _timeoutTimer;
  StreamSubscription? _orderSubscription;
  static const Duration _timeoutDuration = Duration(seconds: 45);

  void startWatchingOrder(String orderId) {
    state = state.copyWith(
      orderId: orderId,
      isLoading: true,
      clearError: true,
      hasTimedOut: false,
    );

    // Cancel any existing timer and subscription
    _timeoutTimer?.cancel();
    _orderSubscription?.cancel();

    // Start timeout timer
    _timeoutTimer = Timer(_timeoutDuration, () {
      debugPrint('Order timeout reached for order: $orderId');
      _handleTimeout(orderId);
    });

    // Watch order status
    _orderSubscription = _orderService.watchOrder(orderId).listen(
      (order) {
        if (order != null) {
          debugPrint('Order status updated: ${order.status}');
          
          // Cancel timer if order is no longer searching
          if (order.status != 'SEARCHING') {
            _timeoutTimer?.cancel();
          }

          state = state.copyWith(
            orderStatus: order.status,
            isLoading: false,
            clearError: true,
          );
        }
      },
      onError: (error) {
        _timeoutTimer?.cancel();
        state = state.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        );
      },
    );
  }

  Future<void> _handleTimeout(String orderId) async {
    try {
      // Cancel the order in Firestore
      await _orderService.updateOrderStatus(orderId, 'CANCELLED');
      debugPrint('Order cancelled due to timeout: $orderId');
      
      state = state.copyWith(
        orderStatus: 'CANCELLED',
        isLoading: false,
        hasTimedOut: true,
      );
    } catch (e) {
      debugPrint('Error cancelling order on timeout: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to cancel order: $e',
        hasTimedOut: true,
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
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
