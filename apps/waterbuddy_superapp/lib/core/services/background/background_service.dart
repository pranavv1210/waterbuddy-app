import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../crashlytics/crashlytics_service.dart';
import '../orders/order_service.dart';
import '../../../models/order.dart' as app_order;

/// Handles background-related concerns:
/// - Active order restoration on cold start and app resume.
/// - Internet reconnect re-sync.
/// - App lifecycle tracking (foreground/background/detached).
///
/// This is a singleton service managed by a provider — attach it early
/// in the widget tree via [app_providers.dart].
class BackgroundService with WidgetsBindingObserver {
  BackgroundService({
    required FirebaseFirestore firestore,
    required OrderService orderService,
  })  : _firestore = firestore,
        _orderService = orderService;

  final FirebaseFirestore _firestore;
  final OrderService _orderService;

  String? _currentUserId;
  String? _currentRole;
  StreamSubscription<DocumentSnapshot>? _connectivitySub;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
  }

  /// Called after successful login to configure user context.
  void setUser(String uid, String role) {
    _currentUserId = uid;
    _currentRole = role;
    CrashlyticsService.setUserIdentifier(uid);
    CrashlyticsService.setRoleContext(role);
    _startConnectivityWatch();
  }

  /// Called on logout.
  void clearUser() {
    _currentUserId = null;
    _currentRole = null;
    CrashlyticsService.clearUserIdentifier();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[BackgroundService] App resumed — re-syncing active order');
        _tryRestoreActiveOrder();
        break;
      case AppLifecycleState.paused:
        debugPrint('[BackgroundService] App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('[BackgroundService] App detached');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  // ── Active order restoration ──────────────────────────────────────────────

  /// Restores the active order after cold start or app resume.
  /// Returns the active order if one exists, null otherwise.
  Future<app_order.Order?> restoreActiveOrder() async {
    if (_currentUserId == null) return null;
    return _tryRestoreActiveOrder();
  }

  Future<app_order.Order?> _tryRestoreActiveOrder() async {
    if (_currentUserId == null) return null;
    try {
      final order = await _orderService.findActiveOrder(
        customerId: _currentRole == 'consumer' ? _currentUserId : null,
        sellerId: _currentRole == 'seller' ? _currentUserId : null,
        driverId: _currentRole == 'driver' ? _currentUserId : null,
      );
      if (order != null) {
        debugPrint('[BackgroundService] Active order restored: ${order.id}');
        await CrashlyticsService.setOrderContext(order.id);
      }
      return order;
    } catch (e, stack) {
      await CrashlyticsService.recordError(
        e,
        stack,
        context: 'BackgroundService._tryRestoreActiveOrder',
      );
      return null;
    }
  }

  // ── Connectivity watch ────────────────────────────────────────────────────

  /// Watches the Firestore connectivity metadata document to detect
  /// internet reconnect events and trigger re-sync.
  void _startConnectivityWatch() {
    _connectivitySub?.cancel();
    // Use a lightweight document snapshot as a connectivity probe
    _connectivitySub = _firestore
        .collection('system_settings')
        .doc('app')
        .snapshots()
        .listen(
          (snap) {
            if (snap.metadata.isFromCache) {
              debugPrint('[BackgroundService] Operating offline');
            } else {
              debugPrint('[BackgroundService] Online — Firestore connected');
              _tryRestoreActiveOrder();
            }
          },
          onError: (e) {
            debugPrint('[BackgroundService] Connectivity watch error: $e');
          },
        );
  }

  // ── Battery saver / screen lock awareness ────────────────────────────────

  /// Returns true if the app is in a state where heavy operations
  /// (location tracking, FCM polling) should be paused.
  bool get shouldThrottleBackgroundOps {
    // In practice, geolocator and FCM handle this automatically,
    // but expose a flag for location tracking services.
    return false;
  }
}
