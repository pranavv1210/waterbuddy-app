import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Handles Razorpay checkout lifecycle and writes the result to Firestore.
class RazorpayService {
  RazorpayService(this._firestore);

  final FirebaseFirestore _firestore;

  // ── Replace with your actual Razorpay Key ID from the dashboard ──────────
  static const String _keyId = 'rzp_test_REPLACE_WITH_YOUR_KEY';

  Razorpay? _razorpay;

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

  /// Opens the Razorpay checkout sheet.
  ///
  /// [amountInPaise] — Razorpay expects amount in smallest currency unit (paise).
  void openCheckout({
    required String orderId,
    required int amountInPaise,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String description,
    String? prefillMethod, // 'upi' | 'card' | 'netbanking'
  }) {
    assert(_razorpay != null,
        'Call init() before openCheckout()');

    final options = <String, dynamic>{
      'key': _keyId,
      'amount': amountInPaise,
      'name': 'WaterBuddy',
      'description': description,
      'order_id': '', // Use Razorpay Orders API in production for server-side order id
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
        'app_order_id': orderId,
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay payment success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    debugPrint('Razorpay payment failure: ${response.code} - ${response.message}');
    onFailure?.call(response);
  }

  void _handleWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay external wallet: ${response.walletName}');
    onWallet?.call(response);
  }

  /// Marks order as PAID in Firestore with Razorpay payment reference.
  Future<void> markOrderPaid(String orderId, String razorpayPaymentId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': 'PAID',
      'paymentId': razorpayPaymentId,
      'paymentType': 'ONLINE',
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  /// Marks order as COD (Cash on Delivery).
  Future<void> markOrderCod(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': 'PENDING',
      'paymentType': 'COD',
    });
  }
}
