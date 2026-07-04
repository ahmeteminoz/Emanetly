import 'package:flutter/material.dart';
import '../models/item.dart';
import '../providers/app_state_provider.dart';
import 'mock_route_screen.dart';

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

    // Determine category icon
    IconData categoryIcon = Icons.inventory_2_outlined;
    switch (currentItem.category) {
      case 'Elektronik':
        categoryIcon = Icons.devices_other;
        break;
      case 'Ders/Kitap':
        categoryIcon = Icons.menu_book_rounded;
        break;
      case 'Kırtasiye':
        categoryIcon = Icons.edit_note_rounded;
        break;
      case 'Yağmurluk/Şemsiye':
        categoryIcon = Icons.umbrella_rounded;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emanet Detayı'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              appState.isFavorite(currentItem.id) ? Icons.favorite : Icons.favorite_border,
              color: appState.isFavorite(currentItem.id) ? Colors.red : null,
            ),
            onPressed: () => appState.toggleFavorite(currentItem.id),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part 1: Large Marketplace Category Hero Image
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(currentItem.mockImageColorValue).withOpacity(0.85),
                      Color(currentItem.mockImageColorValue),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      categoryIcon,
                      size: 80,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentItem.category,
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Comments / Reviews Section
            Text(
              'Yorumlar & Değerlendirmeler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (currentItem.comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Bu eşya için henüz değerlendirme yapılmamış.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: currentItem.comments.map((comment) {
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      comment.authorName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    comment.authorName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                  const SizedBox(width: 2),
                                  Text(
                                    comment.rating.toString(),
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            comment.content,
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 32),

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
                          'Öğrenci Üye',
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

    // If item is currently in active transaction, show Rota Tracking button
    final isParticipant = isOwnItem || isBorrower;
    final inProgress = item.status != EmanetStatus.available;

    if (inProgress && isParticipant) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockRouteScreen(item: item),
                  ),
                );
              },
              icon: const Icon(Icons.navigation_rounded),
              label: const Text('Buluşma & Rota Takibine Git', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Fallback direct action button options
          if (isOwnItem && item.status == EmanetStatus.pendingApproval)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => appState.rejectBorrow(item.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showQrBottomSheet(context, item, 'borrow', item.borrowerId ?? '');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('QR Teslim Et'),
                  ),
                ),
              ],
            ),
          if (isOwnItem && item.status == EmanetStatus.pendingReturn)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showQrBottomSheet(context, item, 'return', item.borrowerId ?? '');
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('QR Doğrula & İade Al'),
              ),
            ),
        ],
      );
    }

    // Case 1: Current User is Lender (Own Item) and it's available
    if (isOwnItem) {
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

    // Case 2: Current User is Borrower / Stranger and it's available
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

    // Someone else borrowed it and not available
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
    BuildContext parentContext,
    EmanetItem item,
    String action,
    String userId,
  ) {
    final appState = AppStateProvider.of(parentContext);
    final theme = Theme.of(parentContext);

    final qrData = appState.qrService.generateQrData(
      itemId: item.id,
      action: action,
      userId: userId,
    );

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
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
                    Navigator.pop(sheetContext); // Close bottom sheet using sheetContext
                    
                    final success = await appState.processQrCode(qrData);

                    if (parentContext.mounted) {
                      if (success) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
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
                        ScaffoldMessenger.of(parentContext).showSnackBar(
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
