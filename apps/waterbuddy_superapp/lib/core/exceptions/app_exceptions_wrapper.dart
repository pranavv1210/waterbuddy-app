import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'exceptions.dart';

class FirebaseExceptionMapper {
  FirebaseExceptionMapper._();

  static AppException map(dynamic exception, {StackTrace? stackTrace}) {
    if (exception is AppException) return exception;

    if (exception is FirebaseException) {
      final code = exception.code;
      final message = exception.message ?? 'A database operation failed.';
      
      switch (code) {
        case 'permission-denied':
          return PermissionException(
            'You do not have permission to perform this action.',
            code: code,
            stackTrace: stackTrace,
          );
        case 'unavailable':
          return NetworkException(
            'The database is currently offline. Your updates will sync when you reconnect.',
            code: code,
            stackTrace: stackTrace,
          );
        case 'not-found':
          return StorageException(
            'Requested resource could not be found.',
            code: code,
            stackTrace: stackTrace,
          );
        case 'already-exists':
          return StorageException(
            'This record already exists in the system.',
            code: code,
            stackTrace: stackTrace,
          );
        case 'resource-exhausted':
          return NetworkException(
            'Rate limit exceeded. Please wait a moment before trying again.',
            code: code,
            stackTrace: stackTrace,
          );
        default:
          return AppException(
            message,
            code: code,
            stackTrace: stackTrace,
          );
      }
    }

    if (exception is TimeoutException) {
      return NetworkException(
        'Connection timed out. Please check your internet connection.',
        code: 'timeout',
        stackTrace: stackTrace,
      );
    }

    return AppException(
      exception.toString(),
      code: 'unknown',
      stackTrace: stackTrace,
    );
  }
}

class RetryPolicy {
  RetryPolicy._();

  static final _random = Random();

  /// Executes [action] with exponential backoff and randomized jitter.
  static Future<T> executeWithRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
    Duration maxDelay = const Duration(seconds: 5),
    double multiplier = 2.0,
    bool Function(Exception)? retryIf,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await action();
      } on Exception catch (e) {
        final mappedException = FirebaseExceptionMapper.map(e);
        
        if (attempt >= maxAttempts || (retryIf != null && !retryIf(e))) {
          throw mappedException;
        }

        // 90% to 110% randomized jitter
        final jitter = _random.nextDouble() * 0.2 + 0.9;
        final sleepMs = (delay.inMilliseconds * jitter).round();
        
        await Future.delayed(Duration(milliseconds: sleepMs));

        final nextDelayMs = (delay.inMilliseconds * multiplier).round();
        delay = nextDelayMs > maxDelay.inMilliseconds 
            ? maxDelay 
            : Duration(milliseconds: nextDelayMs);
      }
    }
  }
}
