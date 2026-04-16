class AssignedOrderTracking {
  const AssignedOrderTracking({
    required this.brandName,
    required this.screenTitle,
    required this.userAvatarUrl,
    required this.mapImageUrl,
    required this.cityLabel,
    required this.liveTrackingLabel,
    required this.orderId,
    required this.truckBadgeLabel,
    required this.estimatedArrivalClock,
    required this.estimatedArrivalLabel,
    required this.estimatedArrival,
    required this.distanceLabel,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.driver,
    required this.vehicle,
    required this.orderSummary,
    required this.navItems,
  });

  final String brandName;
  final String screenTitle;
  final String userAvatarUrl;
  final String mapImageUrl;
  final String cityLabel;
  final String liveTrackingLabel;
  final String orderId;
  final String truckBadgeLabel;
  final String estimatedArrivalClock;
  final String estimatedArrivalLabel;
  final String estimatedArrival;
  final String distanceLabel;
  final String statusTitle;
  final String statusSubtitle;
  final DriverAssignment driver;
  final VehicleAssignment vehicle;
  final OrderSummary orderSummary;
  final List<TrackingNavItem> navItems;
}

class DriverAssignment {
  const DriverAssignment({
    required this.name,
    required this.roleLabel,
    required this.avatarUrl,
    required this.ratingLabel,
    required this.idLabel,
    required this.deliveriesLabel,
  });

  final String name;
  final String roleLabel;
  final String avatarUrl;
  final String ratingLabel;
  final String idLabel;
  final String deliveriesLabel;
}

class VehicleAssignment {
  const VehicleAssignment({
    required this.typeLabel,
    required this.plateLabel,
    required this.imageUrl,
    required this.capacityLabel,
  });

  final String typeLabel;
  final String plateLabel;
  final String imageUrl;
  final String capacityLabel;
}

class OrderSummary {
  const OrderSummary({
    required this.amountLabel,
    required this.description,
    required this.ctaLabel,
  });

  final String amountLabel;
  final String description;
  final String ctaLabel;
}

class TrackingNavItem {
  const TrackingNavItem({
    required this.id,
    required this.label,
    required this.iconKey,
  });

  final String id;
  final String label;
  final String iconKey;
}
