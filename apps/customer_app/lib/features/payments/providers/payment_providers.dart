import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/orders/order_service.dart';
import '../../../providers/app_providers.dart';
import '../data/mock_payment_repository.dart';
import '../models/payment_checkout.dart';

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController(this._orderService) : super(const PaymentState());

  final OrderService _orderService;

  Future<void> selectPaymentMethod(String orderId, String paymentType) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      await _orderService.updateOrderPayment(orderId, paymentType);
      debugPrint('Payment method selected: $paymentType for order: $orderId');
      
      state = state.copyWith(
        isProcessing: false,
        paymentType: paymentType,
        paymentCompleted: true,
      );
    } catch (e) {
      debugPrint('Error selecting payment method: $e');
      state = state.copyWith(
        isProcessing: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

class PaymentState {
  const PaymentState({
    this.isProcessing = false,
    this.paymentType,
    this.paymentCompleted = false,
    this.errorMessage,
  });

  final bool isProcessing;
  final String? paymentType;
  final bool paymentCompleted;
  final String? errorMessage;

  PaymentState copyWith({
    bool? isProcessing,
    String? paymentType,
    bool? paymentCompleted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaymentState(
      isProcessing: isProcessing ?? this.isProcessing,
      paymentType: paymentType ?? this.paymentType,
      paymentCompleted: paymentCompleted ?? this.paymentCompleted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return PaymentController(orderService);
});

final paymentRepositoryProvider = Provider<MockPaymentRepository>(
  (ref) => MockPaymentRepository(),
);

final paymentCheckoutProvider = FutureProvider<PaymentCheckout>(
  (ref) => ref.watch(paymentRepositoryProvider).getCheckout(),
);

final selectedPaymentMethodProvider = StateProvider<String?>((ref) => 'upi');
