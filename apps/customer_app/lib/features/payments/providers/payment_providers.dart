import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/services/payments/razorpay_service.dart';
import '../../../providers/app_providers.dart';

// ── RazorpayService provider ─────────────────────────────────────────────────

final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService(ref.watch(firestoreProvider));
  ref.onDispose(service.dispose);
  return service;
});

// ── PaymentController ────────────────────────────────────────────────────────

class PaymentController extends StateNotifier<PaymentState> {
  PaymentController(this._razorpayService, this._firestore)
      : super(const PaymentState());

  final RazorpayService _razorpayService;
  final FirebaseFirestore _firestore;

  // ── COD ─────────────────────────────────────────────────────────────────────

  Future<void> selectCod(String orderId) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      await _razorpayService.markOrderCod(orderId);
      debugPrint('COD selected for order: $orderId');
      state = state.copyWith(
        isProcessing: false,
        paymentType: 'COD',
        paymentCompleted: true,
      );
    } catch (e) {
      state = state.copyWith(isProcessing: false, errorMessage: e.toString());
    }
  }

  // ── Razorpay (UPI / Card / Netbanking) ──────────────────────────────────────

  Future<void> startOnlinePayment({
    required String orderId,
    required int amountInPaise,
    required String method,      // 'upi' | 'card' | 'netbanking'
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String description,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    // Wire up one-time callbacks
    _razorpayService.onSuccess = (response) async {
      try {
        await _razorpayService.markOrderPaid(orderId, response.paymentId ?? '');
        debugPrint('Payment PAID: ${response.paymentId}');
        state = state.copyWith(
          isProcessing: false,
          paymentType: 'ONLINE',
          paymentCompleted: true,
        );
      } catch (e) {
        state = state.copyWith(isProcessing: false, errorMessage: e.toString());
      }
    };

    _razorpayService.onFailure = (response) {
      debugPrint('Payment FAILED: ${response.code} ${response.message}');
      final msg = response.code == 0
          ? 'Payment cancelled'
          : 'Payment failed: ${response.message}';
      state = state.copyWith(isProcessing: false, errorMessage: msg);
    };

    _razorpayService.onWallet = (_) {
      // External wallet selected — treat like a pending online payment
      state = state.copyWith(isProcessing: false);
    };

    _razorpayService.openCheckout(
      orderId: orderId,
      amountInPaise: amountInPaise,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      description: description,
      prefillMethod: method,
    );
    // Note: state remains isProcessing=true until callback fires
  }

  // ── Legacy stub (keeps old callers compiling) ────────────────────────────────

  Future<void> selectPaymentMethod(String orderId, String paymentType) async {
    if (paymentType == 'COD') {
      await selectCod(orderId);
    }
    // For online types callers should use startOnlinePayment
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── State ────────────────────────────────────────────────────────────────────

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

// ── Providers ────────────────────────────────────────────────────────────────

final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
  return PaymentController(
    ref.watch(razorpayServiceProvider),
    ref.watch(firestoreProvider),
  );
});

final selectedPaymentMethodProvider = StateProvider<String?>((ref) => 'upi');
