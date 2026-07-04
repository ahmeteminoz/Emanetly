import 'package:flutter/material.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'widgets/item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Hepsi';

  final List<String> _categories = [
    'Hepsi',
    'Elektronik',
    'Ders/Kitap',
    'Kırtasiye',
    'Yağmurluk/Şemsiye',
    'Diğer'
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Filter items based on search and category
    final filteredItems = appState.items.where((item) {
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Hepsi' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
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
                'Kampüs Emanet',
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

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Eşya ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
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

        // Horizontal Categories List
        SizedBox(
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

        // Layout controller toolbar: "X ilan bulundu" & Grid style buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${filteredItems.length} İlan Listeleniyor',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Layout style toggles
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_on, size: 18),
                      tooltip: 'Compact',
                      color: appState.gridViewMode == ViewMode.compactGrid
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      onPressed: () => appState.changeViewMode(ViewMode.compactGrid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.grid_view, size: 18),
                      tooltip: 'Standard',
                      color: appState.gridViewMode == ViewMode.standardGrid
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      onPressed: () => appState.changeViewMode(ViewMode.standardGrid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.view_headline, size: 18),
                      tooltip: 'Large',
                      color: appState.gridViewMode == ViewMode.largeCards
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      onPressed: () => appState.changeViewMode(ViewMode.largeCards),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items List or Grid
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
              : appState.gridViewMode == ViewMode.largeCards
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
                        childAspectRatio: appState.gridViewMode == ViewMode.compactGrid ? 0.8 : 0.64,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        return ItemCard(
                          item: filteredItems[index],
                          viewMode: appState.gridViewMode,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
