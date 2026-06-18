import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import '../../exceptions/exceptions.dart';
import '../crashlytics/crashlytics_service.dart';
import '../performance/performance_service.dart';

/// Seller (Tanker Owner) Location Tracking Service
///
/// Features:
/// - Location write throttling: every 5 seconds OR every 20 meters
/// - Offline protection: stops writes when going offline
/// - Structured logging
class SellerLocationTrackingService {
  SellerLocationTrackingService(this._firestore);

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _subscription;
  DateTime? _lastWriteAt;
  Position? _lastPosition;

  static const Duration _minInterval = Duration(seconds: 5);
  static const double _minDistance = 20.0; // meters

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> start({required String sellerId}) async {
    final allowed = await _ensurePermission();
    if (!allowed) {
      debugPrint('[SELLER_LOC] Permission denied - location tracking disabled');
      await CrashlyticsService.recordAppException(
        const PermissionException(
          'Seller location permission denied',
          code: 'seller_location_permission_denied',
        ),
      );
      return;
    }
    await stop();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Triggers every 20m minimum
    );

    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (position) async {
      final now = DateTime.now();

      // THROTTLE: Minimum 5 seconds between writes
      if (_lastWriteAt != null &&
          now.difference(_lastWriteAt!) < _minInterval) {
        return;
      }

      // THROTTLE: Minimum 20 meters distance change
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance < _minDistance) {
          return;
        }
      }

      _lastWriteAt = now;
      _lastPosition = position;

      await PerformanceService.traceLocationUpdate(() async {
        // Use batch write for atomicity: seller doc + tanker_locations doc
        final batch = _firestore.batch();

        batch.set(
          _firestore.collection('sellers').doc(sellerId),
          {
            'currentLocation': {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'heading': position.heading,
              'speed': position.speed,
              'accuracy': position.accuracy,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'lastLocationAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        batch.set(
          _firestore.collection('seller_locations').doc(sellerId),
          {
            'sellerId': sellerId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'heading': position.heading,
            'speed': position.speed,
            'accuracy': position.accuracy,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await batch.commit();
      });

      debugPrint(
        '[SELLER_LOC] Update for $sellerId: '
        '${position.latitude},${position.longitude} '
        'heading=${position.heading} speed=${position.speed}',
      );
    }, onError: (error) {
      debugPrint('[SELLER_LOC] Error: $error');
      CrashlyticsService.recordError(
        error,
        StackTrace.current,
        context: 'SellerLocationTrackingService.positionStream',
      );
    });

    debugPrint('[SELLER_LOC] Started tracking for seller $sellerId');
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastPosition = null;
    _lastWriteAt = null;
    debugPrint('[SELLER_LOC] Stopped tracking');
  }
}
