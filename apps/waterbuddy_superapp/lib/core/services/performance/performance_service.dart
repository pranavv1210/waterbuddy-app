import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Performance monitoring service.
///
/// Wraps Firebase Performance custom traces and HTTP metric recording.
/// In debug mode all operations are no-ops to avoid cluttering dashboards.
class PerformanceService {
  static final FirebasePerformance _perf = FirebasePerformance.instance;

  // ── Trace runner ──────────────────────────────────────────────────────────

  /// Runs [operation] within a named performance trace.
  ///
  /// Usage:
  /// ```dart
  /// final orderId = await performanceService.trace(
  ///   'order_creation',
  ///   () => cloudFunctions.placeOrder(...),
  /// );
  /// ```
  static Future<T> trace<T>(String name, Future<T> Function() operation) async {
    if (kDebugMode) return operation();

    final t = _perf.newTrace(name);
    await t.start();
    try {
      final result = await operation();
      t.putAttribute('status', 'success');
      return result;
    } catch (e) {
      t.putAttribute('status', 'error');
      t.putAttribute('error_type', e.runtimeType.toString());
      rethrow;
    } finally {
      await t.stop();
    }
  }

  // ── Named traces ──────────────────────────────────────────────────────────

  static Future<T> traceOrderCreation<T>(Future<T> Function() op) =>
      trace('order_creation', op);

  static Future<T> traceAppStartup<T>(Future<T> Function() op) =>
      trace('app_startup', op);

  static Future<T> tracePaymentFlow<T>(Future<T> Function() op) =>
      trace('payment_flow', op);

  static Future<T> traceLocationUpdate<T>(Future<T> Function() op) =>
      trace('location_update', op);

  static Future<T> traceFirestoreQuery<T>(
    String collection,
    Future<T> Function() op,
  ) =>
      trace('firestore_query_$collection', op);

  static Future<T> traceCloudFunction<T>(
    String functionName,
    Future<T> Function() op,
  ) =>
      trace('cloud_fn_$functionName', op);

  static Future<T> traceSellerDiscovery<T>(Future<T> Function() op) =>
      trace('seller_discovery', op);

  // ── Screen render ─────────────────────────────────────────────────────────

  static Future<T> traceScreenLoad<T>(
    String screenName,
    Future<T> Function() op,
  ) =>
      trace('screen_${screenName.toLowerCase().replaceAll(' ', '_')}', op);

  // ── Custom metrics ────────────────────────────────────────────────────────

  /// Records a named metric increment within a running trace.
  static void recordMetric(Trace trace, String name, int value) {
    if (kDebugMode) return;
    trace.incrementMetric(name, value);
  }
}
