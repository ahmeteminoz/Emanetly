import 'package:flutter/material.dart';
import '../../models/item.dart';
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
    String statusText = 'Ödünç Alınabilir';
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
    }

    // RENDER LAYOUTS ACCORDING TO VIEW MODE
    
    // 1. COMPACT GRID VIEW
    if (viewMode == ViewMode.compactGrid) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Container
              AspectRatio(
                aspectRatio: 1.1,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(gradient: gradient),
                      child: Center(
                        child: Icon(categoryIcon, size: 36, color: Colors.white.withOpacity(0.9)),
                      ),
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
              // Body
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          rating,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Expanded(
                          child: Text(
                            isOwnItem ? 'Senin' : item.lenderName.split(' ')[0],
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 9),
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

    // 2. STANDARD GRID VIEW
    if (viewMode == ViewMode.standardGrid) {
      return Card(
        clipBehavior: Clip.antiAlias,
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
                    Container(
                      decoration: BoxDecoration(gradient: gradient),
                      child: Center(
                        child: Icon(categoryIcon, size: 48, color: Colors.white.withOpacity(0.9)),
                      ),
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
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: theme.colorScheme.primary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.location,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lender Name & Trust Rating
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          isOwnItem ? 'Senin İlanın' : item.lenderName.split(' ')[0],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            fontWeight: isOwnItem ? FontWeight.bold : FontWeight.normal,
                            color: isOwnItem ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
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

    // 3. LARGE CARDS VIEW
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
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
                  Container(
                    decoration: BoxDecoration(gradient: gradient),
                    child: Center(
                      child: Icon(categoryIcon, size: 64, color: Colors.white.withOpacity(0.9)),
                    ),
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
}
