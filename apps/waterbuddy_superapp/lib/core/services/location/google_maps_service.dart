import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/maps_config.dart';

class GooglePlaceSuggestion {
  const GooglePlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
  });

  final String placeId;
  final String mainText;
  final String secondaryText;
  final String description;

  String get fullAddress => description;
}

class GooglePlaceCoordinates {
  const GooglePlaceCoordinates({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class GoogleMapsService {
  Future<List<GooglePlaceSuggestion>> getSuggestions(String query) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      // Return empty list if no key is configured, avoiding network errors
      return const [];
    }

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': query,
        'key': apiKey,
        'components': 'country:in',
        'location': '12.9716,77.5946', // Bias towards Bengaluru
        'radius': '30000',
        'language': 'en',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return const [];

      final predictions = data['predictions'] as List<dynamic>? ?? const [];
      return predictions.map((pred) {
        final struct = pred['structured_formatting'] as Map<String, dynamic>? ?? {};
        return GooglePlaceSuggestion(
          placeId: (pred['place_id'] ?? '').toString(),
          mainText: (struct['main_text'] ?? '').toString(),
          secondaryText: (struct['secondary_text'] ?? '').toString(),
          description: (pred['description'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<GooglePlaceCoordinates?> getPlaceDetails(String placeId) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty || placeId.isEmpty) return null;

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
        'place_id': placeId,
        'fields': 'geometry',
        'key': apiKey,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final result = data['result'] as Map<String, dynamic>? ?? {};
      final geometry = result['geometry'] as Map<String, dynamic>? ?? {};
      final location = geometry['location'] as Map<String, dynamic>? ?? {};
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        return GooglePlaceCoordinates(latitude: lat, longitude: lng);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
