import 'dart:io';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/borrow_request.dart';
import '../models/user_profile.dart';
import '../providers/app_state_provider.dart';
import '../providers/app_state.dart';
import 'mock_route_screen.dart';
import 'request_chat_screen.dart';
import 'public_profile_screen.dart';
import 'widgets/full_screen_image_viewer.dart';
import 'widgets/qr_scanner_screen.dart';
import 'edit_item_screen.dart';

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
            (() {
              final activeIndexNotifier = ValueNotifier<int>(0);
              return AspectRatio(
                aspectRatio: 1.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: (() {
                            final images = currentItem.displayImages;
                            final gradient = LinearGradient(
                              colors: [
                                Color(currentItem.mockImageColorValue).withOpacity(0.85),
                                Color(currentItem.mockImageColorValue),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            );
                            
                            Widget fallback() => Container(
                                  decoration: BoxDecoration(gradient: gradient),
                                  child: Center(
                                    child: Icon(
                                      categoryIcon,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                );

                            if (images.isEmpty) {
                              return fallback();
                            }

                            return Stack(
                              children: [
                                PageView.builder(
                                  itemCount: images.length,
                                  onPageChanged: (index) {
                                    activeIndexNotifier.value = index;
                                  },
                                  itemBuilder: (context, index) {
                                    final imageUrl = images[index];
                                    Widget imageWidget;
                                    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
                                      imageWidget = Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => fallback(),
                                      );
                                    } else {
                                      imageWidget = Image.file(
                                        File(imageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => fallback(),
                                      );
                                    }

                                    final heroWidget = index == 0
                                        ? Hero(
                                            tag: 'item_detail_image_${currentItem.id}',
                                            child: imageWidget,
                                          )
                                        : imageWidget;

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => FullScreenImageViewer(
                                              imageUrls: images,
                                              initialIndex: index,
                                              heroTag: index == 0 ? 'item_detail_image_${currentItem.id}' : 'item_detail_image_${currentItem.id}_$index',
                                            ),
                                          ),
                                        );
                                      },
                                      child: heroWidget,
                                    );
                                  },
                                ),
                                
                                // Dot Indicator Overlay
                                if (images.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: ValueListenableBuilder<int>(
                                      valueListenable: activeIndexNotifier,
                                      builder: (context, activeIndex, child) {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(images.length, (dotIndex) {
                                            final isActive = activeIndex == dotIndex;
                                            return AnimatedContainer(
                                              duration: const Duration(milliseconds: 300),
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              width: isActive ? 12 : 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            );
                          })(),
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
              );
            })(),
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
      case EmanetStatus.archived:
        statusColor = Colors.grey;
        statusText = 'Arşivlendi';
        statusIcon = Icons.archive_outlined;
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
    final appState = AppStateProvider.of(context);
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
        FutureBuilder<UserProfile?>(
          future: appState.getUserProfile(item.lenderId),
          builder: (context, snapshot) {
            final lenderUser = snapshot.data ?? appState.availableMockUsers.firstWhere(
              (u) => u.uid == item.lenderId,
              orElse: () => appState.availableMockUsers.first,
            );

            return GestureDetector(
              onTap: isOwnItem
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PublicProfileScreen(userId: item.lenderId),
                        ),
                      );
                    },
              child: Container(
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
                        FutureBuilder<UserProfile?>(
                          future: appState.getUserProfile(item.lenderId),
                          builder: (context, snapshot) {
                            final profile = snapshot.data;
                            return CircleAvatar(
                              radius: 24,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              backgroundImage: (profile != null && profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                                  ? (profile.avatarUrl!.startsWith('http')
                                      ? NetworkImage(profile.avatarUrl!)
                                      : FileImage(File(profile.avatarUrl!)) as ImageProvider)
                                  : null,
                              child: (profile != null && profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                                  ? null
                                  : Text(
                                      item.lenderName[0].toUpperCase(),
                                      style: TextStyle(
                                        color: theme.colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            );
                          },
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
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${lenderUser.department} • Öğrenci',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  if (!isOwnItem) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '•   Profili Gör',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
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
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Trust Score and Transaction details
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Trust Rating
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            Text(
                              lenderUser.reviewCount == 0
                                  ? 'Henüz değerlendirilmedi'
                                  : '${lenderUser.averageRating} • ${lenderUser.reviewCount} yorum',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '(Güven Skoru: ${lenderUser.trustScore})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        // Response Time & Location
                        Text(
                          'Yanıt: ${lenderUser.avgResponseTime}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
                FutureBuilder<UserProfile?>(
                  future: appState.getUserProfile(item.borrowerId!),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: (profile != null && profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                          ? (profile.avatarUrl!.startsWith('http')
                              ? NetworkImage(profile.avatarUrl!)
                              : FileImage(File(profile.avatarUrl!)) as ImageProvider)
                          : null,
                      child: (profile != null && profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                          ? null
                          : Text(
                              item.borrowerName![0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
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
    final inProgress = item.status != EmanetStatus.available && item.status != EmanetStatus.archived;

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
                    child: const Text('QR Göster & Teslim Et'),
                  ),
                ),
              ],
            ),
          if (isBorrower && item.status == EmanetStatus.pendingApproval && item.deliveryStatus == DeliveryStatus.routingStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  BorrowRequestModel? activeRequest;
                  try {
                    activeRequest = appState.borrowRequests.firstWhere(
                      (r) => r.itemId == item.id && r.status == BorrowRequestStatus.accepted
                    );
                  } catch (_) {}
                  final requestId = activeRequest?.id ?? 'mock';

                  final scanned = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrScannerScreen(
                        action: 'borrow',
                        requestId: requestId,
                      ),
                    ),
                  );
                  if (scanned == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eşya başarıyla teslim alındı!'), backgroundColor: Colors.green),
                    );
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('QR Tara & Teslim Al'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (isBorrower && item.status == EmanetStatus.borrowed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showQrBottomSheet(context, item, 'return', item.lenderId);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('İade Et (QR Göster)'),
              ),
            ),
          if (isOwnItem && item.status == EmanetStatus.pendingReturn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  BorrowRequestModel? activeRequest;
                  try {
                    activeRequest = appState.borrowRequests.firstWhere(
                      (r) => r.itemId == item.id && r.status == BorrowRequestStatus.accepted
                    );
                  } catch (_) {}
                  final requestId = activeRequest?.id ?? 'mock';

                  final scanned = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QrScannerScreen(
                        action: 'return',
                        requestId: requestId,
                      ),
                    ),
                  );
                  if (scanned == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Eşya başarıyla iade alındı!'), backgroundColor: Colors.green),
                    );
                  }
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('QR Tara & İade Al'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      );
    }

    // Case 1: Current User is Lender (Own Item) and it's available or archived
    if (isOwnItem && (item.status == EmanetStatus.available || item.status == EmanetStatus.archived)) {
      final isArchived = item.status == EmanetStatus.archived;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isArchived ? Colors.grey.shade100 : theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isArchived ? Colors.grey.shade300 : theme.colorScheme.primary.withOpacity(0.2)
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isArchived ? Icons.archive_outlined : Icons.check_circle_outline_rounded,
                  color: isArchived ? Colors.grey.shade700 : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArchived
                        ? 'İlanınız arşivlendi. Diğer kullanıcılar bu ilanı göremez.'
                        : 'İlanınız yayında ve aktif. Ödünç talebi alabilirsiniz.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isArchived ? Colors.grey.shade800 : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // 1. Edit Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditItemScreen(item: item),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Düzenle'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 2. Pause/Publish Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await appState.toggleItemArchive(item.id, !isArchived);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isArchived 
                                ? 'İlan başarıyla arşivden çıkarıldı ve yayına alındı!' 
                                : 'İlan başarıyla arşivlendi.'
                          ),
                          backgroundColor: isArchived ? Colors.green : Colors.grey.shade800,
                        ),
                      );
                    }
                  },
                  icon: Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 18),
                  label: Text(isArchived ? 'Yayınla' : 'Arşivle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 3. Delete Button (Danger Zone)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('İlanı Sil?'),
                    content: const Text('Bu ilanı tamamen silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context); // close dialog
                          await appState.deleteItem(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('İlan başarıyla silindi.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            Navigator.pop(context); // return to home
                          }
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Evet, Sil'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('İlanı Tamamen Sil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // Case 1.5: Current user has an active request on this item under discussion
    final activeRequest = appState.getRequestForActiveItem(item.id);
    if (activeRequest != null && activeRequest.requesterId == appState.currentUser?.uid) {
      if (activeRequest.status == BorrowRequestStatus.onlyInquiry) {
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestChatScreen(requestId: activeRequest.id),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Soru Sor'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  _showDurationSelectionSheet(context, (selectedDuration) async {
                    await appState.upgradeToOfficialRequest(activeRequest.id, requestedDurationText: selectedDuration);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ödünç talebi başarıyla iletildi!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestChatScreen(requestId: activeRequest.id),
                        ),
                      );
                    }
                  });
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
            ),
          ],
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestChatScreen(requestId: activeRequest.id),
              ),
            );
          },
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Ön Görüşme Odasına Git'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    // Case 2: Current User is Borrower / Stranger and it's available
    if (item.status == EmanetStatus.available) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'Kesin buluşma noktası talep sonrası chat içinde belirlenir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Soru Sor / Chat Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _showInquirySheet(context, theme, appState, item),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Soru Sor'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Ödünç Talep Et Button
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: () {
                    _showDurationSelectionSheet(context, (selectedDuration) async {
                      final request = await appState.requestBorrow(
                        item.id,
                        isOfficialRequest: true,
                        requestedDurationText: selectedDuration,
                      );
                      if (context.mounted && request != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ödünç talebi ve ön görüşme odası oluşturuldu!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestChatScreen(requestId: request.id),
                          ),
                        );
                      }
                    });
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
              ),
            ],
          ),
        ],
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

  void _showDurationSelectionSheet(BuildContext context, Function(String duration) onSelected) {
    final theme = Theme.of(context);
    final options = ['1 Saat', '2 Saat', '6 Saat', '1 Gün', '3 Gün', '1 Hafta'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ödünç Alma Süresi Seçin',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...options.map((option) {
                  return ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text(option),
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(option);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
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

    // Find the associated active request
    BorrowRequestModel? activeRequest;
    try {
      activeRequest = appState.borrowRequests.firstWhere(
        (r) => r.itemId == item.id && 
               (r.status == BorrowRequestStatus.accepted ||
                r.status == BorrowRequestStatus.pendingDiscussion ||
                r.status == BorrowRequestStatus.onlyInquiry ||
                r.status == BorrowRequestStatus.completed)
      );
    } catch (_) {}

    final requestId = activeRequest?.id ?? 'mock_request_id_${item.id}';

    final qrData = appState.qrService.generateQrData(
      requestId: requestId,
      action: action,
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
                    
                    final errorMessage = await appState.processQrCode(qrData);

                    if (parentContext.mounted) {
                      if (errorMessage == null) {
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
                          SnackBar(
                            content: Text(errorMessage),
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

  void _showInquirySheet(
    BuildContext context,
    ThemeData theme,
    AppState appState,
    EmanetItem currentItem,
  ) {
    final TextEditingController questionController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'İlan Sahibine Soru Sor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '"${currentItem.title}" ilanı hakkında merak ettiğiniz soruyu yazın. İlk mesajı gönderdiğinizde sohbet odası oluşturulacaktır.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: questionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Sorunuzu buraya yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final text = questionController.text.trim();
                  if (text.isEmpty) return;

                  Navigator.pop(context); // Close sheet

                  final request = await appState.requestBorrow(currentItem.id, isOfficialRequest: false);
                  if (request != null) {
                    await appState.sendChatMessage(request.id, text);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestChatScreen(requestId: request.id),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Soruyu Gönder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
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
