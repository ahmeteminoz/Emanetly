import 'dart:async';
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
  List<String> _selectedCategories = ['Hepsi'];
  ViewMode _selectedViewMode = ViewMode.standardGrid;

  // Premium Micro-interaction states
  bool _isCategoryExpanded = false;
  bool _isViewSelectorExpanded = false;
  Timer? _viewSelectorTimer;

  final List<String> _categories = [
    'Hepsi',
    'Elektronik',
    'Ders & Kırtasiye',
    'Spor & Hobi',
    'Günlük Eşya & Yaşam',
    'Diğer'
  ];

  @override
  void dispose() {
    _viewSelectorTimer?.cancel();
    super.dispose();
  }

  // Starts or resets the 5-second auto-collapse timer for view selector
  void _startViewSelectorTimer() {
    _viewSelectorTimer?.cancel();
    _viewSelectorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isViewSelectorExpanded = false;
        });
      }
    });
  }

  // Get icon based on current selected ViewMode
  IconData _getViewModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.compactGrid:
        return Icons.grid_on_rounded;
      case ViewMode.standardGrid:
        return Icons.grid_view_rounded;
      case ViewMode.largeCards:
        return Icons.view_headline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Filter items based on search, category and owner (exclude current user's own items)
    final filteredItems = appState.items.where((item) {
      final isNotOwnItem = item.lenderId != appState.currentUser?.uid;
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategories.contains('Hepsi') ||
          _selectedCategories.contains(item.category);
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

        // Horizontal Categories & View Mode Selector Row (Minimalist Micro-interaction)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              // 1. FILTER ICON & EXPANDABLE CATEGORIES
              IconButton(
                icon: Icon(
                  _isCategoryExpanded ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'Filtrele',
                onPressed: () {
                  setState(() {
                    _isCategoryExpanded = !_isCategoryExpanded;
                  });
                },
              ),
              
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: !_isCategoryExpanded
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCategoryExpanded = true;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 4.0),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.15)),
                              ),
                              child: Text(
                                (() {
                                  if (_selectedCategories.contains('Hepsi')) {
                                    return 'Kategori: Hepsi';
                                  } else if (_selectedCategories.length == 1) {
                                    return 'Kategori: ${_selectedCategories.first}';
                                  } else {
                                    return 'Kategori: ${_selectedCategories.length} Seçili';
                                  }
                                })(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 42,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategories.contains(cat);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: FilterChip(
                                  label: Text(cat, style: const TextStyle(fontSize: 11.5)),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (cat == 'Hepsi') {
                                        _selectedCategories = ['Hepsi'];
                                      } else {
                                        _selectedCategories.remove('Hepsi');
                                        if (selected) {
                                          _selectedCategories.add(cat);
                                        } else {
                                          _selectedCategories.remove(cat);
                                        }
                                        if (_selectedCategories.isEmpty) {
                                          _selectedCategories.add('Hepsi');
                                        }
                                      }
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
              ),

              const SizedBox(width: 8),

              // 2. EXPANDABLE VIEW MODE SELECTOR WITH 5s AUTO-COLLAPSE & ANIMATION
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                ),
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 200),
                  firstCurve: Curves.easeOut,
                  secondCurve: Curves.easeIn,
                  sizeCurve: Curves.easeInOut,
                  crossFadeState: _isViewSelectorExpanded 
                      ? CrossFadeState.showSecond 
                      : CrossFadeState.showFirst,
                  firstChild: IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8.0),
                    icon: Icon(
                      _getViewModeIcon(_selectedViewMode),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    tooltip: 'Görünümü Değiştir',
                    onPressed: () {
                      setState(() {
                        _isViewSelectorExpanded = true;
                      });
                      _startViewSelectorTimer();
                    },
                  ),
                  secondChild: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact Grid
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8.0),
                          icon: Icon(
                            Icons.grid_on_rounded,
                            size: 18,
                            color: _selectedViewMode == ViewMode.compactGrid
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          onPressed: () {
                            if (_selectedViewMode == ViewMode.compactGrid) {
                              setState(() {
                                _isViewSelectorExpanded = false;
                              });
                              _viewSelectorTimer?.cancel();
                            } else {
                              setState(() {
                                _selectedViewMode = ViewMode.compactGrid;
                              });
                              _startViewSelectorTimer();
                            }
                          },
                        ),
                        // Standard Grid
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8.0),
                          icon: Icon(
                            Icons.grid_view_rounded,
                            size: 18,
                            color: _selectedViewMode == ViewMode.standardGrid
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          onPressed: () {
                            if (_selectedViewMode == ViewMode.standardGrid) {
                              setState(() {
                                _isViewSelectorExpanded = false;
                              });
                              _viewSelectorTimer?.cancel();
                            } else {
                              setState(() {
                                _selectedViewMode = ViewMode.standardGrid;
                              });
                              _startViewSelectorTimer();
                            }
                          },
                        ),
                        // Large Cards
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8.0),
                          icon: Icon(
                            Icons.view_headline_rounded,
                            size: 18,
                            color: _selectedViewMode == ViewMode.largeCards
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          onPressed: () {
                            if (_selectedViewMode == ViewMode.largeCards) {
                              setState(() {
                                _isViewSelectorExpanded = false;
                              });
                              _viewSelectorTimer?.cancel();
                            } else {
                              setState(() {
                                _selectedViewMode = ViewMode.largeCards;
                              });
                              _startViewSelectorTimer();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

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
