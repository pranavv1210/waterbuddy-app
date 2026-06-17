import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../core/exceptions/exceptions.dart';
import '../../../core/services/crashlytics/crashlytics_service.dart';
import '../../../core/services/payments/razorpay_service.dart';
import '../../../core/services/performance/performance_service.dart';
import '../../../providers/app_providers.dart';

// ── RazorpayService provider ─────────────────────────────────────────────────

final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService(
    ref.watch(firestoreProvider),
    ref.watch(cloudFunctionsProvider),
  );
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
      final settings =
          await _firestore.collection('system_settings').doc('config').get();
      if (settings.data()?['codEnabled'] == false) {
        throw const PaymentException(
          'Cash on delivery is currently disabled.',
          code: 'cod_disabled',
        );
      }
      await _razorpayService.markOrderCod(orderId);
      debugPrint('COD selected for order: $orderId');
      state = state.copyWith(
        isProcessing: false,
        paymentType: 'COD',
        paymentCompleted: true,
      );
    } on PaymentException catch (e, stack) {
      await CrashlyticsService.recordAppException(e,
          stackTrace: stack, orderId: orderId);
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
    } catch (e, stack) {
      await CrashlyticsService.recordError(e, stack,
          context: 'PaymentController.selectCod');
      state = state.copyWith(isProcessing: false, errorMessage: e.toString());
    }
  }

  // ── Razorpay (UPI / Card / Netbanking) ──────────────────────────────────────

  Future<void> startOnlinePayment({
    required String orderId,
    required int amountInPaise,
    required String method, // 'upi' | 'card' | 'netbanking'
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String description,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // Step 1: Create a server-side Razorpay order to get the razorpayOrderId.
      // This is critical — the webhook uses `notes.app_order_id` to match payment.
      final razorpayOrderData =
          await PerformanceService.traceOrderCreation(() async {
        return _razorpayService.createRazorpayOrder(
          orderId: orderId,
          amountInPaise: amountInPaise,
        );
      });

      final razorpayOrderId =
          razorpayOrderData['razorpayOrderId'] as String? ?? '';

      if (razorpayOrderId.isEmpty) {
        throw const PaymentException(
          'Server did not return a Razorpay order ID.',
          code: 'missing_razorpay_order_id',
        );
      }

      // Step 2: Wire up one-time callbacks
      _razorpayService.onSuccess = (PaymentSuccessResponse response) async {
        await _handlePaymentSuccess(
          response: response,
          orderId: orderId,
          razorpayOrderId: razorpayOrderId,
        );
      };

      _razorpayService.onFailure = (PaymentFailureResponse response) {
        debugPrint('Payment FAILED: ${response.code} ${response.message}');
        final msg = response.code == 0
            ? 'Payment cancelled'
            : 'Payment failed: ${response.message}';
        state = state.copyWith(isProcessing: false, errorMessage: msg);
      };

      _razorpayService.onWallet = (_) {
        // External wallet selected — Razorpay handles routing
        state = state.copyWith(isProcessing: false);
      };

      // Step 3: Open checkout with the server-generated Razorpay Order ID
      _razorpayService.openCheckout(
        orderId: orderId,
        razorpayOrderId: razorpayOrderId,
        amountInPaise: amountInPaise,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        description: description,
        prefillMethod: method,
      );
      // Note: state remains isProcessing=true until callback fires
    } on PaymentException catch (e, stack) {
      await CrashlyticsService.recordAppException(e,
          stackTrace: stack, orderId: orderId);
      state = state.copyWith(isProcessing: false, errorMessage: e.message);
    } catch (e, stack) {
      await CrashlyticsService.recordError(e, stack,
          context: 'PaymentController.startOnlinePayment');
      state = state.copyWith(isProcessing: false, errorMessage: e.toString());
    }
  }

  Future<void> _handlePaymentSuccess({
    required PaymentSuccessResponse response,
    required String orderId,
    required String razorpayOrderId,
  }) async {
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';

    try {
      // Backend verifies signature and marks order PAID —
      // Flutter never writes paymentStatus = PAID directly.
      await _razorpayService.verifyPaymentWithBackend(
        orderId: orderId,
        razorpayPaymentId: paymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: signature,
      );

      debugPrint('[PAYMENT] Backend verification success: $paymentId');
      state = state.copyWith(
        isProcessing: false,
        paymentType: 'ONLINE',
        paymentCompleted: true,
      );
    } on PaymentException catch (e, stack) {
      await CrashlyticsService.recordAppException(
        e,
        stackTrace: stack,
        orderId: orderId,
        paymentId: paymentId,
      );
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Payment received but verification failed. '
            'Contact support with payment ID: $paymentId',
      );
    }
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
