import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashlyticsService {
  final FirebaseCrashlytics? _crashlytics;

  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  FirebaseCrashlytics get crashlytics =>
      _crashlytics ?? FirebaseCrashlytics.instance;

  /// Initializes global crash handlers and debug mode filters.
  Future<void> initialize() async {
    // Disable automatic collection in debug mode to prevent noise in dashboard
    if (kDebugMode) {
      await crashlytics.setCrashlyticsCollectionEnabled(false);
    } else {
      await crashlytics.setCrashlyticsCollectionEnabled(true);
    }

    // Capture all unhandled Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      } else {
        crashlytics.recordFlutterFatalError(details);
      }
    };

    // Capture async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!isNoiseError(error)) {
        crashlytics.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  /// Sets an anonymous user identifier for crash reporting (No PII: no email, name, or phone).
  Future<void> setUserIdentifier(String userUid) async {
    if (userUid.isEmpty) return;
    try {
      await crashlytics.setUserIdentifier(userUid);
    } catch (_) {
      // Ignore identifier errors
    }
  }

  /// Records custom keys for debugging context without sensitive user data.
  Future<void> setCustomKey(String key, Object value) async {
    try {
      await crashlytics.setCustomKey(key, value);
    } catch (_) {
      // Ignore key setting failures
    }
  }

  /// Records a non-fatal exception if it passes the noise filter.
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (isNoiseError(error)) {
      debugPrint('[CrashlyticsService] Filtered expected noise error: $error');
      return;
    }

    try {
      await crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {
      // Ignore crash reporting failures
    }
  }

  /// Noise filter preventing expected operational issues from filling Crashlytics dashboard.
  bool isNoiseError(dynamic error) {
    if (error == null) return true;
    final errStr = error.toString().toLowerCase();

    // 1. Network / Offline issues
    if (errStr.contains('socketexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('network_error') ||
        errStr.contains('unavailable')) {
      return true;
    }

    // 2. User cancellations (e.g. image picker canceled)
    if (errStr.contains('canceled') || errStr.contains('user_cancelled')) {
      return true;
    }

    // 3. Form validation or expected user input errors
    if (errStr.contains('form_validation_error') ||
        errStr.contains('invalid_email') ||
        errStr.contains('wrong_password')) {
      return true;
    }

    // 4. Expected permission-denied errors (e.g., security rule block)
    if (errStr.contains('permission-denied')) {
      return true;
    }

    return false;
  }
}
