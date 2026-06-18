import 'dart:core';
import '../observability/observability_service.dart';

class CacheEntry<T> {
  CacheEntry(this.data, this.expiryTime);
  final T data;
  final DateTime expiryTime;

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

class CacheService {
  CacheService._();

  static final CacheService instance = CacheService._();
  final Map<String, CacheEntry<dynamic>> _cache = {};

  void write<T>(String key, T data, {Duration ttl = const Duration(minutes: 5)}) {
    final expiry = DateTime.now().add(ttl);
    _cache[key] = CacheEntry<T>(data, expiry);
    ObservabilityService.info(
      LogTag.analytics,
      'Cache WRITE: key=$key, expires in ${ttl.inMinutes} mins',
    );
  }

  T? read<T>(String key) {
    final entry = _cache[key];
    if (entry == null) {
      ObservabilityService.info(LogTag.analytics, 'Cache MISS: key=$key');
      return null;
    }

    if (entry.isExpired) {
      ObservabilityService.info(LogTag.analytics, 'Cache EXPIRED: key=$key');
      _cache.remove(key);
      return null;
    }

    ObservabilityService.info(LogTag.analytics, 'Cache HIT: key=$key');
    return entry.data as T;
  }

  void invalidate(String key) {
    _cache.remove(key);
    ObservabilityService.info(LogTag.analytics, 'Cache INVALIDATED: key=$key');
  }

  void clearAll() {
    _cache.clear();
    ObservabilityService.info(LogTag.analytics, 'Cache CLEAR ALL completed');
  }
}
