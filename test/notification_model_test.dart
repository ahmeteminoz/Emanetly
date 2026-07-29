import 'package:flutter_test/flutter_test.dart';
import 'package:emanetly/models/notification_model.dart';

void main() {
  group('AppNotification Model Tests', () {
    test('isRead returns true when readAt is set, and false when readAt is null', () {
      final unread = AppNotification(
        id: 'notif_1',
        type: 'chat',
        title: 'Test Title',
        body: 'Test Body',
        readAt: null,
      );

      final read = AppNotification(
        id: 'notif_2',
        type: 'accepted',
        title: 'Test Title 2',
        body: 'Test Body 2',
        readAt: DateTime.now(),
      );

      expect(unread.isRead, isFalse);
      expect(read.isRead, isTrue);
      expect(unread.id, equals('notif_1'));
    });
  });
}
