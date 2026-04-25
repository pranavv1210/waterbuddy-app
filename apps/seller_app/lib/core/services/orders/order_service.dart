import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../models/order.dart' as app_order;

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

  // Valid state transitions
  static const Map<String, Set<String>> _validTransitions = {
    'SEARCHING': {'ASSIGNED', 'CANCELLED'},
    'ASSIGNED': {'ON_THE_WAY', 'CANCELLED'},
    'ON_THE_WAY': {'DELIVERED', 'CANCELLED'},
    'DELIVERED': {}, // Terminal state
    'CANCELLED': {}, // Terminal state
  };

  bool _isValidTransition(String currentStatus, String newStatus) {
    final allowedNextStates = _validTransitions[currentStatus];
    return allowedNextStates != null && allowedNextStates.contains(newStatus);
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Order does not exist');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? 'SEARCHING';

      // Validate state transition
      if (!_isValidTransition(currentStatus, newStatus)) {
        throw Exception(
          'Invalid state transition: $currentStatus → $newStatus. '
          'Valid transitions from $currentStatus: ${_validTransitions[currentStatus]?.join(", ") ?? "none"}',
        );
      }

      // Update order atomically
      transaction.update(orderRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<app_order.Order>> watchSearchingOrders() {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'SEARCHING')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(app_order.Order.fromDocument).toList(),
        );
  }

  Stream<List<app_order.Order>> watchSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(app_order.Order.fromDocument).toList(),
        );
  }

  Future<void> acceptOrder(String orderId, String sellerId) async {
    debugPrint('Seller $sellerId attempting to accept order: $orderId');
    await _firestore.runTransaction((transaction) async {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists) {
        throw Exception('Order does not exist');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      final currentStatus = data['status'] as String? ?? 'SEARCHING';

      // Only allow acceptance if order is still searching
      if (currentStatus != 'SEARCHING') {
        debugPrint('Order $orderId is no longer available (status: $currentStatus)');
        throw Exception('Order is no longer available for acceptance');
      }

      // Update order atomically with seller assignment
      transaction.update(orderRef, {
        'status': 'ASSIGNED',
        'sellerId': sellerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Order $orderId accepted successfully by seller $sellerId');
    });
  }
}
