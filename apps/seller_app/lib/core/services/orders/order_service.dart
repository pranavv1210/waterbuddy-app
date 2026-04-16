import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/order.dart';

class OrderService {
  OrderService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Order>> watchSellerOrders(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Order.fromDocument).toList());
  }
}
