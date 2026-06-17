import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationTrackingService {
  DriverLocationTrackingService(this._firestore);

  final FirebaseFirestore _firestore;
  StreamSubscription<Position>? _subscription;
  DateTime? _lastWriteAt;

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
    if (!allowed) return;
    await stop();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25,
    );
    _subscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((position) async {
      final now = DateTime.now();
      if (_lastWriteAt != null && now.difference(_lastWriteAt!).inSeconds < 5) {
        return;
      }
      _lastWriteAt = now;
      await _firestore.collection('drivers').doc(driverId).set({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'lastLocationAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _firestore.collection('driver_locations').doc(driverId).set({
        'driverId': driverId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'heading': position.heading,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
