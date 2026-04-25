import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart' as app_order;

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

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
        throw Exception('Order is no longer available for acceptance');
      }

      // Update order atomically
      transaction.update(orderRef, {
        'status': 'ASSIGNED',
        'sellerId': sellerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
