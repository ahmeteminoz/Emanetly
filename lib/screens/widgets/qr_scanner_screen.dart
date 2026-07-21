import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../providers/app_state_provider.dart';

class QrScannerScreen extends StatefulWidget {
  final String action; // 'borrow' or 'return'
  final String requestId;

  const QrScannerScreen({
    super.key,
    required this.action,
    required this.requestId,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  late AnimationController _animController;
  late Animation<double> _scannerLineAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scannerLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    final navigator = Navigator.of(context);
    final appState = AppStateProvider.of(context);
    final errorMessage = await appState.processQrCode(rawValue);

    if (!mounted) return;

    if (errorMessage == null) {
      // Başarılı okuma
      navigator.pop(true);
    } else {
      // Hata durumu
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Doğrulama Başarısız'),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = false;
                });
              },
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CloseButton(color: Colors.white),
        title: Text(
          widget.action == 'borrow' ? 'Emanet Teslim Al' : 'İadeyi Teslim Al',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Flash toggle button
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amber : Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          // Camera rotation button
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Scanner View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white54),
                      const SizedBox(height: 16),
                      const Text(
                        'Kameraya erişilemiyor.',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.errorDetails?.message ?? 'Lütfen kamera izinlerini kontrol edin.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Custom M3 Overlay & Vizor Painter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scannerLineAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ScannerOverlayPainter(
                    animationValue: _scannerLineAnimation.value,
                    theme: theme,
                  ),
                );
              },
            ),
          ),

          // 3. Fallback Simulation Button at the bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QR kodu vizörün ortasına hizalayın.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (kDebugMode)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Simüle Et (Kamerasız Test)'),
                      onPressed: () async {
                        if (_isProcessing) return;
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final appState = AppStateProvider.of(context);
                        
                        setState(() {
                          _isProcessing = true;
                        });
                        
                        // Generate matching mock QR data to trigger successful flow
                        final mockData = appState.qrService.generateQrData(
                          requestId: widget.requestId,
                          action: widget.action,
                        );
                        
                        final errorMessage = await appState.processQrCode(mockData);
                        if (!mounted) return;

                        if (errorMessage == null) {
                          navigator.pop(true);
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
                          );
                          setState(() {
                            _isProcessing = false;
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double animationValue;
  final ThemeData theme;

  ScannerOverlayPainter({
    required this.animationValue,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    // Define the vizor box size (260x260)
    final double vizorSize = 260.0;
    final double left = (width - vizorSize) / 2;
    final double top = (height - vizorSize) / 2.3;
    final Rect vizorRect = Rect.fromLTWH(left, top, vizorSize, vizorSize);
    final RRect vizorRRect = RRect.fromRectAndRadius(vizorRect, const Radius.circular(24));

    // 1. Draw darkened semi-transparent background around vizor
    final Paint maskPaint = Paint()..color = Colors.black.withOpacity(0.65);
    final Path maskPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, width, height))
      ..addRRect(vizorRRect);
    maskPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(maskPath, maskPaint);

    // 2. Draw vizor borders (Material 3 styling)
    final Paint borderPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(vizorRRect, borderPaint);

    // 3. Draw scanning laser animation line
    final Paint linePaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 2.0;

    final double currentLineY = top + (vizorSize * animationValue);
    canvas.drawLine(
      Offset(left + 12, currentLineY),
      Offset(left + vizorSize - 12, currentLineY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
