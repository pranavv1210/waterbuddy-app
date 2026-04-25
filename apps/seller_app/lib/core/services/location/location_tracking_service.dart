import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationTrackingService {
  LocationTrackingService(this._firestore);

  final FirebaseFirestore _firestore;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionSubscription;
  static const Duration _updateInterval = Duration(seconds: 8);

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location service is disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
      return false;
    }

    return true;
  }

  Future<void> startTracking(String orderId) async {
    debugPrint('Starting location tracking for order: $orderId');

    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      debugPrint('Cannot start tracking: no location permission');
      return;
    }

    // Cancel any existing tracking
    stopTracking();

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocation(orderId, position);
    } catch (e) {
      debugPrint('Error getting initial position: $e');
    }

    // Start periodic updates
    _locationUpdateTimer = Timer.periodic(_updateInterval, (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _updateLocation(orderId, position);
        debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Error updating location: $e');
      }
    });
  }

  Future<void> _updateLocation(String orderId, Position position) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'tracking': {
          'lat': position.latitude,
          'lng': position.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('Error updating Firestore location: $e');
    }
  }

  void stopTracking() {
    debugPrint('Stopping location tracking');
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
  }
}
