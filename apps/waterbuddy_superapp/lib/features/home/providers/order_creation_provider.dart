import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/orders/order_service.dart';
import '../../../providers/app_providers.dart';

class OrderCreationState {
  const OrderCreationState({
    this.isLoading = false,
    this.orderId,
    this.errorMessage,
  });

  final bool isLoading;
  final String? orderId;
  final String? errorMessage;

  OrderCreationState copyWith({
    bool? isLoading,
    String? orderId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderCreationState(
      isLoading: isLoading ?? this.isLoading,
      orderId: orderId ?? this.orderId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class OrderCreationController extends StateNotifier<OrderCreationState> {
  OrderCreationController(this._orderService, this._auth, this._firestore)
      : super(const OrderCreationState());

  final OrderService _orderService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<String?> createOrder({
    required num tankSize,
    required String tankLabel,
    required Map<String, dynamic> location,
    String paymentType = 'COD',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'User not authenticated. Please login again.',
        );
        return null;
      }

      // Get user details from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final customerName = userDoc.data()?['name'] ?? 'Customer';
      final customerPhone = user.phoneNumber ?? userDoc.data()?['phone'] ?? '';

      final orderId = await _orderService.createOrder(
        customerId: user.uid,
        customerName: customerName,
        customerPhone: customerPhone,
        tankSize: tankSize,
        tankLabel: tankLabel,
        location: location,
        paymentType: paymentType,
      );

      state = state.copyWith(
        isLoading: false,
        orderId: orderId,
        clearError: true,
      );
      return orderId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final orderCreationControllerProvider =
    StateNotifierProvider<OrderCreationController, OrderCreationState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return OrderCreationController(orderService, auth, firestore);
});
