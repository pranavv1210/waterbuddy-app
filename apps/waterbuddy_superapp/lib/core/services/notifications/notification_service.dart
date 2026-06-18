import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../crashlytics/crashlytics_service.dart';

/// Top-level FCM background handler — MUST be a top-level function (not a method).
/// Runs in an isolated background isolate when the app is terminated/backgrounded.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised at this point by the plugin's isolate spawn.
  debugPrint(
      '[FCM BG] Received: ${message.messageId} type=${message.data['type']}');
}

/// Android notification channel used by all WaterBuddy order notifications.
const AndroidNotificationChannel _orderChannel = AndroidNotificationChannel(
  'waterbuddy_orders',
  'WaterBuddy Orders',
  description: 'Water delivery order notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// Handles FCM lifecycle:
///  • Requests permission
///  • Saves the FCM token to the correct role sub-collection
///  • Refreshes the token when it rotates
///  • Displays foreground notifications via flutter_local_notifications
///  • Routes notification taps to the correct screen
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

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _messageOpenedSub;

  /// Set of messageIds seen in this session — prevents duplicate local notifications.
  final Set<String> _seenMessageIds = {};

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

    // 3. Set up local notifications for foreground display
    await _initLocalNotifications();

    // 4. Save initial token
    await _saveToken();

    // 5. Listen for token refresh
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed');
      _saveTokenValue(token);
    }, onError: (Object e, StackTrace stack) {
      CrashlyticsService.recordError(
        e,
        stack,
        context: 'FcmService.onTokenRefresh',
      );
    });

    // 6. Handle foreground messages — display as local notification
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object e, StackTrace stack) {
        CrashlyticsService.recordError(
          e,
          stack,
          context: 'FcmService.onMessage',
        );
      },
    );

    // 7. Handle notification taps from background (app in BG, not killed)
    _messageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
      onError: (Object e, StackTrace stack) {
        CrashlyticsService.recordError(
          e,
          stack,
          context: 'FcmService.onMessageOpenedApp',
        );
      },
    );

    // 8. Handle notification that launched the app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
          '[FCM] App launched via notification: ${initialMessage.messageId}');
      // Defer routing slightly to let the widget tree mount
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage);
      });
    }

    // 9. On Android, ensure the FCM messages are shown in foreground too
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _foregroundMessageSub?.cancel();
    await _messageOpenedSub?.cancel();
    _tokenRefreshSub = null;
    _foregroundMessageSub = null;
    _messageOpenedSub = null;
  }

  // ── Local notifications setup ───────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifs.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) {
          _routeFromPayload({'type': payload});
        }
      },
    );

    // Create the Android notification channel
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_orderChannel);
    }
  }

  // ── Token management ───────────────────────────────────────────────────────

  Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) await _saveTokenValue(token);
    } catch (e, stack) {
      debugPrint('[FCM] Failed to get token: $e');
      await CrashlyticsService.recordError(
        e,
        stack,
        context: 'FcmService._saveToken',
      );
    }
  }

  Future<void> _saveTokenValue(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('[FCM] No authenticated user — skipping token save');
      return;
    }

    try {
      final tokenData = {
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save under users/ (consumers)
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set(tokenData, SetOptions(merge: true));

      // Also update the top-level fcmToken field for fast reads
      await _firestore.collection('users').doc(user.uid).set(
        {'fcmToken': token, 'fcmUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      debugPrint('[FCM] Token saved for user ${user.uid}');
    } catch (e) {
      debugPrint('[FCM] Failed to save token: $e');
    }
  }

  /// Call after role selection or role change to save token under the
  /// correct role collection (sellers/drivers).
  Future<void> saveTokenForRole(String role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final tokenData = {
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      switch (role) {
        case 'seller':
          await _firestore
              .collection('sellers')
              .doc(user.uid)
              .collection('fcmTokens')
              .doc(token)
              .set(tokenData, SetOptions(merge: true));
          break;
        case 'driver':
          await _firestore
              .collection('drivers')
              .doc(user.uid)
              .collection('fcmTokens')
              .doc(token)
              .set(tokenData, SetOptions(merge: true));
          break;
        default:
          // consumer — already saved in _saveTokenValue
          break;
      }
      debugPrint('[FCM] Token saved for role $role, user ${user.uid}');
    } catch (e) {
      debugPrint('[FCM] Failed to save role token: $e');
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

      // Remove from all role sub-collections
      for (final col in ['users', 'sellers', 'drivers']) {
        await _firestore
            .collection(col)
            .doc(user.uid)
            .update({'fcmToken': FieldValue.delete()}).catchError((_) {});
        if (token != null) {
          await _firestore
              .collection(col)
              .doc(user.uid)
              .collection('fcmTokens')
              .doc(token)
              .delete()
              .catchError((_) {});
        }
      }

      await _messaging.deleteToken();
      debugPrint('[FCM] Token cleared on logout');
    } catch (e) {
      debugPrint('[FCM] Failed to clear token: $e');
    }
  }

  // ── Message handlers ───────────────────────────────────────────────────────

  /// Broadcast tapped notification payloads for the router to handle.
  static final List<void Function(Map<String, dynamic>)> _tapCallbacks = [];

  static void onNotificationTap(void Function(Map<String, dynamic> data) cb) {
    _tapCallbacks.add(cb);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final messageId = message.messageId ?? '';
    if (messageId.isNotEmpty && _seenMessageIds.contains(messageId)) {
      debugPrint('[FCM FG] Duplicate suppressed: $messageId');
      return;
    }
    if (messageId.isNotEmpty) _seenMessageIds.add(messageId);

    debugPrint(
        '[FCM FG] ${message.notification?.title}: ${message.notification?.body}');

    final notification = message.notification;
    if (notification == null) return;

    // Show local notification so foreground users see a heads-up banner
    _localNotifs.show(
      messageId.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _orderChannel.id,
          _orderChannel.name,
          channelDescription: _orderChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['type'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM TAP] data=${message.data}');
    _routeFromPayload(message.data);
  }

  void _routeFromPayload(Map<String, dynamic> data) {
    for (final cb in _tapCallbacks) {
      try {
        cb(data);
      } catch (e, stack) {
        CrashlyticsService.recordError(
          e,
          stack,
          context: 'FcmService._routeFromPayload',
        );
      }
    }
  }

  // ── Notification type routing helper ──────────────────────────────────────

  /// Returns the GoRouter path to navigate to based on notification type.
  static String? routeForNotificationType(String? type) {
    switch (type) {
      case 'ORDER_OFFER':
        return '/seller'; // seller dashboard
      case 'ORDER_ACCEPTED':
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_EN_ROUTE':
      case 'DRIVER_ARRIVED':
        return '/consumer/tracking';
      case 'ORDER_DELIVERED':
        return '/consumer/order-complete';
      case 'ORDER_CANCELLED':
      case 'NO_PARTNER_FOUND':
        return '/consumer/home';
      case 'PAYMENT_SUCCESS':
      case 'PAYMENT_FAILED':
        return '/consumer/payments';
      default:
        return null;
    }
  }
}
