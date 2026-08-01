import 'package:flutter_test/flutter_test.dart';
import 'package:emanetly/services/crashlytics_service.dart';

void main() {
  group('CrashlyticsService Noise Filter Tests', () {
    late CrashlyticsService crashlyticsService;

    setUp(() {
      crashlyticsService = CrashlyticsService();
    });

    test('Filters network offline and socket exceptions as expected noise', () {
      expect(
        crashlyticsService.isNoiseError('SocketException: Connection refused'),
        isTrue,
      );
      expect(
        crashlyticsService.isNoiseError('ClientException: Software caused connection abort'),
        isTrue,
      );
      expect(
        crashlyticsService.isNoiseError('firebase_core/unavailable'),
        isTrue,
      );
    });

    test('Filters user cancellation errors as expected noise', () {
      expect(
        crashlyticsService.isNoiseError('user_cancelled image selection'),
        isTrue,
      );
      expect(
        crashlyticsService.isNoiseError('Operation canceled by user'),
        isTrue,
      );
    });

    test('Filters expected permission-denied errors as noise', () {
      expect(
        crashlyticsService.isNoiseError('firebase_firestore/permission-denied'),
        isTrue,
      );
    });

    test('Allows real unexpected system errors to pass noise filter', () {
      expect(
        crashlyticsService.isNoiseError('FormatException: Unexpected character at L10'),
        isFalse,
      );
      expect(
        crashlyticsService.isNoiseError('StateError: Bad state: No element'),
        isFalse,
      );
      expect(
        crashlyticsService.isNoiseError('NoSuchMethodError: The getter was called on null'),
        isFalse,
      );
    });
  });
}
