import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../exceptions/exceptions.dart';
import '../crashlytics/crashlytics_service.dart';
import '../performance/performance_service.dart';

/// Handles Razorpay checkout lifecycle with server-side payment verification.
///
/// Payment flow:
/// 1. Call [createRazorpayOrder] → gets server-side Razorpay Order ID.
/// 2. Call [openCheckout] with that order ID.
/// 3. On success callback, call [verifyPaymentWithBackend].
///    The backend verifies the HMAC-SHA256 signature and marks the order PAID.
/// 4. Flutter NEVER writes paymentStatus = PAID directly to Firestore.
class RazorpayService {
  RazorpayService(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  // ── Replace with your actual Razorpay Key ID from the dashboard ──────────
  // The key is fetched from the createRazorpayOrder response so this is only
  // a fallback display identifier.
  static const String _keyId = 'rzp_test_REPLACE_WITH_YOUR_KEY';

  Razorpay? _razorpay;
  String? _pendingOrderId; // WaterBuddy order ID awaiting payment

  /// Callbacks set by the caller
  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onFailure;
  void Function(ExternalWalletResponse)? onWallet;

  void init() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  // ── Server-side Razorpay Order creation ──────────────────────────────────

  /// Creates a Razorpay Order via Cloud Function and returns the order details.
  /// Must be called before [openCheckout].
  Future<Map<String, dynamic>> createRazorpayOrder({
    required String orderId,
    required int amountInPaise,
  }) async {
    return PerformanceService.traceCloudFunction(
      'createRazorpayOrder',
      () async {
        try {
          final callable = _functions.httpsCallable('createRazorpayOrder');
          final result = await callable.call({
            'orderId': orderId,
            'amountPaise': amountInPaise,
          });
          return Map<String, dynamic>.from(result.data as Map);
        } catch (e, stack) {
          final ex = PaymentException(
            'Failed to create Razorpay order: $e',
            code: 'razorpay_order_creation_failed',
          );
          await CrashlyticsService.recordAppException(
            ex,
            stackTrace: stack,
            orderId: orderId,
          );
          throw ex;
        }
      },
    );
  }

  // ── Checkout ──────────────────────────────────────────────────────────────

  /// Opens the Razorpay checkout sheet.
  ///
  /// [razorpayOrderId] — Must be the server-created Razorpay Order ID.
  /// [amountInPaise] — Amount in smallest currency unit (paise).
  void openCheckout({
    required String orderId,
    required String razorpayOrderId,
    required int amountInPaise,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String description,
    String? prefillMethod,
  }) {
    assert(_razorpay != null, 'Call init() before openCheckout()');
    _pendingOrderId = orderId;

    final options = <String, dynamic>{
      'key': _keyId,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': 'WaterBuddy',
      'description': description,
      'order_id': razorpayOrderId, // Server-side order ID for webhook matching
      'prefill': {
        'contact': customerPhone,
        'email': customerEmail,
        'name': customerName,
        if (prefillMethod != null) 'method': prefillMethod,
      },
      'external': {
        'wallets': ['paytm'],
      },
      'theme': {
        'color': '#0F2B5B',
      },
      'notes': {
        'app_order_id': orderId, // Used by webhook to match to Firestore order
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e, stack) {
      debugPrint('Razorpay open error: $e');
      CrashlyticsService.recordError(e, stack, context: 'RazorpayService.openCheckout');
    }
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay payment success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    debugPrint(
        'Razorpay payment failure: ${response.code} - ${response.message}');

    // Record to Crashlytics (non-fatal — user-initiated failure)
    if (response.code != 0) {
      // code 0 = user dismissed, not a real error
      CrashlyticsService.recordAppException(
        PaymentException(
          'Razorpay payment failed: ${response.message}',
          code: response.code.toString(),
        ),
        orderId: _pendingOrderId,
      );
    }

    onFailure?.call(response);
  }

  void _handleWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay external wallet: ${response.walletName}');
    onWallet?.call(response);
  }

  // ── Backend payment verification ──────────────────────────────────────────

  /// Calls the verifyPayment Cloud Function to verify the HMAC-SHA256 signature
  /// and mark the order as PAID — Flutter never writes PAID directly.
  Future<void> verifyPaymentWithBackend({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    return PerformanceService.traceCloudFunction(
      'verifyPayment',
      () async {
        try {
          final callable = _functions.httpsCallable('verifyPayment');
          final result = await callable.call({
            'orderId': orderId,
            'razorpayPaymentId': razorpayPaymentId,
            'razorpayOrderId': razorpayOrderId,
            'razorpaySignature': razorpaySignature,
          });

          final data = Map<String, dynamic>.from(result.data as Map);
          if (data['success'] != true) {
            throw PaymentException(
              'Payment verification returned unsuccessful',
              code: 'verification_failed',
              paymentId: razorpayPaymentId,
            );
          }

          debugPrint('[PAYMENT] Verified by backend: $razorpayPaymentId');
        } catch (e, stack) {
          final ex = e is PaymentException
              ? e
              : PaymentException(
                  'Payment verification failed: $e',
                  code: 'verification_error',
                  paymentId: razorpayPaymentId,
                );
          await CrashlyticsService.recordAppException(
            ex,
            stackTrace: stack,
            orderId: orderId,
            paymentId: razorpayPaymentId,
          );
          rethrow;
        }
      },
    );
  }

  /// Marks order as COD (Cash on Delivery) — writes directly since no
  /// payment signature verification is needed for COD.
  Future<void> markOrderCod(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': 'PENDING',
      'paymentType': 'COD',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
