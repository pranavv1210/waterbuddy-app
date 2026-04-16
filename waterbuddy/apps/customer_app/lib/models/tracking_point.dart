class TrackingPoint {
  const TrackingPoint({
    required this.orderId,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  final String orderId;
  final double lat;
  final double lng;
  final DateTime? timestamp;
}
