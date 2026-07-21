import 'dart:async';

class QrScanResult {
  final String requestId;
  final String action; // 'borrow' or 'return'
  final int timestamp;

  QrScanResult({
    required this.requestId,
    required this.action,
    required this.timestamp,
  });

  bool get isBorrow => action == 'borrow';
  bool get isReturn => action == 'return';
}

abstract class QrService {
  String generateQrData({required String requestId, required String action});
  Future<QrScanResult?> scanQrCode(String code);
}

class MockQrService implements QrService {
  @override
  String generateQrData({required String requestId, required String action}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'emanetly://handover?requestId=$requestId&action=$action&t=$timestamp';
  }

  @override
  Future<QrScanResult?> scanQrCode(String code) async {
    // 300ms yapay gecikme (tarama hissi için)
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final uri = Uri.parse(code);
      if (uri.scheme == 'emanetly' && uri.host == 'handover') {
        final requestId = uri.queryParameters['requestId'];
        final action = uri.queryParameters['action'];
        final tStr = uri.queryParameters['t'];
        if (requestId != null && action != null && tStr != null) {
          final timestamp = int.parse(tStr);
          return QrScanResult(
            requestId: requestId,
            action: action,
            timestamp: timestamp,
          );
        }
      }
    } catch (_) {
      // Ayrıştırma hatası
    }
    return null;
  }
}
