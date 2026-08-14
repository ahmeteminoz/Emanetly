import 'package:flutter_test/flutter_test.dart';
import 'package:emanetly/models/item.dart';

void main() {
  group('EmanetItem Model Tests', () {
    test('EmanetItem.fromMap parses valid lenderName successfully', () {
      final map = {
        'id': 'item_1',
        'title': 'Test Item',
        'lenderId': 'user_1',
        'lenderName': 'Ahmet Emin',
        'status': 'available',
        'createdAt': '2026-08-01T21:00:00.000Z',
      };

      final item = EmanetItem.fromMap(map);
      expect(item.lenderName, equals('Ahmet Emin'));
    });

    test('EmanetItem.fromMap handles missing/null lenderName safely', () {
      final map = {
        'id': 'item_2',
        'title': 'Test Item No Name',
        'lenderId': 'user_2',
        'lenderName': null,
        'status': 'available',
        'createdAt': '2026-08-01T21:00:00.000Z',
      };

      final item = EmanetItem.fromMap(map);
      expect(item.lenderName, equals(''));
    });

    test('EmanetItem.fromMap handles non-string lenderName safely', () {
      final map = {
        'id': 'item_3',
        'title': 'Test Item Int Name',
        'lenderId': 'user_3',
        'lenderName': 12345,
        'status': 'available',
        'createdAt': '2026-08-01T21:00:00.000Z',
      };

      final item = EmanetItem.fromMap(map);
      expect(item.lenderName, equals('12345'));
    });
  });
}
