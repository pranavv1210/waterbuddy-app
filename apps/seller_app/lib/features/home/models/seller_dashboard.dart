class SellerDashboard {
  const SellerDashboard({
    required this.sellerName,
    required this.businessName,
    required this.avatarUrl,
    required this.isOnline,
    required this.todaysEarnings,
    required this.earningsChangeLabel,
    required this.activeTime,
    required this.efficiencyLabel,
    required this.completedOrders,
    required this.ratingToday,
    required this.statusTitle,
    required this.statusMessage,
  });

  final String sellerName;
  final String businessName;
  final String avatarUrl;
  final bool isOnline;
  final String todaysEarnings;
  final String earningsChangeLabel;
  final String activeTime;
  final String efficiencyLabel;
  final int completedOrders;
  final double ratingToday;
  final String statusTitle;
  final String statusMessage;

  SellerDashboard copyWith({
    bool? isOnline,
    String? statusTitle,
    String? statusMessage,
  }) {
    return SellerDashboard(
      sellerName: sellerName,
      businessName: businessName,
      avatarUrl: avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      todaysEarnings: todaysEarnings,
      earningsChangeLabel: earningsChangeLabel,
      activeTime: activeTime,
      efficiencyLabel: efficiencyLabel,
      completedOrders: completedOrders,
      ratingToday: ratingToday,
      statusTitle: statusTitle ?? this.statusTitle,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
