class MapsConfig {
  /// Google Maps API Key passed via compiler definition.
  /// Use `--dart-define=GOOGLE_MAPS_API_KEY=your_key` when building or running.
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue:
        'AIzaSyBDH8TLcO_vfDQ2wl_72bj09UT06PDPsbo', // Fallback to firebase key
  );
}
