import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/orders/order_service.dart';
import '../../../models/order.dart' as app_order;
import '../../../providers/app_providers.dart';
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
  final app_order.TrackingData? tracking;
  final String? errorMessage;

  TrackingState copyWith({
    bool? isLoading,
    String? orderId,
    String? orderStatus,
    app_order.TrackingData? tracking,
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

final orderStreamProvider = StreamProvider.family<app_order.Order?, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).watchOrder(orderId);
});

final sellerFutureProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, sellerId) async {
  final firestore = FirebaseFirestore.instance;
  final doc = await firestore.collection('sellers').doc(sellerId).get();
  return doc.data();
});

final assignedOrderTrackingProvider = FutureProvider.autoDispose<AssignedOrderTracking>((ref) async {
  final trackingState = ref.watch(trackingControllerProvider);
  final orderId = trackingState.orderId;
  
  if (orderId == null) throw Exception('No orderId provided');
  
  final orderAsync = ref.watch(orderStreamProvider(orderId));
  final order = orderAsync.value;
  
  if (order == null) {
    throw Exception('Order not found or still loading');
  }

  if (order.sellerId == null) {
    throw Exception('No seller assigned yet');
  }

  final sellerAsync = ref.watch(sellerFutureProvider(order.sellerId!));
  final sellerData = sellerAsync.value;

  if (sellerData == null) {
    throw Exception('Seller data not found');
  }

  // Map real data to UI model
  return AssignedOrderTracking(
    brandName: 'WaterBuddy',
    screenTitle: 'Tracking Order',
    userAvatarUrl: '', // Default placeholder
    mapImageUrl: '',
    cityLabel: 'Your Location',
    liveTrackingLabel: 'LIVE',
    orderId: orderId.substring(0, 8).toUpperCase(),
    truckBadgeLabel: 'Water Tanker',
    estimatedArrivalClock: '12:45',
    estimatedArrivalLabel: 'Estimated Arrival',
    estimatedArrival: '15 mins',
    distanceLabel: '2.4 km',
    statusTitle: 'Driver Assigned',
    statusSubtitle: 'Heading to pick up your water',
    driver: DriverAssignment(
      name: sellerData['name'] ?? 'Unknown Driver',
      roleLabel: 'Verified Partner',
      avatarUrl: sellerData['photoUrl'] ?? '',
      ratingLabel: (sellerData['rating'] ?? 4.5).toString(),
      idLabel: 'ID: ${order.sellerId!.substring(0, 6)}',
      deliveriesLabel: '${sellerData['totalOrders'] ?? 100}+ Deliveries',
      phoneNumber: sellerData['phone'] ?? '',
    ),
    vehicle: VehicleAssignment(
      typeLabel: sellerData['vehicleType'] ?? 'Standard Tanker',
      plateLabel: sellerData['vehiclePlate'] ?? 'KA 01 WB 2026',
      imageUrl: '',
      capacityLabel: '${order.tankSize}L',
    ),
    orderSummary: OrderSummary(
      amountLabel: 'COD',
      description: 'Payment on delivery',
      ctaLabel: 'View Details',
    ),
    navItems: [
      const TrackingNavItem(id: 'home', label: 'Home', iconKey: 'home'),
      const TrackingNavItem(id: 'history', label: 'History', iconKey: 'history'),
      const TrackingNavItem(id: 'book', label: 'Tracking', iconKey: 'water_drop'),
      const TrackingNavItem(id: 'profile', label: 'Profile', iconKey: 'person'),
    ],
  );
});

