import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Location Throttling Tests', () {
    test('Simulate time-based throttling', () {
      const minInterval = Duration(seconds: 5);
      DateTime? lastWriteAt;
      var writeCount = 0;

      void onLocationUpdated(DateTime now) {
        if (lastWriteAt != null && now.difference(lastWriteAt!) < minInterval) {
          // Throttled
          return;
        }
        lastWriteAt = now;
        writeCount++;
      }

      final start = DateTime(2026, 6, 17, 12, 0, 0);

      // First update write succeeds
      onLocationUpdated(start);
      expect(writeCount, 1);

      // Update after 2 seconds gets throttled
      onLocationUpdated(start.add(const Duration(seconds: 2)));
      expect(writeCount, 1);

      // Update after 5 seconds succeeds
      onLocationUpdated(start.add(const Duration(seconds: 5)));
      expect(writeCount, 2);
    });

    test('Simulate distance-based throttling', () {
      const minDistance = 20.0; // meters
      double? lastLatitude;
      double? lastLongitude;
      var writeCount = 0;

      double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        // Simple approximation for distance in meters
        final dy = (lat2 - lat1) * 111320;
        final dx = (lon2 - lon1) * 111320;
        return sqrt(dx * dx + dy * dy);
      }

      void onLocationUpdated(double lat, double lon) {
        if (lastLatitude != null && lastLongitude != null) {
          final distance = calculateDistance(lastLatitude!, lastLongitude!, lat, lon);
          if (distance < minDistance) {
            // Throttled
            return;
          }
        }
        lastLatitude = lat;
        lastLongitude = lon;
        writeCount++;
      }

      // First location write succeeds
      onLocationUpdated(12.9716, 77.5946);
      expect(writeCount, 1);

      // Extremely close location update gets throttled (approx ~0.15m)
      onLocationUpdated(12.971601, 77.594601);
      expect(writeCount, 1);

      // Far update succeeds (approx ~62m)
      onLocationUpdated(12.9720, 77.5950);
      expect(writeCount, 2);
    });
  });
}
