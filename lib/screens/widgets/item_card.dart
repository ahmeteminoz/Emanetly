import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/borrow_request.dart';
import '../../providers/app_state.dart';
import '../../providers/app_state_provider.dart';
import '../item_detail_screen.dart';

class ItemCard extends StatelessWidget {
  final EmanetItem item;
  final ViewMode viewMode;

  const ItemCard({
    super.key,
    required this.item,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final isOwnItem = item.lenderId == appState.currentUser?.uid;

    // Determine category icon
    IconData categoryIcon = Icons.inventory_2_outlined;
    switch (item.category) {
      case 'Elektronik':
        categoryIcon = Icons.devices_other;
        break;
      case 'Ders & Kırtasiye':
        categoryIcon = Icons.menu_book_rounded;
        break;
      case 'Spor & Hobi':
        categoryIcon = Icons.sports_volleyball_outlined;
        break;
      case 'Günlük Eşya & Yaşam':
        categoryIcon = Icons.shopping_bag_outlined;
        break;
    }

    // Colors
    final primaryColor = Color(item.mockImageColorValue);
    final gradient = LinearGradient(
      colors: [
        primaryColor.withOpacity(0.85),
        primaryColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Determine trust score mock rating
    String rating = '4.9';
    if (item.lenderId == 'user_1') {
      rating = '4.8';
    } else if (item.lenderId == 'user_3') {
      rating = '4.7';
    }

    // Determine status badge color
    Color statusColor = Colors.green;
    String statusText = 'Açık';

    final activeRequest = appState.getRequestForActiveItem(item.id);
    if (activeRequest != null && activeRequest.status == BorrowRequestStatus.pendingDiscussion) {
      statusColor = Colors.orange;
      statusText = 'Talep Var';
    } else {
      switch (item.status) {
        case EmanetStatus.available:
          statusColor = Colors.green;
          statusText = 'Açık';
          break;
        case EmanetStatus.pendingApproval:
          statusColor = Colors.orange;
          statusText = 'Talep Var';
          break;
        case EmanetStatus.borrowed:
          statusColor = Colors.red;
          statusText = 'Ödünçte';
          break;
        case EmanetStatus.pendingReturn:
          statusColor = Colors.deepPurple;
          statusText = 'İade Sırada';
          break;
        case EmanetStatus.archived:
          statusColor = Colors.grey;
          statusText = 'Arşivlendi';
          break;
      }
    }

    // RENDER LAYOUTS ACCORDING TO VIEW MODE
    
    // 1. COMPACT GRID VIEW (Very clean and dense - Overflow-proof)
    if (viewMode == ViewMode.compactGrid) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          child: AspectRatio(
            aspectRatio: 1.0, // Square photo
            child: Stack(
              children: [
                _buildItemImage(
                  imageUrl: item.imageUrl,
                  iconSize: 36,
                  categoryIcon: categoryIcon,
                  gradient: gradient,
                ),
                // Favorite Heart Button (Top-Right)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _buildFavoriteButton(appState, context),
                ),
                // Status Badge (Bottom-Left)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. STANDARD GRID VIEW (Dolap Style: Photo & Detailed Info - Overflow-proof)
    if (viewMode == ViewMode.standardGrid) {
      return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Container
              AspectRatio(
                aspectRatio: 1.0, // Square image
                child: Stack(
                  children: [
                    _buildItemImage(
                      imageUrl: item.imageUrl,
                      iconSize: 48,
                      categoryIcon: categoryIcon,
                      gradient: gradient,
                    ),
                    // Favorite Heart Button (Top-Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildFavoriteButton(appState, context),
                    ),
                    // Status Badge (Top-Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    // Trust Rating Badge (Bottom-Right)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Body (Clean & Overflow-proof Layout)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 11, color: theme.colorScheme.outline),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                item.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Maks: 3g',
                              style: TextStyle(
                                      fontSize: 9,
                                color: theme.colorScheme.outline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. LARGE CARDS VIEW (Full Details banner style)
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: () => _navigateToDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Container
            AspectRatio(
              aspectRatio: 1.7, // Wide banner image
              child: Stack(
                children: [
                  _buildItemImage(
                    imageUrl: item.imageUrl,
                    iconSize: 64,
                    categoryIcon: categoryIcon,
                    gradient: gradient,
                  ),
                  // Favorite Heart Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _buildFavoriteButton(appState, context),
                  ),
                  // Status Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Category tag bottom left
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Trust Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            item.location,
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        isOwnItem ? 'Senin İlanın' : 'Paylaşan: ${item.lenderName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isOwnItem ? FontWeight.bold : FontWeight.normal,
                          color: isOwnItem ? theme.colorScheme.primary : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(AppState appState, BuildContext context) {
    final isFavorited = appState.isFavorite(item.id);
    return ClipOval(
      child: Container(
        color: Colors.white.withOpacity(0.9),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => appState.toggleFavorite(item.id),
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.red : Colors.grey.shade700,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    );
  }

  Widget _buildItemImage({
    required String? imageUrl,
    required double iconSize,
    required IconData categoryIcon,
    required Gradient gradient,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(gradient: gradient),
            child: Center(
              child: Icon(categoryIcon, size: iconSize, color: Colors.white.withOpacity(0.9)),
            ),
          ),
        );
      } else {
        return Image.file(
          File(imageUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(gradient: gradient),
            child: Center(
              child: Icon(categoryIcon, size: iconSize, color: Colors.white.withOpacity(0.9)),
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: Icon(categoryIcon, size: iconSize, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }
}
