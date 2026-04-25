class SellerProfile {
  const SellerProfile({
    required this.id,
    required this.kycStatus,
    required this.isOnline,
    required this.lastActiveAt,
    required this.tankSizes,
    required this.pricing,
    required this.serviceArea,
  });

  final String id;
  final String kycStatus;
  final bool isOnline;
  final DateTime? lastActiveAt;
  final List<num> tankSizes;
  final Map<String, num> pricing;
  final Map<String, dynamic> serviceArea;

  SellerProfile copyWith({
    String? id,
    String? kycStatus,
    bool? isOnline,
    DateTime? lastActiveAt,
    List<num>? tankSizes,
    Map<String, num>? pricing,
    Map<String, dynamic>? serviceArea,
  }) {
    return SellerProfile(
      id: id ?? this.id,
      kycStatus: kycStatus ?? this.kycStatus,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      tankSizes: tankSizes ?? this.tankSizes,
      pricing: pricing ?? this.pricing,
      serviceArea: serviceArea ?? this.serviceArea,
    );
  }
}
