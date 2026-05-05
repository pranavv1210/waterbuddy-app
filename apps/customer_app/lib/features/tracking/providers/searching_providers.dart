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
  static const Duration _timeoutDuration = Duration(seconds: 60);

  void startWatchingOrder(String orderId) {
    state = state.copyWith(
      orderId: orderId,
      isLoading: true,
      clearError: true,
      hasTimedOut: false,
      orderStatus: 'SEARCHING',
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
  return const SearchingTankersState(
    title: 'Finding nearby tankers...',
    userAvatarUrl: '', // Will use default icon if empty
    mapImageUrl: '',
    mapLocationLabel: 'Detecting Location',
    vehicleDistances: ['1.2km', '2.5km'],
    scanTitle: 'Searching...',
    scanSubtitle: 'Broadcasting order to nearby tankers',
    connectionLabel: 'Real-time Signal',
    connectionBadge: 'ACTIVE',
    footerMessage:
        'Please wait while a tanker accepts your order. This usually takes less than a minute.',
    cancelLabel: 'Cancel Booking',
  );
});
