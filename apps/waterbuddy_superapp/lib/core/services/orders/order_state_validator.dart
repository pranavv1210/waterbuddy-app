/// Central Order State Validator
/// 
/// Production-grade state machine for WaterBuddy orders.
/// Allowed transitions are strictly enforced.
/// 
/// States:
///   SEARCHING → ASSIGNED → EN_ROUTE → COMPLETED
///   SEARCHING → CANCELLED
///   ASSIGNED → CANCELLED
///   EN_ROUTE → CANCELLED
/// 
/// Any other transition is INVALID and throws.
class OrderStateValidator {
  const OrderStateValidator._();

  static const String seaching = 'SEARCHING';
  static const String assigned = 'ASSIGNED';
  static const String enRoute = 'EN_ROUTE';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';

  /// The strict state machine
  static const Map<String, Set<String>> transitions = {
    seaching: {assigned, cancelled},
    assigned: {enRoute, cancelled},
    enRoute: {completed, cancelled},
    completed: {},
    cancelled: {},
  };

  /// Returns true if the transition is valid
  static bool isValid(String current, String next) {
    final allowed = transitions[current];
    return allowed != null && allowed.contains(next);
  }

  /// Throws if transition is invalid
  static void validateTransition(String current, String next) {
    if (!isValid(current, next)) {
      throw OrderStateException(
        'Invalid state transition: $current → $next',
        currentStatus: current,
        attemptedStatus: next,
      );
    }
  }

  /// Returns true if the status is a terminal state
  static bool isTerminal(String status) {
    return status == completed || status == cancelled;
  }

  /// Returns true if the status is an active, non-terminal state
  static bool isActive(String status) {
    return !isTerminal(status);
  }
}

class OrderStateException implements Exception {
  const OrderStateException(
    this.message, {
    this.currentStatus,
    this.attemptedStatus,
    this.orderId,
  });

  final String message;
  final String? currentStatus;
  final String? attemptedStatus;
  final String? orderId;

  @override
  String toString() {
    final buf = StringBuffer('OrderStateException: $message');
    if (orderId != null) buf.write(' (order: $orderId)');
    return buf.toString();
  }
}