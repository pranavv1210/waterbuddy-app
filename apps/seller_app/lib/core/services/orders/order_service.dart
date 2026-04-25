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
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'ASSIGNED',
      'sellerId': sellerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
