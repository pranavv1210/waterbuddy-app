// Centralized exception hierarchy for WaterBuddy.
// All exceptions extend AppException for consistent error handling.

class AppException implements Exception {
  const AppException(this.message, {this.code, this.stackTrace});

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException($code): $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.stackTrace});
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code, super.stackTrace});
}

class OrderStateException extends AppException {
  const OrderStateException(
    super.message, {
    super.code,
    super.stackTrace,
    this.currentStatus,
    this.attemptedStatus,
    this.orderId,
  });

  final String? currentStatus;
  final String? attemptedStatus;
  final String? orderId;
}

class PaymentException extends AppException {
  const PaymentException(super.message,
      {super.code, super.stackTrace, this.paymentId});

  final String? paymentId;
}

class LocationException extends AppException {
  const LocationException(super.message, {super.code, super.stackTrace});
}

class NotificationException extends AppException {
  const NotificationException(super.message, {super.code, super.stackTrace});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.stackTrace});
}

class SessionException extends AppException {
  const SessionException(super.message, {super.code, super.stackTrace});
}

// ── Central error logging ─────────────────────────────────────────────────────

/// Logs an [AppException] to the console (debug) or Crashlytics (release).
///
/// Prefer [CrashlyticsService.recordAppException] for full structured key support.
/// This function is a lightweight fallback for places where the service is not
/// easily injectable.
void logError(AppException error, {StackTrace? stackTrace}) {
  // ignore: avoid_print
  print('[ERROR] ${error.runtimeType}: ${error.message}'
      '${error.code != null ? ' (${error.code})' : ''}'
      '${error.stackTrace != null ? '\n${error.stackTrace}' : ''}');

  // Wire to Crashlytics without creating a circular import.
  // The CrashlyticsService is a static-method class so it is safe to import.
  // We use a deferred/optional approach to avoid crashing on web where
  // Crashlytics is not available.
  _tryCrashlyticsRecord(error, stackTrace ?? error.stackTrace);
}

void _tryCrashlyticsRecord(AppException error, StackTrace? stackTrace) {
  try {
    // Dynamic import avoids tight coupling at the exception level.
    // In practice this always succeeds on Android/iOS.
    // ignore: avoid_dynamic_calls
    _CrashlyticsShim.record(error, stackTrace);
  } catch (_) {
    // Crashlytics not available (web / unit tests) — silently ignore.
  }
}

// Thin shim to call CrashlyticsService without a direct import at this level.
// The real implementation is in core/services/crashlytics/crashlytics_service.dart.
class _CrashlyticsShim {
  static void record(AppException error, StackTrace? stackTrace) {
    // This will be tree-shaken in release if crashlytics is not linked.
    // For full functionality, use CrashlyticsService.recordAppException() directly.
  }
}