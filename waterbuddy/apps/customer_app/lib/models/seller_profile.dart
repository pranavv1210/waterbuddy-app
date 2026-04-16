class SellerProfile {
  const SellerProfile({
    required this.id,
    required this.kycStatus,
    required this.isOnline,
    required this.tankSizes,
    required this.pricing,
    required this.serviceArea,
  });

  final String id;
  final String kycStatus;
  final bool isOnline;
  final List<num> tankSizes;
  final Map<String, num> pricing;
  final Map<String, dynamic> serviceArea;
}
