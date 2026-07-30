import 'package:flutter_test/flutter_test.dart';
import 'package:emanetly/services/block_service.dart';

void main() {
  group('BlockedUserModel Tests', () {
    test('BlockedUserModel toMap creates correct structure with source', () {
      final model = BlockedUserModel(
        blockedUserId: 'user_xyz',
        createdAt: DateTime.now(),
        source: 'chat',
      );

      final map = model.toMap();
      expect(map['blockedUserId'], equals('user_xyz'));
      expect(map['source'], equals('chat'));
      expect(map.containsKey('createdAt'), isTrue);
    });

    test('BlockedUserModel.fromMap parses map fields correctly', () {
      final map = {
        'blockedUserId': 'user_abc',
        'createdAt': '2026-07-31T02:00:00.000Z',
        'source': 'profile',
      };

      final model = BlockedUserModel.fromMap(map, 'user_abc');
      expect(model.blockedUserId, equals('user_abc'));
      expect(model.source, equals('profile'));
    });
  });
}
