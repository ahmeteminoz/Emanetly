import 'package:flutter/material.dart';
import '../providers/app_state_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Privacy states
  bool _approxLocation = true;
  bool _exactLocationPostRequest = true;

  // Notification states
  bool _notifyRequests = true;
  bool _notifyMessages = true;
  bool _notifyReminders = true;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Section 1: Theme selection
          _buildSectionHeader(context, 'Görünüm ve Tema', Icons.brightness_6_outlined),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _buildRadioListTile<ThemeMode>(
                  context: context,
                  title: 'Açık Tema',
                  value: ThemeMode.light,
                  groupValue: appState.themeMode,
                  onChanged: (mode) => appState.changeThemeMode(mode!),
                  icon: Icons.light_mode_outlined,
                ),
                const Divider(height: 1),
                _buildRadioListTile<ThemeMode>(
                  context: context,
                  title: 'Koyu Tema',
                  value: ThemeMode.dark,
                  groupValue: appState.themeMode,
                  onChanged: (mode) => appState.changeThemeMode(mode!),
                  icon: Icons.dark_mode_outlined,
                ),
                const Divider(height: 1),
                _buildRadioListTile<ThemeMode>(
                  context: context,
                  title: 'Sistem Teması',
                  value: ThemeMode.system,
                  groupValue: appState.themeMode,
                  onChanged: (mode) => appState.changeThemeMode(mode!),
                  icon: Icons.settings_suggest_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Privacy Settings
          _buildSectionHeader(context, 'Gizlilik Ayarları', Icons.security_outlined),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Yaklaşık konum göster'),
                  subtitle: const Text('Diğer öğrenciler eşyalarınızın yaklaşık bölgesini görebilir.', style: TextStyle(fontSize: 12)),
                  value: _approxLocation,
                  onChanged: (val) {
                    setState(() {
                      _approxLocation = val;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Tam konumu sadece talep sonrası göster'),
                  subtitle: const Text('Buluşma noktası tam adresi sadece talep kabul edilirse paylaşılır.', style: TextStyle(fontSize: 12)),
                  value: _exactLocationPostRequest,
                  onChanged: (val) {
                    setState(() {
                      _exactLocationPostRequest = val;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Notification Settings
          _buildSectionHeader(context, 'Bildirimler', Icons.notifications_none_rounded),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Yeni talep bildirimleri'),
                  value: _notifyRequests,
                  onChanged: (val) {
                    setState(() {
                      _notifyRequests = val;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Yeni mesaj bildirimleri'),
                  value: _notifyMessages,
                  onChanged: (val) {
                    setState(() {
                      _notifyMessages = val;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Teslim / iade hatırlatmaları'),
                  value: _notifyReminders,
                  onChanged: (val) {
                    setState(() {
                      _notifyReminders = val;
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 4: Account Actions
          _buildSectionHeader(context, 'Hesap Ayarları', Icons.person_outline_rounded),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                  title: const Text('Profil bilgilerini düzenle'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil düzenleme özelliği sonraki sürümde eklenecek.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Çıkış yap', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Çıkış yapma özelliği sonraki sürümde eklenecek.'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioListTile<T>({
    required BuildContext context,
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return RadioListTile<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      activeColor: theme.colorScheme.primary,
    );
  }
}
