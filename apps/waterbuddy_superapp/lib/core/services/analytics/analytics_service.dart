import 'package:firebase_analytics/firebase_analytics.dart';
import '../observability/observability_service.dart';

class AnalyticsService {
  AnalyticsService._(this._analytics);

  final FirebaseAnalytics _analytics;
  static AnalyticsService? _instance;

  static AnalyticsService get instance {
    _instance ??= AnalyticsService._(FirebaseAnalytics.instance);
    return _instance!;
  }

  void _log(String name, Map<String, Object> parameters) {
    try {
      _analytics.logEvent(name: name, parameters: parameters);
      ObservabilityService.info(
        LogTag.analytics,
        'Logged event: $name',
        context: parameters,
      );
    } catch (e, stack) {
      ObservabilityService.error(
        LogTag.analytics,
        'Failed to log event: $name',
        error: e,
        stack: stack,
      );
    }
  }

  void logLogin(String userId, String role) {
    _log('login', {'user_id': userId, 'role': role});
  }

  void logSignup(String userId, String role) {
    _log('signup', {'user_id': userId, 'role': role});
  }

  void logBookingCreated(String orderId, double amount, num tankSize) {
    _log('booking_created', {
      'order_id': orderId,
      'amount': amount,
      'tank_size': tankSize,
    });
  }

  void logBookingCancelled(String orderId, String reason, String cancelledBy) {
    _log('booking_cancelled', {
      'order_id': orderId,
      'reason': reason,
      'cancelled_by': cancelledBy,
    });
  }

  void logBookingCompleted(String orderId) {
    _log('booking_completed', {'order_id': orderId});
  }

  void logPaymentSuccess(String orderId, String paymentId) {
    _log('payment_success', {'order_id': orderId, 'payment_id': paymentId});
  }

  void logPaymentFailure(String orderId, String errorCode, String errorMessage) {
    _log('payment_failure', {
      'order_id': orderId,
      'error_code': errorCode,
      'error_message': errorMessage,
    });
  }

  void logRefundRequested(String orderId, double amount) {
    _log('refund_requested', {'order_id': orderId, 'amount': amount});
  }

  void logRefundApproved(String orderId, double amount) {
    _log('refund_approved', {'order_id': orderId, 'amount': amount});
  }

  void logWalletTopup(String userId, double amount) {
    _log('wallet_topup', {'user_id': userId, 'amount': amount});
  }

  void logSellerOnline(String sellerId, bool online) {
    _log('seller_online', {'seller_id': sellerId, 'online': online ? 1 : 0});
  }

  void logDriverOnline(String driverId, bool online) {
    _log('driver_online', {'driver_id': driverId, 'online': online ? 1 : 0});
  }

  void logReviewSubmitted(String orderId, double rating) {
    _log('review_submitted', {'order_id': orderId, 'rating': rating});
  }

  void logOrderTimeout(String orderId) {
    _log('order_timeout', {'order_id': orderId});
  }
}