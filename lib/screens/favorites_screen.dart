import 'package:flutter/material.dart';
import '../providers/app_state_provider.dart';
import '../providers/app_state.dart';
import 'widgets/item_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Filter items that are favorited
    final favoritedItems = appState.items
        .where((item) => appState.isFavorite(item.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
        centerTitle: true,
      ),
      body: favoritedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz favori ilanınız yok',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Beğendiğiniz ürünlerin kalbine basarak daha sonra kolayca bulmak üzere buraya kaydedebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Beğendiğiniz İlanlar (${favoritedItems.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: appState.gridViewMode == ViewMode.largeCards
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: favoritedItems.length,
                          itemBuilder: (context, index) {
                            return ItemCard(
                              item: favoritedItems[index],
                              viewMode: ViewMode.largeCards,
                            );
                          },
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: appState.gridViewMode == ViewMode.compactGrid ? 1.0 : 0.8,
                          ),
                          itemCount: favoritedItems.length,
                          itemBuilder: (context, index) {
                            return ItemCard(
                              item: favoritedItems[index],
                              viewMode: appState.gridViewMode,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
