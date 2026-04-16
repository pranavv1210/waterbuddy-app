abstract class LocationService {
  Future<({double lat, double lng})?> getCurrentCoordinates();
}
