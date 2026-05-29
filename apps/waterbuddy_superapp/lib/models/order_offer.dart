import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import 'order.dart';

class OrderOffer {
  const OrderOffer({
    required this.id,
    required this.orderId,
    required this.sellerId,
    required this.status,
    required this.attemptNumber,
    required this.distanceKm,
    required this.expiresAt,
    this.order,
  });

  factory OrderOffer.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document, {
    Order? order,
  }) {
    final data = document.data() ?? <String, dynamic>{};
    return OrderOffer(
      id: document.id,
      orderId: (data['orderId'] ?? '').toString(),
      sellerId: (data['sellerId'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      attemptNumber: (data['attemptNumber'] as num?)?.toInt() ?? 1,
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      expiresAt: data['expiresAt'] as Timestamp?,
      order: order,
    );
  }

  final String id;
  final String orderId;
  final String sellerId;
  final String status;
  final int attemptNumber;
  final double distanceKm;
  final Timestamp? expiresAt;
  final Order? order;
}
