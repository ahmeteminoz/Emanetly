import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/user_profile.dart';
import '../models/borrow_request.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import '../services/auth_service.dart';
import 'item_detail_screen.dart';
import 'settings_screen.dart';
import 'public_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showPhotoSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil fotoğrafı yükleme özelliği sonraki sürümde eklenecek.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final currentUser = appState.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Kullanıcı girişi yapılmadı.'));
    }

    // Filter active items owned by logged in user
    final myListedItems = appState.items.where((i) => i.lenderId == currentUser.uid).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      // Profile Picture with camera overlay button
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showPhotoSnackbar(context),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : '?',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 40,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _showPhotoSnackbar(context),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Full Name
                      Text(
                        currentUser.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      
                      // Username
                      Text(
                        currentUser.username,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Department & Campus info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 16, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            '${currentUser.department} • İstanbul',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Bio
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          currentUser.bio,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              // Tab Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('Güven Paneli'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 18),
                            SizedBox(width: 6),
                            Text('İlanlarım & Geçmiş'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  theme.colorScheme.surface,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Tab 1: Trust Dashboard
              _buildTrustDashboardTab(context, currentUser, theme),
              
              // Tab 2: My Listings & History
              _buildActiveListingsTab(context, myListedItems, currentUser, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustDashboardTab(BuildContext context, UserProfile user, ThemeData theme) {
    final appState = AppStateProvider.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Large Trust Score Card
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Circular Trust Score representation
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${user.trustScore}',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Güven Skoru',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.verified_outlined, color: theme.colorScheme.primary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          Text(
                            user.reviewCount == 0
                                ? 'Henüz değerlendirilmedi'
                                : '${user.averageRating}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (user.reviewCount > 0)
                            Text(
                              '(${user.reviewCount} Değerlendirme)',
                              style: TextStyle(color: theme.colorScheme.outline, fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 2. Verification Badges
        Text(
          'Doğrulamalar',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.verificationBadges.map((badge) {
            return Chip(
              avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
              label: Text(badge, style: const TextStyle(fontSize: 11)),
              backgroundColor: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // 3. 2x2 Statistics Grid
        Text(
          'İşlem İstatistikleri',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _buildStatCard(theme, 'Ödünç Alma', '${user.successfulBorrows} İşlem', Icons.shopping_bag_outlined),
            _buildStatCard(theme, 'Ödünç Verme', '${user.successfulLends} İşlem', Icons.share_outlined),
            _buildStatCard(theme, 'Zamanında İade', '%${user.onTimeReturnRate.toInt()}', Icons.timer_outlined),
            _buildStatCard(theme, 'Yanıt Süresi', user.avgResponseTime, Icons.flash_on_outlined),
          ],
        ),
        const SizedBox(height: 8),
        // Late returns warning label if any
        if (user.lateReturnsCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  'Geç İade Sayısı: ${user.lateReturnsCount}',
                  style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'Gecikmiş İade: Yok',
                style: TextStyle(color: Colors.green[800], fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // 4. Achievement User Badges
        Text(
          'Kazanılan Rozetler',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.userBadges.map((badge) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    badge,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // 5. Recent reviews list
        Text(
          'Son Değerlendirmeler',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
        ),
        const SizedBox(height: 8),
        if (user.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Henüz değerlendirme yapılmamış.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          ...user.reviews.map((review) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.authorName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              review.rating,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.dateText,
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 24),

        // 6. Test Prototype Account Switcher (For Demo purposes - Hidden in real FirebaseAuth mode)
        if (appState.authService is MockAuthService) ...[
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.swap_horizontal_circle_outlined, color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Demo: Kullanıcı Değiştir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              DropdownButton<String>(
                value: user.uid,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                items: appState.availableMockUsers.map<DropdownMenuItem<String>>((UserProfile u) {
                  return DropdownMenuItem<String>(
                    value: u.uid,
                    child: Text(u.name),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    appState.switchUser(value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String metric, IconData icon) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.outline, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              metric,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListingsTab(BuildContext context, List<EmanetItem> items, UserProfile currentUser, ThemeData theme) {
    final appState = AppStateProvider.of(context);
    final completedRequests = appState.borrowRequests.where((r) {
      final isParticipant = r.ownerId == currentUser.uid || r.requesterId == currentUser.uid;
      return isParticipant && r.status == BorrowRequestStatus.completed;
    }).toList();

    if (items.isEmpty && completedRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              const Text(
                'Henüz bir ilanınız veya geçmiş işleminiz bulunmuyor.',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (items.isNotEmpty) ...[
          Text(
            'Aktif İlanlarım (${items.length})',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final isBorrowed = item.status == EmanetStatus.borrowed;
            final isPending = item.status == EmanetStatus.pendingApproval || item.status == EmanetStatus.pendingReturn;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(item.mockImageColorValue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: Color(item.mockImageColorValue)),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Konum: ${item.location} • ${item.category}'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBorrowed 
                        ? Colors.blue.shade50 
                        : isPending 
                            ? Colors.orange.shade50 
                            : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isBorrowed 
                        ? 'Ödünçte' 
                        : isPending 
                            ? 'İşlemde' 
                            : 'Müsait',
                    style: TextStyle(
                      fontSize: 10, 
                      fontWeight: FontWeight.bold, 
                      color: isBorrowed 
                          ? Colors.blue.shade800 
                          : isPending 
                              ? Colors.orange.shade800 
                              : Colors.green.shade800
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(item: item),
                    ),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        if (completedRequests.isNotEmpty) ...[
          Text(
            'Geçmiş İşlemlerim (${completedRequests.length})',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          ...completedRequests.map((request) {
            final isLender = request.ownerId == currentUser.uid;
            EmanetItem? relatedItem;
            try {
              relatedItem = appState.items.firstWhere((i) => i.id == request.itemId);
            } catch (_) {}

            final title = relatedItem?.title ?? 'Emanet Eşya';
            final category = relatedItem?.category ?? 'Kategori';
            final colorVal = relatedItem?.mockImageColorValue ?? 0xFF1E3A8A;
            
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(colorVal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.history_rounded, color: Color(colorVal)),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  isLender 
                      ? 'Ödünç Verildi (Tamamlandı)' 
                      : 'Ödünç Alındı (Tamamlandı)',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.account_circle_outlined),
                onTap: () async {
                  final otherUserId = isLender ? request.requesterId : request.ownerId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfileScreen(userId: otherUserId),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
