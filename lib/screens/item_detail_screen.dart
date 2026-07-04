import 'package:flutter/material.dart';
import '../models/item.dart';
import '../providers/app_state_provider.dart';

class ItemDetailScreen extends StatelessWidget {
  final EmanetItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Get fresh item reference from state in case of updates
    final currentItem = appState.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    final isOwnItem = currentItem.lenderId == appState.currentUser?.uid;
    final isBorrower = currentItem.borrowerId == appState.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emanet Detayı'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Status Header Card
            _buildStatusHeader(context, currentItem),
            const SizedBox(height: 20),

            // Item Title
            Text(
              currentItem.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Location & Date
            Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  currentItem.location,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, color: theme.colorScheme.outline, size: 18),
                const SizedBox(width: 4),
                Text(
                  _formatDate(currentItem.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Description
            Text(
              'Açıklama',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentItem.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Lender Info
            _buildUserInfoSection(context, currentItem, isOwnItem, isBorrower),
            const SizedBox(height: 40),

            // Action Buttons
            _buildActionsSection(context, currentItem, isOwnItem, isBorrower),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, EmanetItem item) {
    final theme = Theme.of(context);
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (item.status) {
      case EmanetStatus.available:
        statusColor = Colors.green;
        statusText = 'Ödünç Alınabilir';
        statusIcon = Icons.check_circle_outline;
        break;
      case EmanetStatus.pendingApproval:
        statusColor = Colors.orange;
        statusText = 'Talep Onayı Bekliyor';
        statusIcon = Icons.hourglass_empty;
        break;
      case EmanetStatus.borrowed:
        statusColor = Colors.red;
        statusText = 'Ödünç Verildi';
        statusIcon = Icons.remove_circle_outline;
        break;
      case EmanetStatus.pendingReturn:
        statusColor = Colors.deepPurple;
        statusText = 'İade Onayı Bekliyor';
        statusIcon = Icons.assignment_return_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Kategori: ${item.category}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(
    BuildContext context,
    EmanetItem item,
    bool isOwnItem,
    bool isBorrower,
  ) {
    final theme = Theme.of(context);
    final lenderText = isOwnItem ? 'Sen (Eşya Sahibi)' : item.lenderName;

    // Determine trust score mock values
    String rating = '4.9';
    String transactions = '54';
    String badgeText = 'Güvenilir Üye';
    Color badgeColor = Colors.teal;

    if (item.lenderId == 'user_1') {
      rating = '4.8';
      transactions = '32';
      badgeText = 'Popüler Paylaşımcı';
      badgeColor = Colors.indigo;
    } else if (item.lenderId == 'user_3') {
      rating = '4.7';
      transactions = '15';
      badgeText = 'Hızlı Yanıt';
      badgeColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eşya Sahibi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      item.lenderName[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lenderText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Öğrenci Üye', // General label
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isOwnItem)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'İlanım',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Trust Score and Transaction details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Trust Rating
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($transactions işlem)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      badgeText,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (item.borrowerName != null) ...[
          const SizedBox(height: 20),
          Text(
            item.status == EmanetStatus.pendingApproval
                ? 'Ödünç Almak İsteyen'
                : item.status == EmanetStatus.pendingReturn
                    ? 'İade Etmek İsteyen'
                    : 'Ödünç Alan Öğrenci',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    item.borrowerName![0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBorrower ? 'Sen' : item.borrowerName!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Öğrenci',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    EmanetItem item,
    bool isOwnItem,
    bool isBorrower,
  ) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Case 1: Current User is Lender (Own Item)
    if (isOwnItem) {
      if (item.status == EmanetStatus.pendingApproval) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => appState.rejectBorrow(item.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Talebi Reddet'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _showQrBottomSheet(context, item, 'borrow', item.borrowerId ?? '');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code),
                    SizedBox(width: 8),
                    Text('QR ile Teslim Et'),
                  ],
                ),
              ),
            ),
          ],
        );
      }

      if (item.status == EmanetStatus.pendingReturn) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              _showQrBottomSheet(context, item, 'return', item.borrowerId ?? '');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner),
                SizedBox(width: 8),
                Text('QR Doğrula & İade Al'),
              ],
            ),
          ),
        );
      }

      if (item.status == EmanetStatus.borrowed) {
        return Center(
          child: Text(
            'Bu eşya şu an ödünç verilmiş durumda. İade talebi bekleniyor.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      return Center(
        child: Text(
          'İlanınız aktif ve ödünç alınmayı bekliyor.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Case 2: Current User is Borrower / Stranger
    if (item.status == EmanetStatus.available) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            final success = await appState.requestBorrow(item.id);
            if (context.mounted && success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ödünç talebiniz iletildi. Onay bekleniyor.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Ödünç Talep Et',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (item.status == EmanetStatus.pendingApproval && isBorrower) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              'Ödünç talebiniz onay bekliyor.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Eşya sahibi onay verdiğinde teslimat QR kodu oluşturulacaktır.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (item.status == EmanetStatus.borrowed && isBorrower) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final success = await appState.requestReturn(item.id);
                if (context.mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('İade talebiniz iletildi. Teslim edebilirsiniz.'),
                      backgroundColor: Colors.deepPurple,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('İade Talebi Gönder'),
            ),
          ),
        ],
      );
    }

    if (item.status == EmanetStatus.pendingReturn && isBorrower) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code, color: Colors.deepPurple, size: 40),
            const SizedBox(height: 12),
            Text(
              'İade Talebi Onay Bekliyor',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sahibi iadeyi onaylayana kadar bekleyiniz.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Someone else borrowed it
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Bu eşya şu an başka bir öğrenci tarafından ödünç alınmış.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.red[800],
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showQrBottomSheet(
    BuildContext context,
    EmanetItem item,
    String action,
    String userId,
  ) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    final qrData = appState.qrService.generateQrData(
      itemId: item.id,
      action: action,
      userId: userId,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                action == 'borrow' ? 'Emanet Teslim QR Kodu' : 'İade Alım QR Kodu',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              Text(
                action == 'borrow'
                    ? 'Eşyayı alan öğrencinin bu QR kodu kendi kamerasından taramasını sağlayın.'
                    : 'İade eden öğrencinin size eşyayı getirmesiyle bu QR kodunu taranabilir yapın.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 32),

              // Mock QR Code Render
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: MockQrPainter(),
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Kod: $qrData',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 32),

              // Simulation Button for Prototype testing
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close bottom sheet
                    
                    // Show progress loader
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    final success = await appState.processQrCode(qrData);

                    if (context.mounted) {
                      Navigator.pop(context); // Remove progress loader
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              action == 'borrow'
                                  ? 'Emanet başarıyla teslim edildi!'
                                  : 'İade başarıyla onaylandı ve eşya geri alındı!',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR Kod geçersiz veya hata oluştu.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Karşı Taraf Taramasını Simüle Et (Prototip)'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Custom Painter to draw a mock QR Code pattern
class MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final double squareSize = size.width / 7;

    // Helper to draw alignment blocks (corners)
    void drawCorner(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, squareSize * 3, squareSize * 3), paint);
      
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(x + squareSize, y + squareSize, squareSize, squareSize),
        whitePaint,
      );
    }

    // Top-Left corner
    drawCorner(0, 0);

    // Top-Right corner
    drawCorner(size.width - squareSize * 3, 0);

    // Bottom-Left corner
    drawCorner(0, size.height - squareSize * 3);

    // Draw some random pixels inside to look like a QR code
    final dots = [
      [3, 3], [3, 4], [4, 3], [4, 5],
      [1, 4], [2, 4], [4, 1], [4, 2],
      [5, 3], [5, 4], [5, 5], [6, 4],
      [3, 1], [3, 2], [5, 1], [5, 2],
      [1, 5], [2, 5], [6, 1], [6, 2],
    ];

    for (final dot in dots) {
      canvas.drawRect(
        Rect.fromLTWH(
          dot[0] * squareSize,
          dot[1] * squareSize,
          squareSize,
          squareSize,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
