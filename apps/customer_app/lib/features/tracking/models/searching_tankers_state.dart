class SearchingTankersState {
  const SearchingTankersState({
    required this.title,
    required this.userAvatarUrl,
    required this.mapImageUrl,
    required this.mapLocationLabel,
    required this.vehicleDistances,
    required this.scanTitle,
    required this.scanSubtitle,
    required this.connectionLabel,
    required this.connectionBadge,
    required this.footerMessage,
    required this.cancelLabel,
  });

  final String title;
  final String userAvatarUrl;
  final String mapImageUrl;
  final String mapLocationLabel;
  final List<String> vehicleDistances;
  final String scanTitle;
  final String scanSubtitle;
  final String connectionLabel;
  final String connectionBadge;
  final String footerMessage;
  final String cancelLabel;
}
