import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/item.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import 'widgets/item_card.dart';
import 'widgets/full_screen_image_viewer.dart';
import 'widgets/report_dialog.dart';

class PublicProfileScreen extends StatelessWidget {
  final String userId;

  const PublicProfileScreen({
    super.key,
    required this.userId,
  });

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

        final isSelf = appState.currentUser?.uid == userId;
        final isRelationBlocked = appState.isRelationBlocked(userId);
        final iBlockedThem = appState.isUserBlocked(userId);

        if (!isSelf && isRelationBlocked) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profil'),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? (user.avatarUrl!.startsWith('http')
                              ? NetworkImage(user.avatarUrl!)
                              : FileImage(File(user.avatarUrl!)) as ImageProvider)
                          : null,
                      child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? null
                          : Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name & Username
                  Text(
                    user.name,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.username ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Warning/Info Card
                  Card(
                    elevation: 0,
                    color: Colors.red.shade50.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.lock_outline_rounded, color: Colors.red, size: 32),
                          const SizedBox(height: 12),
                          const Text(
                            'Bu Profile Erişim Kısıtlandı',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            iBlockedThem
                                ? 'Bu kullanıcıyı engellediniz. Aktif iade/teslimat işlemleri dışındaki bio, güven skoru, rozetler ve diğer ilanlar gizlenmiştir.'
                                : 'Bu kullanıcı ile erişim kısıtlanmıştır. Aktif iade/teslimat işlemleri dışındaki bio, güven skoru, rozetler ve diğer ilanlar gizlenmiştir.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (iBlockedThem)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await appState.unblockUser(userId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kullanıcı engeli kaldırıldı.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Engeli Kaldır'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${user.name} Profili'),
            centerTitle: true,
            actions: isSelf ? null : [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'block') {
                    if (iBlockedThem) {
                      await appState.unblockUser(userId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${user.name} engeli kaldırıldı.')),
                        );
                      }
                    } else {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('${user.name} Engellensin mi?'),
                          content: const Text('Bu kullanıcıyı engellediğinizde birbirinizle yeni mesajlaşamaz ve yeni ödünç talebi oluşturamazsınız.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('Engelle'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await appState.blockUser(userId, source: 'profile');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${user.name} engellendi.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  } else if (value == 'report') {
                    ReportDialog.show(
                      context,
                      targetType: 'user',
                      targetId: userId,
                      targetTitle: '${user.name} Profilini Şikayet Et',
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(
                          iBlockedThem ? Icons.lock_open_rounded : Icons.block_rounded,
                          color: iBlockedThem ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(iBlockedThem ? 'Engeli Kaldır' : 'Kullanıcıyı Engelle'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Kullanıcıyı Şikayet Et'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
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
                  GestureDetector(
                    onTap: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageViewer(
                                  imageUrl: user.avatarUrl!,
                                  heroTag: 'public_profile_avatar_${user.uid}',
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Hero(
                      tag: 'public_profile_avatar_${user.uid}',
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                            ? (user.avatarUrl!.startsWith('http')
                                ? NetworkImage(user.avatarUrl!)
                                : FileImage(File(user.avatarUrl!)) as ImageProvider)
                            : null,
                        child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                            ? null
                            : Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
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
                    user.username ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school_outlined, size: 16, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${user.department} • Bandırma Onyedi Eylül Üni.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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

          // 2. Large Rating Card
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Değerlendirme Ortalaması',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 2,
                          children: [
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
          if (user.successfulBorrows == 0 && user.successfulLends == 0 && user.reviewCount == 0)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'Henüz tamamlanmış işlem yok',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                if (user.successfulBorrows > 0)
                  _buildStatCard(theme, 'Ödünç Alma', '${user.successfulBorrows} İşlem', Icons.shopping_bag_outlined),
                if (user.successfulLends > 0)
                  _buildStatCard(theme, 'Ödünç Verme', '${user.successfulLends} İşlem', Icons.share_outlined),
              ],
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
                  onPressed: () {
                    ReportDialog.show(
                      context,
                      targetType: 'user',
                      targetId: userId,
                      targetTitle: '${user.name} Profilini Şikayet Et',
                    );
                  },
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
                  onPressed: () async {
                    final isBlocked = appState.isUserBlocked(userId);
                    if (isBlocked) {
                      await appState.unblockUser(userId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${user.name} engeli kaldırıldı.')),
                        );
                      }
                    } else {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('${user.name} Engellensin mi?'),
                          content: const Text('Bu kullanıcıyı engellediğinizde birbirinizle yeni mesajlaşamaz ve yeni ödünç talebi oluşturamazsınız.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('Engelle'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await appState.blockUser(userId, source: 'profile');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${user.name} engellendi.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: Icon(
                    appState.isUserBlocked(userId) ? Icons.check_circle_outline : Icons.block_flipped, 
                    size: 18
                  ),
                  label: Text(appState.isUserBlocked(userId) ? 'Engeli Kaldır' : 'Engelle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appState.isUserBlocked(userId) ? Colors.green : Colors.red,
                    side: BorderSide(color: appState.isUserBlocked(userId) ? Colors.green : Colors.red),
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
