import 'dart:math' as math;

class EtaResult {
  const EtaResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedArrival,
    required this.estimatedCompletion,
  });

  final double distanceKm;
  final int durationMinutes;
  final DateTime estimatedArrival;
  final DateTime estimatedCompletion;
}

class EtaService {
  const EtaService({
    this.averageSpeedKmph = 28,
    this.trafficFactor = 1.2,
    this.completionBufferMinutes = 8,
  });

  final double averageSpeedKmph;
  final double trafficFactor;
  final int completionBufferMinutes;

  EtaResult calculate({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    DateTime? now,
  }) {
    final distance = distanceKm(
      originLat,
      originLng,
      destinationLat,
      destinationLng,
    );
    final minutes = estimateMinutes(distance);
    final baseTime = now ?? DateTime.now();
    final arrival = baseTime.add(Duration(minutes: minutes));
    return EtaResult(
      distanceKm: distance,
      durationMinutes: minutes,
      estimatedArrival: arrival,
      estimatedCompletion:
          arrival.add(Duration(minutes: completionBufferMinutes)),
    );
  }

  int estimateMinutes(double distanceKm) {
    if (!distanceKm.isFinite || distanceKm <= 0) return 0;
    final speed = math.max(5.0, averageSpeedKmph);
    return ((distanceKm / speed) * 60 * trafficFactor).ceil();
  }

  double distanceKm(
    double originLat,
    double originLng,
    double destinationLat,
    double destinationLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(destinationLat - originLat);
    final dLng = _toRadians(destinationLng - originLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(originLat)) *
            math.cos(_toRadians(destinationLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double value) => value * math.pi / 180;
}
