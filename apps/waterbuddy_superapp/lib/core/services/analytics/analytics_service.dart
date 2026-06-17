import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Analytics Service
/// 
/// Tracks key platform metrics in Firestore under system_metrics.
/// This is a lightweight counter-based approach — counters are incremented
/// using FieldValue.increment() which avoids read-before-write costs.
class AnalyticsService {
  AnalyticsService(this._firestore);
  final FirebaseFirestore _firestore;

  static const String _metricsCollection = 'system_metrics';

  String get _todayId {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> incrementOrdersCreated() => _increment('ordersCreated');
  Future<void> incrementOrdersCompleted() => _increment('ordersCompleted');
  Future<void> incrementOrdersCancelled() => _increment('ordersCancelled');
  Future<void> incrementPaymentsSuccess() => _increment('paymentsSuccess');
  Future<void> incrementPaymentsFailed() => _increment('paymentsFailed');

  Future<void> _increment(String field) async {
    try {
      await _firestore
          .collection(_metricsCollection)
          .doc(_todayId)
          .set({
            field: FieldValue.increment(1),
            'date': _todayId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ANALYTICS] Failed to increment $field: $e');
    }
  }

  /// Record delivery time for average calculation
  Future<void> recordDeliveryTime(Duration duration) async {
    try {
      await _firestore
          .collection(_metricsCollection)
          .doc(_todayId)
          .set({
            'deliveryTimes': FieldValue.arrayUnion([duration.inMinutes]),
            'totalDeliveries': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[ANALYTICS] Failed to record delivery time: $e');
    }
  }
}