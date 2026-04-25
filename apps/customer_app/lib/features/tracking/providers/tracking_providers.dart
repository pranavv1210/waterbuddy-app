import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/orders/order_service.dart';
import '../../../models/order.dart';
import '../../../providers/app_providers.dart';
import '../data/mock_tracking_repository.dart';
import '../models/assigned_order_tracking.dart';

class TrackingController extends StateNotifier<TrackingState> {
  TrackingController(this._orderService) : super(const TrackingState());

  final OrderService _orderService;

  void startWatchingOrder(String orderId) {
    state = state.copyWith(orderId: orderId, isLoading: true, clearError: true);

    _orderService.watchOrder(orderId).listen(
      (order) {
        if (order != null) {
          debugPrint('Tracking order status: ${order.status}');
          debugPrint('Tracking location: ${order.tracking?.lat}, ${order.tracking?.lng}');
          state = state.copyWith(
            orderStatus: order.status,
            tracking: order.tracking,
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

class TrackingState {
  const TrackingState({
    this.isLoading = false,
    this.orderId,
    this.orderStatus = 'ASSIGNED',
    this.tracking,
    this.errorMessage,
  });

  final bool isLoading;
  final String? orderId;
  final String orderStatus;
  final TrackingData? tracking;
  final String? errorMessage;

  TrackingState copyWith({
    bool? isLoading,
    String? orderId,
    String? orderStatus,
    TrackingData? tracking,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrackingState(
      isLoading: isLoading ?? this.isLoading,
      orderId: orderId ?? this.orderId,
      orderStatus: orderStatus ?? this.orderStatus,
      tracking: tracking ?? this.tracking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return TrackingController(orderService);
});

final trackingRepositoryProvider = Provider<MockTrackingRepository>(
  (ref) => MockTrackingRepository(),
);

final assignedOrderTrackingProvider = FutureProvider<AssignedOrderTracking>(
  (ref) => ref.watch(trackingRepositoryProvider).getAssignedOrder(),
);

