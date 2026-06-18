import 'package:flutter/foundation.dart';

enum LogTag {
  auth,
  order,
  payment,
  wallet,
  payout,
  refund,
  seller,
  driver,
  location,
  fcm,
  analytics,
  function,
}

class ObservabilityService {
  const ObservabilityService._();

  static String _tagToString(LogTag tag) {
    switch (tag) {
      case LogTag.auth:
        return 'AUTH';
      case LogTag.order:
        return 'ORDER';
      case LogTag.payment:
        return 'PAYMENT';
      case LogTag.wallet:
        return 'WALLET';
      case LogTag.payout:
        return 'PAYOUT';
      case LogTag.refund:
        return 'REFUND';
      case LogTag.seller:
        return 'SELLER';
      case LogTag.driver:
        return 'DRIVER';
      case LogTag.location:
        return 'LOCATION';
      case LogTag.fcm:
        return 'FCM';
      case LogTag.analytics:
        return 'ANALYTICS';
      case LogTag.function:
        return 'FUNCTION';
    }
  }

  static void info(LogTag tag, String message, {Map<String, String?>? ids, Map<String, dynamic>? context}) {
    final formatted = _format(tag, message, ids, context);
    debugPrint('[INFO] $formatted');
  }

  static void warn(LogTag tag, String message, {Map<String, String?>? ids, Map<String, dynamic>? context}) {
    final formatted = _format(tag, message, ids, context);
    debugPrint('[WARN] $formatted');
  }

  static void error(LogTag tag, String message, {dynamic error, StackTrace? stack, Map<String, String?>? ids, Map<String, dynamic>? context}) {
    final formatted = _format(tag, message, ids, context);
    debugPrint('[ERROR] $formatted | Error: $error');
    if (stack != null) {
      debugPrint('$stack');
    }
  }

  static String _format(LogTag tag, String message, Map<String, String?>? ids, Map<String, dynamic>? context) {
    final tagStr = _tagToString(tag);
    final idsPart = ids != null && ids.isNotEmpty
        ? ' | ${ids.entries.where((e) => e.value != null).map((e) => "${e.key}=${e.value}").join(" ")}'
        : '';
    final ctxPart = context != null && context.isNotEmpty
        ? ' | context=$context'
        : '';
    return '[$tagStr] $message$idsPart$ctxPart';
  }
}
