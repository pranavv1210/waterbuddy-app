import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.sellerId,
    required this.tankSize,
    required this.status,
    required this.paymentType,
    required this.paymentStatus,
    required this.location,
  });

  factory Order.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return Order(
      id: document.id,
      customerId: data['customerId'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
      tankSize: data['tankSize'] as num? ?? 0,
      status: data['status'] as String? ?? 'SEARCHING',
      paymentType: data['paymentType'] as String? ?? 'COD',
      paymentStatus: data['paymentStatus'] as String? ?? 'PENDING',
      location: Map<String, dynamic>.from(data['location'] as Map? ?? const {}),
    );
  }

  final String id;
  final String customerId;
  final String? sellerId;
  final num tankSize;
  final String status;
  final String paymentType;
  final String paymentStatus;
  final Map<String, dynamic> location;
}
