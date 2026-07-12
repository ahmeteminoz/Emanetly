import 'dart:async';

class QrScanResult {
  final String itemId;
  final String action; // 'borrow' or 'return'
  final String userId;

  QrScanResult({
    required this.itemId,
    required this.action,
    required this.userId,
  });

  bool get isBorrow => action == 'borrow';
  bool get isReturn => action == 'return';
}

abstract class QrService {
  String generateQrData({required String itemId, required String action, required String userId});
  Future<QrScanResult?> scanQrCode(String code);
}

class MockQrService implements QrService {
  @override
  String generateQrData({required String itemId, required String action, required String userId}) {
    return 'emanetly:///item/$itemId/$action/$userId';
  }

  @override
  Future<QrScanResult?> scanQrCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulating camera scanning
    try {
      final uri = Uri.parse(code);
      if (uri.scheme == 'emanetly' || uri.scheme == 'kampusemanet') {
        final segments = uri.pathSegments;
        if (segments.length >= 4 && segments[0] == 'item') {
          final itemId = segments[1];
          final action = segments[2];
          final userId = segments[3];
          return QrScanResult(itemId: itemId, action: action, userId: userId);
        }
      }
    } catch (_) {
      // Parse error
    }
    return null;
  }
}
