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
    this.tracking,
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
      tracking: data['tracking'] != null
          ? TrackingData.fromMap(data['tracking'] as Map<String, dynamic>)
          : null,
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
  final TrackingData? tracking;
}

class TrackingData {
  const TrackingData({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory TrackingData.fromMap(Map<String, dynamic> map) {
    return TrackingData(
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  final double lat;
  final double lng;
  final Timestamp? updatedAt;
}
