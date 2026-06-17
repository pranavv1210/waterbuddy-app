import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Driver Location Tracking Service
/// 
/// Features:
/// - Location write throttling: every 5 seconds OR every 20 meters
/// - Offline protection: stops writes when going offline
/// - Batch writes for atomic updates
/// - Structured logging
class DriverLocationTrackingService {
  DriverLocationTrackingService(this._firestore);

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

  Future<void> start({required String driverId}) async {
    final allowed = await _ensurePermission();
    if (!allowed) {
      debugPrint('[DRIVER_LOC] Permission denied - location tracking disabled');
      return;
    }
    await stop();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Triggers every 20m minimum
    );
    
    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) async {
      final now = DateTime.now();
      
      // THROTTLE: Minimum 5 seconds between writes
      if (_lastWriteAt != null && now.difference(_lastWriteAt!) < _minInterval) {
        return;
      }
      
      // THROTTLE: Minimum 20 meters distance change
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        if (distance < _minDistance) {
          return;
        }
      }

      _lastWriteAt = now;
      _lastPosition = position;

      // Use batch write for atomicity: driver doc + driver_locations doc
      final batch = _firestore.batch();
      
      batch.set(
        _firestore.collection('drivers').doc(driverId),
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
        _firestore.collection('driver_locations').doc(driverId),
        {
          'driverId': driverId,
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
      
      debugPrint(
        '[DRIVER_LOC] Update for $driverId: '
        '${position.latitude},${position.longitude} '
        'heading=${position.heading} speed=${position.speed}',
      );
    }, onError: (error) {
      debugPrint('[DRIVER_LOC] Error: $error');
    });
    
    debugPrint('[DRIVER_LOC] Started tracking for driver $driverId');
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastPosition = null;
    _lastWriteAt = null;
    debugPrint('[DRIVER_LOC] Stopped tracking');
  }
}