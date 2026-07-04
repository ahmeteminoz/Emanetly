import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'active_transactions_screen.dart';
import 'profile_screen.dart';
import 'add_item_screen.dart';
import '../models/item.dart';
import '../providers/app_state_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const FavoritesScreen(),
    const ActiveTransactionsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);

    // Count pending requests to show a badge on the Profile tab if needed
    final myListedItems = appState.items.where((i) => i.lenderId == appState.currentUser?.uid).toList();
    final pendingCount = myListedItems.where(
      (i) => i.status == EmanetStatus.pendingApproval || i.status == EmanetStatus.pendingReturn
    ).length;

    // Count active deliveries for tracking badge
    final activeTrackingCount = appState.items.where((item) {
      final isParticipant = item.borrowerId == appState.currentUser?.uid || item.lenderId == appState.currentUser?.uid;
      final inProgress = item.status != EmanetStatus.available;
      return isParticipant && inProgress;
    }).length;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            if (appState.isLoading)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemScreen(
                onItemAdded: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 0; // Switch to Home Feed tab
                  });
                },
              ),
            ),
          );
        },
        tooltip: 'Yeni İlan Paylaş',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                _currentIndex == 0 ? Icons.explore : Icons.explore_outlined,
                color: _currentIndex == 0 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
              tooltip: 'Keşfet',
            ),
            IconButton(
              icon: Icon(
                _currentIndex == 1 ? Icons.favorite : Icons.favorite_border,
                color: _currentIndex == 1 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              tooltip: 'Favoriler',
            ),
            const SizedBox(width: 48), // Space for floating action button
            Badge(
              isLabelVisible: activeTrackingCount > 0,
              label: Text(activeTrackingCount.toString()),
              backgroundColor: theme.colorScheme.secondary,
              child: IconButton(
                icon: Icon(
                  _currentIndex == 2 ? Icons.local_shipping : Icons.local_shipping_outlined,
                  color: _currentIndex == 2 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
                tooltip: 'Aktif Takip',
              ),
            ),
            Badge(
              isLabelVisible: pendingCount > 0,
              label: Text(pendingCount.toString()),
              child: IconButton(
                icon: Icon(
                  _currentIndex == 3 ? Icons.person : Icons.person_outline,
                  color: _currentIndex == 3 ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
                tooltip: 'Profilim',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
