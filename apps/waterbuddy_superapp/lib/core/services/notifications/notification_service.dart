import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Top-level FCM background handler — MUST be a top-level function (not a method).
/// Runs in an isolated background isolate when the app is terminated/backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised at this point because the isolate
  // is spawned by the FirebaseMessaging plugin which handles init.
  debugPrint('[FCM BG] Received: ${message.messageId}');
}

/// Handles FCM lifecycle:
///  • Requests permission
///  • Saves the FCM token to Firestore under users/{uid}
///  • Refreshes the token when it rotates
///  • Provides a stream of tapped notifications for the UI to navigate
class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _messaging = messaging,
        _firestore = firestore,
        _auth = auth;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ── Initialise ─────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Register top-level background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications denied by user');
      return;
    }

    // 3. Save initial token
    await _saveToken();

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed');
      _saveTokenValue(token);
    });

    // 5. Handle foreground messages (show in-app banner via callback)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Handle notification taps from background (app was in BG, not killed)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Handle notification that launched the app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '[FCM] App launched via notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveTokenValue(token);
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
    }
  }

  Future<void> _saveTokenValue(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[FCM] No authenticated user — skipping token save');
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FCM] Token saved for user ${user.uid}');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Call after login / when user changes to ensure token is always fresh.
  Future<void> refreshTokenForCurrentUser() => _saveToken();

  /// Call on logout to remove the token so stale devices don't receive pushes.
  Future<void> clearTokenOnLogout() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
      if (token != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token)
            .delete();
      }
      await _messaging.deleteToken();
      debugPrint('[FCM] Token cleared on logout');
    } catch (e) {
      debugPrint('[FCM] Failed to clear token: $e');
    }
  }

  // ── Message handlers ───────────────────────────────────────────────────────

  /// Broadcast tapped notification payloads for the router to handle.
  static final _tapCallbacks = <void Function(Map<String, dynamic>)>[];

  static void onNotificationTap(void Function(Map<String, dynamic> data) cb) {
    _tapCallbacks.add(cb);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
        '[FCM FG] ${message.notification?.title}: ${message.notification?.body}');
    // Foreground messages: the system does NOT show a banner on Android by default.
    // A local notification library (flutter_local_notifications) would be needed
    // to display a heads-up banner. We log here so the developer can add it later.
    // The data payload is still actionable via onMessage.listen in the UI layer.
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM TAP] ${message.data}');
    for (final cb in _tapCallbacks) {
      cb(message.data);
    }
  }
}
