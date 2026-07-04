import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../models/item.dart';
import 'widgets/item_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    // Sample mock item for live preview
    final previewItem = EmanetItem(
      id: 'preview_1',
      title: 'Önizleme Eşyası',
      description: 'Renk paleti ve görünüm modunu canlı önizlemek için örnek karttır.',
      category: 'Elektronik',
      lenderId: 'user_2',
      lenderName: 'Ayşe Yılmaz',
      location: 'Kütüphane',
      status: EmanetStatus.available,
      createdAt: DateTime.now(),
      mockImageColorValue: AppTheme.palettes[appState.selectedPaletteIndex]['seed'].value,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görünüm Ayarları'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Dark Mode Option
          _buildSectionHeader(context, 'Tema Modu', Icons.brightness_6_outlined),
          const SizedBox(height: 12),
          Card(
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

          // Section 2: Color Palettes Choice
          _buildSectionHeader(context, 'Renk Paleti', Icons.palette_outlined),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AppTheme.palettes.length,
              itemBuilder: (context, index) {
                final palette = AppTheme.palettes[index];
                final isSelected = appState.selectedPaletteIndex == index;
                final seedColor = palette['seed'] as Color;
                final secondary = palette['secondary'] as Color;

                return GestureDetector(
                  onTap: () => appState.changePalette(index),
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outlineVariant.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Circle representation
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [seedColor, secondary],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          palette['name'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: View Mode Configuration
          _buildSectionHeader(context, 'Ürün Akış Modu', Icons.grid_view_outlined),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _buildRadioListTile<ViewMode>(
                  context: context,
                  title: 'Standard Grid (Geniş 2\'li)',
                  value: ViewMode.standardGrid,
                  groupValue: appState.gridViewMode,
                  onChanged: (mode) => appState.changeViewMode(mode!),
                  icon: Icons.grid_view,
                ),
                const Divider(height: 1),
                _buildRadioListTile<ViewMode>(
                  context: context,
                  title: 'Compact Grid (Yoğun 2\'li)',
                  value: ViewMode.compactGrid,
                  groupValue: appState.gridViewMode,
                  onChanged: (mode) => appState.changeViewMode(mode!),
                  icon: Icons.grid_on,
                ),
                const Divider(height: 1),
                _buildRadioListTile<ViewMode>(
                  context: context,
                  title: 'Large Cards (Geniş Tek İlan)',
                  value: ViewMode.largeCards,
                  groupValue: appState.gridViewMode,
                  onChanged: (mode) => appState.changeViewMode(mode!),
                  icon: Icons.view_headline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Section 4: Live Preview box
          _buildSectionHeader(context, 'Canlı Önizleme', Icons.visibility_outlined),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: appState.gridViewMode == ViewMode.largeCards ? double.infinity : 200,
              child: IgnorePointer(
                child: ItemCard(
                  item: previewItem,
                  viewMode: appState.gridViewMode,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
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
