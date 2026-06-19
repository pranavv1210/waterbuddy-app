import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../exceptions/exceptions.dart';

/// Centralized Crashlytics wrapper.
///
/// All error paths in the app should go through this service instead of
/// calling FirebaseCrashlytics.instance directly. This ensures:
/// - Structured custom keys are set before every error report.
/// - Debug builds suppress crash reporting to avoid polluting production data.
/// - A consistent log breadcrumb is added for every error.
class CrashlyticsService {
  static FirebaseCrashlytics get _instance => FirebaseCrashlytics.instance;

  // ── User context ──────────────────────────────────────────────────────────

  /// Call after successful login.
  static Future<void> setUserIdentifier(String uid) async {
    if (kDebugMode) return;
    await _runSafely(() => _instance.setUserIdentifier(uid));
  }

  /// Call on logout.
  static Future<void> clearUserIdentifier() async {
    if (kDebugMode) return;
    await _runSafely(() => _instance.setUserIdentifier(''));
  }

  // ── Custom keys ────────────────────────────────────────────────────────────

  static Future<void> setCustomKey(String key, Object value) async {
    if (kDebugMode) return;
    await _runSafely(() => _instance.setCustomKey(key, value));
  }

  static Future<void> setOrderContext(String orderId) async =>
      setCustomKey('active_order_id', orderId);

  static Future<void> setRoleContext(String role) async =>
      setCustomKey('user_role', role);

  // ── Breadcrumb logging ────────────────────────────────────────────────────

  static Future<void> log(String message) async {
    debugPrint('[CRASHLYTICS] $message');
    if (kDebugMode) return;
    await _runSafely(() => _instance.log(message));
  }

  // ── Error recording ───────────────────────────────────────────────────────

  /// Records an [AppException] with structured context keys.
  static Future<void> recordAppException(
    AppException exception, {
    StackTrace? stackTrace,
    bool fatal = false,
    String? orderId,
    String? paymentId,
    String? userId,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[CRASHLYTICS] ${exception.runtimeType}: ${exception.message}'
        '${exception.code != null ? ' (${exception.code})' : ''}',
      );
      return;
    }

    // Set structured keys before recording
    await Future.wait([
      if (exception.code != null) setCustomKey('error_code', exception.code!),
      if (orderId != null) setCustomKey('error_order_id', orderId),
      if (paymentId != null) setCustomKey('error_payment_id', paymentId),
      if (userId != null) setCustomKey('error_user_id', userId),
      setCustomKey('error_type', exception.runtimeType.toString()),
    ]);

    await _runSafely(
      () => _instance.recordError(
        exception,
        stackTrace ?? exception.stackTrace,
        reason: exception.message,
        fatal: fatal,
      ),
    );
  }

  /// Records a raw error that is not an [AppException].
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    String? context,
  }) async {
    if (kDebugMode) {
      debugPrint('[CRASHLYTICS] Error in $context: $error');
      return;
    }
    if (context != null) {
      await setCustomKey('error_context', context);
    }
    await _runSafely(
      () => _instance.recordError(error, stackTrace, fatal: fatal),
    );
  }

  /// Records a Flutter framework error (for FlutterError.onError).
  static void recordFlutterError(FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
      return;
    }
    _runSafely(() => _instance.recordFlutterFatalError(details));
  }

  static Future<void> _runSafely(Future<void> Function() action) async {
    if (Firebase.apps.isEmpty) {
      debugPrint('[CRASHLYTICS] Firebase not initialized; reporting skipped.');
      return;
    }
    try {
      await action();
    } catch (e) {
      debugPrint('[CRASHLYTICS] Reporting unavailable: $e');
    }
  }
}
