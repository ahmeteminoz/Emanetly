import 'package:flutter/material.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'transaction_success_screen.dart';

class MockRouteScreen extends StatefulWidget {
  final EmanetItem item;
  const MockRouteScreen({super.key, required this.item});

  @override
  State<MockRouteScreen> createState() => _MockRouteScreenState();
}

class _MockRouteScreenState extends State<MockRouteScreen> {
  final _meetingPointController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meetingPointController.text = widget.item.meetingPoint ?? '';
  }

  @override
  void dispose() {
    _meetingPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Get fresh item data
    final currentItem = appState.items.firstWhere(
      (i) => i.id == widget.item.id,
      orElse: () => widget.item,
    );

    final isLender = currentItem.lenderId == appState.currentUser?.uid;
    final isBorrower = currentItem.borrowerId == appState.currentUser?.uid;

    if (currentItem.status == EmanetStatus.available || currentItem.status == EmanetStatus.archived) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeReq = appState.getRequestForActiveItem(widget.item.id);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionSuccessScreen(
              item: currentItem,
              targetUserId: isLender ? (currentItem.borrowerId ?? '') : currentItem.lenderId,
              targetName: isLender ? (currentItem.borrowerName ?? 'Ödünç Alan') : currentItem.lenderName,
              requestId: activeReq?.id ?? '',
            ),
          ),
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buluşma & Rota Takibi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Part 1: Custom Painted Mock Map
            Container(
              height: 250,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, 250),
                      painter: MockMapPainter(
                        status: currentItem.deliveryStatus ?? DeliveryStatus.requestSent,
                        theme: theme,
                      ),
                    ),
                    // Glassmorphic status label on map
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.map_outlined, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'Kampüs Haritası (Simüle)',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Part 2: Buluşma Noktası Bilgisi & Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emanet İşlemi: ${currentItem.title}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ortaklar: ${currentItem.lenderName} (Lender) ➔ ${currentItem.borrowerName} (Borrower)',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  
                  // Meeting point card
                  _buildMeetingPointCard(context, currentItem, isLender, appState),
                  const SizedBox(height: 24),
                  
                  // Delivery status timeline
                  Text(
                    'Teslimat Durumu',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDeliveryTimeline(context, currentItem.deliveryStatus ?? DeliveryStatus.requestSent),
                  const SizedBox(height: 24),
                  
                  // Simulation helper control buttons
                  _buildSimulationControls(context, currentItem, isLender, isBorrower, appState),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingPointCard(
    BuildContext context,
    EmanetItem item,
    bool isLender,
    AppState appState,
  ) {
    final theme = Theme.of(context);
    final hasMeetingPoint = item.meetingPoint != null && item.meetingPoint!.isNotEmpty;

    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_outlined, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Buluşma Noktası',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasMeetingPoint) ...[
              Text(
                item.meetingPoint!,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Lütfen bu konumda bir araya gelerek teslimatı tamamlayın.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ] else ...[
              Text(
                'Buluşma noktası henüz belirlenmedi.',
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            
            // Allow LENDER to set/change the meeting point if status is Accepted or Request Sent
            if (isLender && item.status == EmanetStatus.pendingApproval) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _meetingPointController,
                        decoration: const InputDecoration(
                          hintText: 'Buluşma noktası girin (örn. Kütüphane önü)...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final val = _meetingPointController.text.trim();
                      if (val.isNotEmpty) {
                        appState.setMeetingPoint(item.id, val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Buluşma noktası ayarlandı: $val')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                    child: const Text('Ayarla', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeline(BuildContext context, DeliveryStatus status) {
    final theme = Theme.of(context);
    final steps = [
      {'status': DeliveryStatus.requestSent, 'title': 'Talep Gönderildi'},
      {'status': DeliveryStatus.accepted, 'title': 'Kabul Edildi'},
      {'status': DeliveryStatus.meetingPointSet, 'title': 'Konum Belirlendi'},
      {'status': DeliveryStatus.routingStarted, 'title': 'Rotada / Yolda'},
      {'status': DeliveryStatus.delivered, 'title': 'Eşya Teslim Edildi'},
      {'status': DeliveryStatus.completed, 'title': 'İşlem Tamamlandı'},
    ];

    final activeIndex = steps.indexWhere((step) => step['status'] == status);

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        
        final isCompleted = index < activeIndex;
        final isActive = index == activeIndex;
        
        final color = isCompleted
            ? Colors.green
            : isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant;
                
        final icon = isCompleted
            ? Icons.check_circle
            : isActive
                ? Icons.radio_button_checked
                : Icons.radio_button_off;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(icon, size: 22, color: color),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 30,
                    color: index < activeIndex ? Colors.green : theme.colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  step['title'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : isCompleted
                            ? theme.colorScheme.onSurface.withOpacity(0.7)
                            : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showFeedbackDialog(
    BuildContext context,
    String targetUserId,
    String targetName,
    AppState appState,
    String requestId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        double currentRating = 5.0;
        final commentController = TextEditingController();
        final List<String> availableTags = ['Zamanında Teslim', 'Hızlı İletişim', 'Temiz Kullanım', 'Güvenilir'];
        final List<String> selectedTags = [];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$targetName Değerlendir')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Lütfen emanet süreç kalitesini değerlendirin:'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starVal = index + 1.0;
                        return IconButton(
                          icon: Icon(
                            starVal <= currentRating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              currentRating = starVal;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Deneyiminizi buraya yazın (isteğe bağlı)...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableTags.map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(tag),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                          selectedColor: theme.colorScheme.primary,
                          checkmarkColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  child: const Text('Atla'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final comment = commentController.text.trim();
                    String finalComment = comment.isNotEmpty ? comment : 'Sorunsuz ve güvenilir işlem.';
                    if (selectedTags.isNotEmpty) {
                      finalComment += ' (${selectedTags.join(', ')})';
                    }

                    appState.addUserReview(
                      targetUserId,
                      finalComment,
                      currentRating,
                      requestId,
                    );

                    Navigator.pop(context); // Close dialog

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Değerlendirmeniz başarıyla eklendi, güven puanı güncellendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSimulationControls(
    BuildContext context,
    EmanetItem item,
    bool isLender,
    bool isBorrower,
    AppState appState,
  ) {
    final theme = Theme.of(context);

    // If status is available (not active process), don't show controls
    if (item.status == EmanetStatus.available) {
      return const SizedBox();
    }

    Widget buildButton({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
      Color? color,
    }) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
    }

    // Timeline control flows based on who clicks what
    if (item.deliveryStatus == DeliveryStatus.requestSent) {
      if (isLender) {
        return buildButton(
          label: 'Talebi Kabul Et',
          icon: Icons.check,
          onPressed: () => appState.approveBorrow(item.id),
          color: Colors.green,
        );
      }
      return const Center(child: Text('Eşya sahibinin talebi kabul etmesi bekleniyor...'));
    }

    if (item.deliveryStatus == DeliveryStatus.accepted) {
      if (isLender) {
        return const Center(child: Text('Lütfen yukarıdaki panelden bir buluşma noktası belirleyin.'));
      }
      return const Center(child: Text('Eşya sahibinin buluşma noktası girmesi bekleniyor...'));
    }

    if (item.deliveryStatus == DeliveryStatus.meetingPointSet) {
      if (isBorrower) {
        return buildButton(
          label: 'Rotayı Başlat (Yola Çık)',
          icon: Icons.navigation_outlined,
          onPressed: () => appState.startRouting(item.id),
        );
      }
      return const Center(child: Text('Ödünç alan öğrencinin rotayı başlatıp buluşma noktasına gelmesi bekleniyor...'));
    }

    if (item.deliveryStatus == DeliveryStatus.routingStarted) {
      if (isLender) {
        return buildButton(
          label: 'QR Göster & Teslim Et',
          icon: Icons.qr_code,
          onPressed: () {
            appState.completeDelivery(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Eşya teslim edildi! Ödünç süreci başladı.'), backgroundColor: Colors.green),
            );
          },
          color: Colors.green,
        );
      }
      return buildButton(
        label: 'Teslim Aldım (Onayla)',
        icon: Icons.verified_user_outlined,
        onPressed: () {
          appState.completeDelivery(item.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eşya teslim alındı! Ödünç süreci başladı.'), backgroundColor: Colors.green),
          );
        },
        color: theme.colorScheme.secondary,
      );
    }

    // 1. Handover Complete / Active Borrow State Controls
    if (item.status == EmanetStatus.borrowed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isBorrower) ...[
            buildButton(
              label: 'İade Talebi Gönder (QR Göster)',
              icon: Icons.settings_backup_restore_rounded,
              onPressed: () {
                appState.requestReturn(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('İade talebi gönderildi. Eşya sahibinin onaylaması bekleniyor.')),
                );
              },
              color: Colors.deepPurple,
            ),
          ] else if (isLender) ...[
            const Center(
              child: Text(
                'Eşya şu an ödünçte. İade talebi bekleniyor...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      );
    }

    // 2. Return Request Submitted State Controls
    if (item.status == EmanetStatus.pendingReturn) {
      if (isLender) {
        return buildButton(
          label: 'İadeyi Onayla & Kapat',
          icon: Icons.done_all_rounded,
          onPressed: () {
            appState.approveReturn(item.id);
            Navigator.pop(context);
          },
          color: Colors.green,
        );
      }
      return const Center(child: Text('İade talebi iletildi. Eşya sahibinin onaylaması bekleniyor...'));
    }

    return const SizedBox();
  }
}

// Custom Painter to draw an interactive mock map
class MockMapPainter extends CustomPainter {
  final DeliveryStatus status;
  final ThemeData theme;

  MockMapPainter({required this.status, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = theme.colorScheme.outlineVariant.withOpacity(0.15)
      ..strokeWidth = 1.0;

    final double step = 25.0;

    // Draw grid background
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double j = 0; j < size.height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paintGrid);
    }

    // Draw campus buildings placeholders
    final paintBuilding = Paint()
      ..color = theme.colorScheme.primaryContainer.withOpacity(0.5)
      ..style = PaintingStyle.fill;
      
    final paintBuildingOutline = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Helper to draw building box
    void drawBuilding(Rect rect, String label) {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paintBuilding);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paintBuildingOutline);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2),
      );
    }

    // 3 campus buildings
    drawBuilding(const Rect.fromLTWH(20, 40, 90, 60), 'Kütüphane');
    drawBuilding(Rect.fromLTWH(size.width - 130, 40, 110, 60), 'Mühendislik');
    drawBuilding(const Rect.fromLTWH(100, 160, 120, 50), 'Öğrenci Cafesi');

    // Buluşma / Rota Çizimi
    // Start node: Mühendislik (lender location) -> (250, 70)
    // End node: Kütüphane (meeting location) -> (65, 70)
    final startOffset = Offset(size.width - 75, 70);
    final endOffset = Offset(65, 70);

    final paintRoute = Paint()
      ..color = theme.colorScheme.primary.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw path
    final path = Path();
    path.moveTo(startOffset.dx, startOffset.dy);
    // Draw route along student cafe Kantin
    path.lineTo(size.width / 2, 185);
    path.lineTo(endOffset.dx, endOffset.dy);
    canvas.drawPath(path, paintRoute);

    // If routing has started, let's draw a moving dot path or dashed path
    if (status == DeliveryStatus.routingStarted) {
      final paintActiveRoute = Paint()
        ..color = Colors.green
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final pathActive = Path();
      pathActive.moveTo(startOffset.dx, startOffset.dy);
      pathActive.lineTo(size.width / 2, 185);
      canvas.drawPath(pathActive, paintActiveRoute);
    }

    // Pin locations
    // 1. Lender Pin (Blue)
    final paintLenderPin = Paint()..color = theme.colorScheme.primary;
    canvas.drawCircle(startOffset, 8.0, paintLenderPin);
    canvas.drawCircle(startOffset, 12.0, Paint()..color = theme.colorScheme.primary.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    // 2. Meeting/End Pin (Red or secondary)
    final hasMeetingSet = status.index >= DeliveryStatus.meetingPointSet.index;
    final paintMeetingPin = Paint()..color = hasMeetingSet ? Colors.red : Colors.grey;
    canvas.drawCircle(endOffset, 8.0, paintMeetingPin);
    canvas.drawCircle(endOffset, 12.0, Paint()..color = (hasMeetingSet ? Colors.red : Colors.grey).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    // Draw moving borrower dot if routing started
    if (status == DeliveryStatus.routingStarted) {
      final paintBorrower = Paint()..color = Colors.blue;
      final borrowerPosition = Offset(size.width / 2, 185); // Simulating half-way there
      canvas.drawCircle(borrowerPosition, 6.0, paintBorrower);
      canvas.drawCircle(borrowerPosition, 10.0, Paint()..color = Colors.blue.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
