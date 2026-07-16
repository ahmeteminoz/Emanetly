import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'item_detail_screen.dart';
import 'widgets/item_card.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

  void _showReportAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          action == 'report' 
              ? 'Kullanıcı bildirme talebi alındı. İnceleme başlatılacaktır.' 
              : 'Kullanıcı engellendi. Artık ilanlarınızı göremeyecek.',
        ),
        backgroundColor: action == 'report' ? Colors.orange : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    return FutureBuilder<UserProfile?>(
      future: appState.getUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Yükleniyor')),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil Bulunamadı')),
            body: const Center(child: Text('Aradığınız kullanıcı profili bulunamadı.')),
          );
        }

        // Filter active items listed by this user
        final userActiveItems = appState.items
            .where((i) => i.lenderId == userId && i.status == EmanetStatus.available)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text('${user.name} Profili'),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
        children: [
          // 1. Profile Header Details Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Large Avatar (Read-Only)
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Name & Username
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.username,
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
                        '${user.department} • İstanbul',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emanetly Üyesi: Güz 2024',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 12),
                  // Bio
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      user.bio,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Large Trust Score Card
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${user.trustScore}',
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Güven Skoru',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${user.averageRating}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              ' (${user.reviewCount} Değerlendirme)',
                              style: TextStyle(color: theme.colorScheme.outline, fontSize: 11),
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

          // 3. Verification Badges
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

          // 4. Achievement Badges
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
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
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
          const SizedBox(height: 20),

          // 5. 2x2 Statistics Grid
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
            childAspectRatio: 1.8,
            children: [
              _buildStatCard(theme, 'Ödünç Alma', '${user.successfulBorrows} İşlem', Icons.shopping_bag_outlined),
              _buildStatCard(theme, 'Ödünç Verme', '${user.successfulLends} İşlem', Icons.share_outlined),
              _buildStatCard(theme, 'Zamanında İade', '%${user.onTimeReturnRate.toInt()}', Icons.timer_outlined),
              _buildStatCard(theme, 'Yanıt Süresi', user.avgResponseTime, Icons.flash_on_outlined),
            ],
          ),
          const SizedBox(height: 20),

          // 6. Preferred Handover Areas
          Text(
            'Tercih Ettiği Teslim Bölgeleri',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildLocationTile(theme, 'Kütüphane önü', 'Merkez Kütüphane ana giriş kapısı'),
                  const Divider(height: 1, indent: 48),
                  _buildLocationTile(theme, 'Mühendislik Fakültesi çevresi', 'Mühendislik B Blok giriş merdivenleri'),
                  const Divider(height: 1, indent: 48),
                  _buildLocationTile(theme, 'Kampüs giriş kapısı', 'Ana nizamiye metro çıkışı'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 7. Active Listings (Dolap style Grid)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yayındaki İlanları (${userActiveItems.length})',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (userActiveItems.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text('Kullanıcının aktif ilanı bulunmuyor.', style: TextStyle(fontStyle: FontStyle.italic)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.72,
              ),
              itemCount: userActiveItems.length,
              itemBuilder: (context, index) {
                return ItemCard(
                  item: userActiveItems[index],
                  viewMode: ViewMode.standardGrid,
                );
              },
            ),
          const SizedBox(height: 24),

          // 8. Son Yorumlar & Değerlendirmeler Section
          Text(
            'Son Değerlendirmeler',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (user.reviews.isEmpty)
            const Text('Henüz değerlendirme yapılmamış.', style: TextStyle(fontStyle: FontStyle.italic))
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
                      // Review Tag Chips
                      Wrap(
                        spacing: 4,
                        children: const [
                          _ReviewTagChip(label: 'Zamanında teslim'),
                          _ReviewTagChip(label: 'Hızlı iletişim'),
                        ],
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

          // 9. Safety Actions (Report & Block buttons)
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReportAction(context, 'report'),
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: const Text('Bildir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReportAction(context, 'block'),
                  icon: const Icon(Icons.block_flipped, size: 18),
                  label: const Text('Engelle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
      },
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
                Icon(icon, size: 13, color: theme.colorScheme.outline),
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
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTile(ThemeData theme, String title, String subtitle) {
    return ListTile(
      leading: Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline)),
      dense: true,
    );
  }
}

class _ReviewTagChip extends StatelessWidget {
  final String label;
  const _ReviewTagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
      ),
    );
  }
}
