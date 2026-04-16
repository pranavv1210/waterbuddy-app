class ProfileDashboard {
  const ProfileDashboard({
    required this.brandName,
    required this.userAvatarUrl,
    required this.profileImageUrl,
    required this.profileName,
    required this.email,
    required this.membershipLabel,
    required this.completedOrdersLabel,
    required this.topNavItems,
    required this.recentOrders,
    required this.paymentMethods,
    required this.supportEmail,
    required this.supportItems,
    required this.bottomNavItems,
  });

  final String brandName;
  final String userAvatarUrl;
  final String profileImageUrl;
  final String profileName;
  final String email;
  final String membershipLabel;
  final String completedOrdersLabel;
  final List<ProfileNavItem> topNavItems;
  final List<ProfileOrderItem> recentOrders;
  final List<PaymentMethodCard> paymentMethods;
  final String supportEmail;
  final List<SupportActionItem> supportItems;
  final List<ProfileNavItem> bottomNavItems;
}

class ProfileNavItem {
  const ProfileNavItem({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;
}

class ProfileOrderItem {
  const ProfileOrderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amountLabel,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String subtitle;
  final String amountLabel;
  final String iconKey;
}

class PaymentMethodCard {
  const PaymentMethodCard({
    required this.id,
    required this.title,
    required this.maskedNumber,
    required this.expiryLabel,
    required this.brandImageUrl,
    required this.brandImageAlt,
    this.isPrimary = false,
    this.isAddNew = false,
  });

  final String id;
  final String title;
  final String maskedNumber;
  final String expiryLabel;
  final String brandImageUrl;
  final String brandImageAlt;
  final bool isPrimary;
  final bool isAddNew;
}

class SupportActionItem {
  const SupportActionItem({
    required this.id,
    required this.title,
    required this.iconKey,
  });

  final String id;
  final String title;
  final String iconKey;
}
