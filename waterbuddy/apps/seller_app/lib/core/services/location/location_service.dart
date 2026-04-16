abstract class LocationService {
  Future<void> startSharingLocation({required String activeOrderId});
  Future<void> stopSharingLocation();
}
