import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_state_provider.dart';
import 'settings/delete_account_dialog.dart';
import 'settings/legal_document_screen.dart';
import 'settings/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notification states
  bool _isLoaded = false;
  bool _notifyRequests = true;
  bool _notifyMessages = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded) {
      _loadNotificationPreferences();
      _isLoaded = true;
    }
  }

  Future<void> _loadNotificationPreferences() async {
    final appState = AppStateProvider.of(context);
    final user = appState.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          final prefs = data?['notificationPreferences'] as Map<String, dynamic>?;
          if (prefs != null) {
            setState(() {
              _notifyRequests = prefs['newBorrowRequests'] ?? true;
              _notifyMessages = prefs['newMessages'] ?? true;
            });
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    final appState = AppStateProvider.of(context);
    final user = appState.currentUser;
    if (user == null) return;

    final oldRequests = _notifyRequests;
    final oldMessages = _notifyMessages;

    setState(() {
      if (key == 'newBorrowRequests') {
        _notifyRequests = value;
      } else if (key == 'newMessages') {
        _notifyMessages = value;
      }
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'notificationPreferences': {
          'newBorrowRequests': _notifyRequests,
          'newMessages': _notifyMessages,
        }
      });
    } catch (e) {
      setState(() {
        _notifyRequests = oldRequests;
        _notifyMessages = oldMessages;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar güncellenirken bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
                  title: const Text('Yeni soru ve talep bildirimleri'),
                  value: _notifyRequests,
                  onChanged: (val) => _updatePreference('newBorrowRequests', val),
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Yeni mesaj bildirimleri'),
                  value: _notifyMessages,
                  onChanged: (val) => _updatePreference('newMessages', val),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Legal Documents
          _buildSectionHeader(context, 'Yasal Bilgiler', Icons.gavel_rounded),
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
                  leading: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                  title: const Text('Kullanım Şartları'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => LegalDocumentScreen.showTOS(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: theme.colorScheme.primary),
                  title: const Text('Gizlilik Politikası'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => LegalDocumentScreen.showPrivacyPolicy(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
                  title: const Text('KVKK Aydınlatma Metni'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => LegalDocumentScreen.showKVKK(context),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
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
                    appState.signOut();
                    // Go back to the root of navigation (which will drop into AuthGate login)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Hesabımı sil', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const DeleteAccountDialog(),
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
