import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_state_provider.dart';
import '../../services/notification_service.dart';

class DebugLabScreen extends StatefulWidget {
  const DebugLabScreen({super.key});

  @override
  State<DebugLabScreen> createState() => _DebugLabScreenState();
}

class _DebugLabScreenState extends State<DebugLabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService.instance;

  String? _fcmToken;
  String _permissionStatus = 'Bilinmiyor';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDiagnosticInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDiagnosticInfo() async {
    setState(() => _isLoading = true);
    _fcmToken = _notificationService.currentFcmToken;
    final settings = await _notificationService.getNotificationSettings();
    if (settings != null) {
      _permissionStatus = settings.authorizationStatus.name;
    }
    setState(() => _isLoading = false);
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'Token Yok / Alınmadı';
    if (token.length <= 16) return token;
    return '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label panoya kopyalandı'),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEV LAB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Geliştirici & Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active_outlined), text: 'Bildirim & Push'),
            Tab(icon: Icon(Icons.badge_outlined), text: 'Kimlik / Auth'),
            Tab(icon: Icon(Icons.terminal_rounded), text: 'Teşhis & Loglar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ─── Build Metadata Banner ──────────────────────────────────────────
          _buildMetadataBanner(context, appState),

          // ─── Tab Views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationTab(context, appState),
                _buildAuthTab(context, appState),
                _buildDiagnosticsTab(context, appState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Metadata Banner ────────────────────────────────────────────────────────
  Widget _buildMetadataBanner(BuildContext context, dynamic appState) {
    final theme = Theme.of(context);
    final projectId = Firebase.apps.isNotEmpty ? Firebase.app().options.projectId : 'Mock / Local';
    final buildMode = kDebugMode ? 'DEBUG' : (kProfileMode ? 'PROFILE' : 'RELEASE');
    final platform = Platform.isAndroid ? 'Android ${Platform.operatingSystemVersion.split(' ').first}' : Platform.operatingSystem;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Emanetly v0.9.4', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kDebugMode ? Colors.green[700] : Colors.orange[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(buildMode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Text(platform, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Project ID: ', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              SelectableText(projectId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Profile: ', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              Text(
                appState.isProfileLoaded ? '✅ Loaded' : '⏳ Loading',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: appState.isProfileLoaded ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: Bildirim & Deep-Link ───────────────────────────────────────────
  Widget _buildNotificationTab(BuildContext context, dynamic appState) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Disclaimer Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Bu bölümdeki bildirim butonları Yerel (Local) bildirim motorunu test eder. Bildirime tıklandığında uygulamanın doğru sayfaya yönlenip yönlenmediğini (Deep-link) doğrulamak içindir.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live Status Card
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Canlı Bildirim Durumu', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 20),
              _buildKeyValueRow(
                'FCM Token:',
                _maskToken(_fcmToken),
                trailing: _fcmToken != null
                    ? IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () => _copyToClipboard(_fcmToken!, 'FCM Token'),
                        tooltip: 'Token\'ı Kopyala',
                      )
                    : null,
              ),
              _buildKeyValueRow('İzin Durumu:', _permissionStatus),
              _buildKeyValueRow(
                'Aktif Chat RequestId:',
                _notificationService.activeChatRequestId ?? 'Yok (Chat dışında)',
              ),
              _buildKeyValueRow(
                'Son Tıklama Payload:',
                _notificationService.lastReceivedPayload != null
                    ? jsonEncode(_notificationService.lastReceivedPayload)
                    : 'Henüz yok',
              ),
            ],
          ),
        ),
      ),
        const SizedBox(height: 20),

        // Test Triggers
        Text('Simüle Yerel Bildirim Fırlat', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        _buildSimulatorTile(
          icon: Icons.chat_bubble_outline_rounded,
          color: Colors.indigo,
          title: 'Simüle Yeni Mesaj',
          subtitle: 'Payload: route=request_chat, requestId=test_chat_req_1',
          onTap: () {
            _notificationService.showSimulatedNotification(
              title: 'Ahmet Emin Öz',
              body: 'Test mesajı: "Tabii, yarın kütüphanede teslim edebilirim."',
              data: {
                'route': 'request_chat',
                'type': 'chat',
                'requestId': 'test_chat_req_1',
              },
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🔔 Simüle mesaj bildirimi fırlatıldı! Bildirim çubuğunu açın.')),
            );
          },
        ),

        _buildSimulatorTile(
          icon: Icons.handshake_outlined,
          color: Colors.teal,
          title: 'Simüle Yeni Ödünç Talebi',
          subtitle: 'Payload: route=request_detail, requestId=test_borrow_req_1',
          onTap: () {
            _notificationService.showSimulatedNotification(
              title: 'Yeni Ödünç Talebi',
              body: 'Ayşe Yılmaz "Xbox Joystick" için ödünç talebinde bulundu.',
              data: {
                'route': 'request_chat',
                'type': 'request_update',
                'requestId': 'test_borrow_req_1',
              },
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🔔 Simüle talep bildirimi fırlatıldı!')),
            );
          },
        ),

        _buildSimulatorTile(
          icon: Icons.check_circle_outline_rounded,
          color: Colors.green,
          title: 'Simüle Talep Onaylandı',
          subtitle: 'Payload: route=request_chat, requestId=test_chat_req_1',
          onTap: () {
            _notificationService.showSimulatedNotification(
              title: 'Talebiniz Kabul Edildi! 🎉',
              body: 'Xbox Joystick talebiniz kabul edildi. Buluşma detaylarını konuşun.',
              data: {
                'route': 'request_chat',
                'type': 'status_change',
                'requestId': 'test_chat_req_1',
              },
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🔔 Simüle onay bildirimi fırlatıldı!')),
            );
          },
        ),
      ],
    );
  }

  // ─── TAB 2: Kimlik & Auth Denetleyicisi ─────────────────────────────────────
  Widget _buildAuthTab(BuildContext context, dynamic appState) {
    final theme = Theme.of(context);
    final user = appState.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Aktif oturum açmış kullanıcı yok'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => appState.signOut(),
              child: const Text('Giriş Ekranına Git'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(user.email, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildKeyValueRow('UID:', user.uid, trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () => _copyToClipboard(user.uid, 'UID'),
                  tooltip: 'UID Kopyala',
                )),
                _buildKeyValueRow('Kullanıcı Adı:', user.username ?? 'Tanımsız (null)'),
                _buildKeyValueRow('Kullanıcı Adı Kaynağı:', user.usernameSource),
                _buildKeyValueRow('Onboarding Tamam mı?:', user.onboardingComplete ? '✅ Evet' : '❌ Hayır'),
                _buildKeyValueRow('E-posta Doğrulandı mı?:', appState.isEmailVerified ? '✅ Evet' : '❌ Hayır'),
                _buildKeyValueRow('Güven Skoru (Trust):', '${user.trustScore} / 100'),
                _buildKeyValueRow('Ortalama Puan:', '${user.averageRating} (${user.reviewCount} yorum)'),
                _buildKeyValueRow('Kayıtlı FCM Token Sayısı:', '${user.fcmTokens.length} adet'),
                _buildKeyValueRow('Favori Eşya Sayısı:', '${user.favoriteItemIds.length} adet'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            setState(() => _isLoading = true);
            await appState.reloadUser();
            setState(() => _isLoading = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔄 Profil Firestore\'dan yeniden yüklendi.')),
              );
            }
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Profili Firestore\'dan Yeniden Çek'),
        ),
      ],
    );
  }

  // ─── TAB 3: Teşhis & Loglar ───────────────────────────────────────────────
  Widget _buildDiagnosticsTab(BuildContext context, dynamic appState) {
    final theme = Theme.of(context);
    final List<String> logs = appState.activityLogs;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Storage & Cache Controls
        Text('Önbellek & Hafıza Araçları', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined, color: Colors.blue),
                title: const Text('Görsel Önbelleğini (Image Cache) Temizle'),
                subtitle: const Text('Bellekteki indirilmiş resimleri sıfırlar'),
                trailing: const Icon(Icons.cleaning_services_rounded),
                onTap: () {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🧹 Görsel önbelleği temizlendi.')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage_rounded, color: Colors.orange),
                title: const Text('SharedPreferences Sıfırla'),
                subtitle: const Text('Tema, görünüm ve yerel ayarları temizler (Onay gerektirir)'),
                trailing: const Icon(Icons.delete_sweep_rounded, color: Colors.orange),
                onTap: () => _showClearPreferencesDialog(context, appState),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Crashlytics Controls
        Text('Crashlytics Test Araçları', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, color: Colors.amber),
                title: const Text('Non-Fatal Hata Gönder'),
                subtitle: const Text('Firebase Crashlytics\'e test hatası raporlar (Uygulama kapanmaz)'),
                onTap: () async {
                  try {
                    await FirebaseCrashlytics.instance.recordError(
                      Exception('Emanetly DebugLab: Non-fatal test error triggered at ${DateTime.now()}'),
                      StackTrace.current,
                      reason: 'DebugLab manual verification',
                      fatal: false,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ Non-fatal hata Crashlytics\'e iletildi.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hata: $e')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                title: const Text('Test Crash Fırlat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                subtitle: const Text('Gerçek çökme oluşturur (Uygulama derhal kapanır)'),
                onTap: () => _showTestCrashDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Log Console
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Canlı Aktivite Logları (${logs.length})', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            if (logs.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.copy_all_rounded, size: 16),
                label: const Text('Logları Kopyala'),
                onPressed: () {
                  final text = logs.join('\n');
                  _copyToClipboard(text, 'Tüm loglar');
                },
              ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          height: 220,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: logs.isEmpty
              ? const Center(
                  child: Text('Henüz kaydedilmiş log yok.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        logs[index],
                        style: const TextStyle(
                          color: Color(0xFF4AF626),
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ─── Dialogs & Helpers ──────────────────────────────────────────────────────
  void _showClearPreferencesDialog(BuildContext context, dynamic appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SharedPreferences Sıfırlansın mı?'),
        content: const Text(
          'Bu işlem telefon hafızasındaki tema tercihlerini, görünüm ayarlarını ve yerel önbelleği silecektir. Oturum açık kalmaya devam eder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🧹 SharedPreferences sıfırlandı. Uygulamayı yeniden başlatabilirsiniz.')),
                );
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _showTestCrashDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Gerçek Test Crash Fırlat'),
        content: const Text(
          'Bu işlem Firebase Crashlytics entegrasyonunu doğrulamak için uygulamayı bilerek çökertecektir (Force Crash). Uygulama anında kapanacaktır.\n\nDevam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              FirebaseCrashlytics.instance.crash();
            },
            child: const Text('Çökert (Crash)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatorTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.send_rounded, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
