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

class GoogleRouteInfo {
  const GoogleRouteInfo({
    required this.polylinePoints,
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    this.durationInTrafficText,
    this.durationInTrafficSeconds,
  });

  final List<GooglePlaceCoordinates> polylinePoints;
  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
  final String? durationInTrafficText;
  final int? durationInTrafficSeconds;
}

class GoogleDistanceMatrixInfo {
  const GoogleDistanceMatrixInfo({
    required this.distanceText,
    required this.distanceMeters,
    required this.durationText,
    required this.durationSeconds,
    this.durationInTrafficText,
    this.durationInTrafficSeconds,
  });

  final String distanceText;
  final int distanceMeters;
  final String durationText;
  final int durationSeconds;
  final String? durationInTrafficText;
  final int? durationInTrafficSeconds;
}

class GoogleGeocodeResult {
  const GoogleGeocodeResult({
    required this.formattedAddress,
    required this.coordinates,
  });

  final String formattedAddress;
  final GooglePlaceCoordinates coordinates;
}

class GoogleMapsService {
  Future<List<GooglePlaceSuggestion>> getSuggestions(String query) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      // Return empty list if no key is configured, avoiding network errors
      return const [];
    }

    try {
      final uri = Uri.https(
          'maps.googleapis.com', '/maps/api/place/autocomplete/json', {
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
        final struct =
            pred['structured_formatting'] as Map<String, dynamic>? ?? {};
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
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
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

  Future<GoogleRouteInfo?> getDirections({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
        'origin': '$originLatitude,$originLongitude',
        'destination': '$destinationLatitude,$destinationLongitude',
        'mode': 'driving',
        'departure_time': 'now',
        'traffic_model': 'best_guess',
        'key': apiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final routes = data['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>? ?? const [];
      if (legs.isEmpty) return null;
      final leg = legs.first as Map<String, dynamic>;
      final polyline = (route['overview_polyline']
              as Map<String, dynamic>?)?['points']
          ?.toString();
      return GoogleRouteInfo(
        polylinePoints: _decodePolyline(polyline ?? ''),
        distanceText:
            ((leg['distance'] as Map<String, dynamic>?)?['text'] ?? '')
                .toString(),
        distanceMeters:
            ((leg['distance'] as Map<String, dynamic>?)?['value'] as num?)
                    ?.toInt() ??
                0,
        durationText:
            ((leg['duration'] as Map<String, dynamic>?)?['text'] ?? '')
                .toString(),
        durationSeconds:
            ((leg['duration'] as Map<String, dynamic>?)?['value'] as num?)
                    ?.toInt() ??
                0,
        durationInTrafficText:
            (leg['duration_in_traffic'] as Map<String, dynamic>?)?['text']
                ?.toString(),
        durationInTrafficSeconds:
            ((leg['duration_in_traffic'] as Map<String, dynamic>?)?['value']
                    as num?)
                ?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<GoogleDistanceMatrixInfo?> getDistanceMatrix({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/distancematrix/json', {
        'origins': '$originLatitude,$originLongitude',
        'destinations': '$destinationLatitude,$destinationLongitude',
        'mode': 'driving',
        'departure_time': 'now',
        'traffic_model': 'best_guess',
        'key': apiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final rows = data['rows'] as List<dynamic>? ?? const [];
      if (rows.isEmpty) return null;
      final elements =
          (rows.first as Map<String, dynamic>)['elements'] as List<dynamic>? ??
              const [];
      if (elements.isEmpty) return null;
      final element = elements.first as Map<String, dynamic>;
      if (element['status'] != 'OK') return null;
      return GoogleDistanceMatrixInfo(
        distanceText:
            ((element['distance'] as Map<String, dynamic>?)?['text'] ?? '')
                .toString(),
        distanceMeters:
            ((element['distance'] as Map<String, dynamic>?)?['value'] as num?)
                    ?.toInt() ??
                0,
        durationText:
            ((element['duration'] as Map<String, dynamic>?)?['text'] ?? '')
                .toString(),
        durationSeconds:
            ((element['duration'] as Map<String, dynamic>?)?['value'] as num?)
                    ?.toInt() ??
                0,
        durationInTrafficText:
            (element['duration_in_traffic'] as Map<String, dynamic>?)?['text']
                ?.toString(),
        durationInTrafficSeconds:
            ((element['duration_in_traffic'] as Map<String, dynamic>?)?['value']
                    as num?)
                ?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<GoogleGeocodeResult?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return null;
    return _geocode({'latlng': '$latitude,$longitude', 'key': apiKey});
  }

  Future<GoogleGeocodeResult?> forwardGeocode(String address) async {
    const apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty || address.trim().isEmpty) return null;
    return _geocode({'address': address.trim(), 'key': apiKey});
  }

  Future<GoogleGeocodeResult?> _geocode(Map<String, String> query) async {
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        ...query,
        'components': 'country:IN',
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final results = data['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final location =
          ((first['geometry'] as Map<String, dynamic>?)?['location']
                  as Map<String, dynamic>?) ??
              {};
      final lat = (location['lat'] as num?)?.toDouble();
      final lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return GoogleGeocodeResult(
        formattedAddress: (first['formatted_address'] ?? '').toString(),
        coordinates: GooglePlaceCoordinates(latitude: lat, longitude: lng),
      );
    } catch (_) {
      return null;
    }
  }

  List<GooglePlaceCoordinates> _decodePolyline(String encoded) {
    final points = <GooglePlaceCoordinates>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lat += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      lng += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      points.add(
        GooglePlaceCoordinates(
          latitude: lat / 1E5,
          longitude: lng / 1E5,
        ),
      );
    }

    return points;
  }
}
