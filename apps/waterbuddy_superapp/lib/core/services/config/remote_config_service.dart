import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RemoteConfigService {
  RemoteConfigService._(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;
  static RemoteConfigService? _instance;

  static RemoteConfigService get instance {
    if (_instance == null) {
      throw StateError('RemoteConfigService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      
      // Define defaults
      final defaults = <String, dynamic>{
        'search_radius': 10.0,
        'order_timeout_seconds': 300,
        'location_update_interval_ms': 5000,
        'commission_percentage': 10.0,
        'refund_window_minutes': 15,
        'notification_interval_seconds': 10,
        'payment_retry_count': 3,
        // Feature flags defaults matching local environment
        'feature_wallets': _getEnvBool('FEATURE_WALLETS', true),
        'feature_reviews': _getEnvBool('FEATURE_REVIEWS', true),
        'feature_ratings': _getEnvBool('FEATURE_RATINGS', true),
        'feature_referrals': _getEnvBool('FEATURE_REFERRALS', true),
        'feature_promotions': _getEnvBool('FEATURE_PROMOTIONS', false),
        'feature_surge_pricing': _getEnvBool('FEATURE_SURGE_PRICING', false),
        'feature_subscriptions': _getEnvBool('FEATURE_SUBSCRIPTIONS', false),
        'feature_driver_incentives': _getEnvBool('FEATURE_DRIVER_INCENTIVES', false),
      };

      await remoteConfig.setDefaults(defaults);
      
      // Set settings: short fetch interval in debug, 1 hour in release
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? const Duration(seconds: 10) : const Duration(hours: 1),
      ));

      await remoteConfig.fetchAndActivate();
      _instance = RemoteConfigService._(remoteConfig);
    } catch (e) {
      debugPrint('[REMOTE_CONFIG] Init failed, using defaults and environment: $e');
      // Mock / fallback instance for tests or offline situations
      _instance = RemoteConfigService._(FirebaseRemoteConfig.instance);
    }
  }

  static bool _getEnvBool(String key, bool fallback) {
    try {
      final val = dotenv.maybeGet(key);
      if (val != null) {
        return val.toLowerCase() == 'true';
      }
    } catch (_) {}
    return fallback;
  }

  // ── Remotely configurable values ───────────────────────────────────────────

  double get searchRadius => _remoteConfig.getDouble('search_radius');
  int get orderTimeoutSeconds => _remoteConfig.getInt('order_timeout_seconds');
  int get locationUpdateIntervalMs => _remoteConfig.getInt('location_update_interval_ms');
  double get commissionPercentage => _remoteConfig.getDouble('commission_percentage');
  int get refundWindowMinutes => _remoteConfig.getInt('refund_window_minutes');
  int get notificationIntervalSeconds => _remoteConfig.getInt('notification_interval_seconds');
  int get paymentRetryCount => _remoteConfig.getInt('payment_retry_count');

  // ── Feature Flags ──────────────────────────────────────────────────────────

  bool get isWalletEnabled => _remoteConfig.getBool('feature_wallets');
  bool get isReviewsEnabled => _remoteConfig.getBool('feature_reviews');
  bool get isRatingsEnabled => _remoteConfig.getBool('feature_ratings');
  bool get isReferralsEnabled => _remoteConfig.getBool('feature_referrals');
  bool get isPromotionsEnabled => _remoteConfig.getBool('feature_promotions');
  bool get isSurgePricingEnabled => _remoteConfig.getBool('feature_surge_pricing');
  bool get isSubscriptionsEnabled => _remoteConfig.getBool('feature_subscriptions');
  bool get isDriverIncentivesEnabled => _remoteConfig.getBool('feature_driver_incentives');
}
