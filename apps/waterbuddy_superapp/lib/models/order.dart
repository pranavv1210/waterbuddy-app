import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.sellerId,
    required this.tankSize,
    required this.status,
    required this.paymentType,
    required this.paymentStatus,
    required this.location,
    this.driverId,
    this.assignedAt,
    this.startedAt,
    this.deliveredAt,
    this.tracking,
    this.createdAt,
  });

  factory Order.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return Order(
      id: document.id,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      customerPhone: data['customerPhone'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
      tankSize: data['tankSize'] as num? ?? 0,
      status: data['status'] as String? ?? 'SEARCHING',
      paymentType: data['paymentType'] as String? ?? 'COD',
      paymentStatus: data['paymentStatus'] as String? ?? 'PENDING',
      location: Map<String, dynamic>.from(data['location'] as Map? ?? const {}),
      driverId: data['driverId'] as String?,
      assignedAt: data['assignedAt'] as Timestamp?,
      startedAt: data['startedAt'] as Timestamp?,
      deliveredAt: data['deliveredAt'] as Timestamp?,
      tracking: data['tracking'] != null
          ? TrackingData.fromMap(data['tracking'] as Map<String, dynamic>)
          : null,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? sellerId;
  final num tankSize;
  final String status;
  final String paymentType;
  final String paymentStatus;
  final Map<String, dynamic> location;
  final String? driverId;
  final Timestamp? assignedAt;
  final Timestamp? startedAt;
  final Timestamp? deliveredAt;
  final TrackingData? tracking;
  final Timestamp? createdAt;

  String? get deliveryAddress => location['address'] as String?;
  double get latitude => (location['latitude'] as num?)?.toDouble() ?? 0.0;
  double get longitude => (location['longitude'] as num?)?.toDouble() ?? 0.0;
  String get tankLabel => '${tankSize.toInt()}L Tanker';
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
