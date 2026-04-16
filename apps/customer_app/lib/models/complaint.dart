class Complaint {
  const Complaint({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.status,
  });

  final String id;
  final String orderId;
  final String userId;
  final String status;
}
