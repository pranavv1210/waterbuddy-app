class HomeDashboard {
  const HomeDashboard({
    required this.brandName,
    required this.userName,
    required this.userAvatarUrl,
    required this.heroBadgeLabel,
    required this.mapImageUrl,
    required this.mapImageAlt,
    required this.capacityTitle,
    required this.capacitySubtitle,
    required this.tankOptions,
    required this.bottomNavItems,
  });

  final String brandName;
  final String userName;
  final String userAvatarUrl;
  final String heroBadgeLabel;
  final String mapImageUrl;
  final String mapImageAlt;
  final String capacityTitle;
  final String capacitySubtitle;
  final List<TankOption> tankOptions;
  final List<BottomNavItemData> bottomNavItems;
}

class TankOption {
  const TankOption({
    required this.id,
    required this.label,
    required this.capacityLabel,
    required this.priceLabel,
    required this.iconKey,
    this.isRecommended = false,
  });

  final String id;
  final String label;
  final String capacityLabel;
  final String priceLabel;
  final String iconKey;
  final bool isRecommended;
}

class BottomNavItemData {
  const BottomNavItemData({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;
}
