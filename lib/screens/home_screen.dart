import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import '../models/item.dart';
import '../models/borrow_request.dart';
import 'widgets/item_card.dart';
import 'request_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Hepsi';
  ViewMode _selectedViewMode = ViewMode.standardGrid;

  final List<String> _categories = [
    'Hepsi',
    'Elektronik',
    'Ders & Kırtasiye',
    'Spor & Hobi',
    'Günlük Eşya & Yaşam',
    'Diğer'
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Filter items based on search, category and owner (exclude current user's own items)
    final filteredItems = appState.items.where((item) {
      final isNotOwnItem = item.lenderId != appState.currentUser?.uid;
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Hepsi' || item.category == _selectedCategory;
      return isNotOwnItem && matchesSearch && matchesCategory;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Settings shortcut
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emanetly',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Görsel odaklı kampüs pazar yeri ve ödünçleşme',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Active incoming chat alerts banner
        (() {
          if (appState.currentUser == null) return const SizedBox.shrink();
          final myIncomingRequests = appState.borrowRequests.where((req) {
            return req.ownerId == appState.currentUser!.uid && req.status == BorrowRequestStatus.pendingDiscussion;
          }).toList();

          if (myIncomingRequests.isEmpty) return const SizedBox.shrink();

          final count = myIncomingRequests.length;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: ListTile(
                leading: Icon(Icons.mark_chat_unread, color: theme.colorScheme.onPrimaryContainer),
                title: Text(
                  'Yeni Görüşme Talebi ($count)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                subtitle: Text(
                  'Eşyalarınız için gelen soruları yanıtlayın.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.onPrimaryContainer),
                onTap: () {
                  if (count == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestChatScreen(requestId: myIncomingRequests.first.id),
                      ),
                    );
                  } else {
                    // Navigate to chat list index
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tüm sohbetleri görmek için alttaki Mesajlar sekmesine geçebilirsiniz.')),
                    );
                  }
                },
              ),
            ),
          );
        })(),

        // Search Bar Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Kampüste ne arıyorsunuz?',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),

        // Horizontal Categories List & View Mode Buttons
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          selectedColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const VerticalDivider(width: 8, indent: 12, endIndent: 12),
              // Compact Grid Button
              IconButton(
                icon: Icon(
                  Icons.grid_on_rounded,
                  size: 20,
                  color: _selectedViewMode == ViewMode.compactGrid
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                tooltip: 'Yoğun Görünüm',
                onPressed: () => setState(() => _selectedViewMode = ViewMode.compactGrid),
              ),
              // Standard Grid Button
              IconButton(
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 20,
                  color: _selectedViewMode == ViewMode.standardGrid
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                tooltip: 'Standart Görünüm',
                onPressed: () => setState(() => _selectedViewMode = ViewMode.standardGrid),
              ),
              // Large Cards Button
              IconButton(
                icon: Icon(
                  Icons.view_headline_rounded,
                  size: 20,
                  color: _selectedViewMode == ViewMode.largeCards
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
                tooltip: 'Geniş Kartlar',
                onPressed: () => setState(() => _selectedViewMode = ViewMode.largeCards),
              ),
            ],
          ),
        ),

        // Product Listings Feed Area
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Eşya bulunamadı',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : _selectedViewMode == ViewMode.largeCards
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return ItemCard(
                          item: filteredItems[index],
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
                        childAspectRatio: _selectedViewMode == ViewMode.compactGrid ? 1.0 : 0.72,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return ItemCard(
                          item: filteredItems[index],
                          viewMode: _selectedViewMode,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
