import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics;

  FirebaseAnalytics get analytics =>
      _analytics ?? FirebaseAnalytics.instance;

  /// Log listing creation event (Low-cardinality only: no itemId, no user names/emails).
  Future<void> logListingCreated({
    required String category,
    required String durationBucket,
  }) async {
    try {
      await analytics.logEvent(
        name: 'listing_created',
        parameters: {
          'category': category.toLowerCase(),
          'duration_bucket': durationBucket,
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging listing_created: $e');
    }
  }

  /// Helper to convert arbitrary duration text into fixed low-cardinality buckets
  static String normalizeDurationBucket(String rawDuration) {
    final lower = rawDuration.toLowerCase().trim();
    if (lower.contains('saat') || lower.contains('1 gün') || lower.contains('aynı gün') || lower == 'standard') {
      return 'same_day';
    } else if (lower.contains('2 gün') || lower.contains('3 gün')) {
      return '1_3_days';
    } else if (lower.contains('4 gün') || lower.contains('5 gün') || lower.contains('6 gün') || lower.contains('1 hafta')) {
      return '4_7_days';
    } else if (lower.contains('hafta') || lower.contains('1 ay')) {
      return '1_4_weeks';
    } else if (lower.contains('ay')) {
      return 'over_1_month';
    }
    return 'unknown';
  }

  /// Log borrow request creation event.
  Future<void> logBorrowRequestCreated({
    required String category,
    required String durationBucket,
  }) async {
    try {
      final safeBucket = normalizeDurationBucket(durationBucket);
      await analytics.logEvent(
        name: 'borrow_request_created',
        parameters: {
          'category': category.toLowerCase(),
          'duration_bucket': safeBucket,
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging borrow_request_created: $e');
    }
  }

  /// Log borrow request status transition.
  Future<void> logBorrowRequestStatusChanged({
    required String requestStatus,
  }) async {
    try {
      await analytics.logEvent(
        name: 'borrow_request_status_changed',
        parameters: {
          'request_status': requestStatus.toLowerCase(),
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging status change: $e');
    }
  }

  /// Log chat message transmission.
  Future<void> logChatMessageSent({
    required String messageType, // 'text', 'proposal', 'system'
  }) async {
    try {
      await analytics.logEvent(
        name: 'chat_message_sent',
        parameters: {
          'message_type': messageType,
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging chat_message_sent: $e');
    }
  }

  /// Log favorite toggle action.
  Future<void> logFavoriteToggled({
    required String action, // 'add' or 'remove'
    required String category,
  }) async {
    try {
      await analytics.logEvent(
        name: 'favorite_toggled',
        parameters: {
          'action': action,
          'category': category.toLowerCase(),
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging favorite_toggled: $e');
    }
  }

  /// Log user block event.
  Future<void> logUserBlocked({
    required String source, // 'profile' or 'chat'
  }) async {
    try {
      await analytics.logEvent(
        name: 'user_blocked',
        parameters: {
          'source': source,
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging user_blocked: $e');
    }
  }

  /// Log report submission event.
  Future<void> logReportSubmitted({
    required String targetType, // 'listing', 'user', 'message'
    required String reason,
  }) async {
    try {
      await analytics.logEvent(
        name: 'report_submitted',
        parameters: {
          'target_type': targetType,
          'reason': reason,
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging report_submitted: $e');
    }
  }

  /// Log QR handover completion.
  Future<void> logQrHandoverCompleted({
    required String action, // 'borrow' or 'return'
    required bool success,
  }) async {
    try {
      await analytics.logEvent(
        name: 'qr_handover_completed',
        parameters: {
          'action': action,
          'success': success ? 'true' : 'false',
        },
      );
    } catch (e) {
      debugPrint('[AnalyticsService] Error logging qr_handover_completed: $e');
    }
  }
}
