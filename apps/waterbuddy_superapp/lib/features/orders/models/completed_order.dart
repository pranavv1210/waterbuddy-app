class CompletedOrder {
  const CompletedOrder({
    required this.brandName,
    required this.userAvatarUrl,
    required this.successTitle,
    required this.successSubtitle,
    required this.deliveryTime,
    required this.deliveryStatus,
    required this.dropLocation,
    required this.mapImageUrl,
    required this.orderId,
    required this.items,
    required this.ratingTitle,
    required this.ratingSubtitle,
    required this.feedbackCta,
    required this.navItems,
  });

  final String brandName;
  final String userAvatarUrl;
  final String successTitle;
  final String successSubtitle;
  final String deliveryTime;
  final String deliveryStatus;
  final String dropLocation;
  final String mapImageUrl;
  final String orderId;
  final List<CompletedOrderItem> items;
  final String ratingTitle;
  final String ratingSubtitle;
  final String feedbackCta;
  final List<CompletedOrderNavItem> navItems;
}

class CompletedOrderItem {
  const CompletedOrderItem({
    required this.name,
    required this.quantityLabel,
    required this.amountLabel,
  });

  final String name;
  final String quantityLabel;
  final String amountLabel;
}

class CompletedOrderNavItem {
  const CompletedOrderNavItem({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;
}
