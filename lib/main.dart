import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'providers/app_state_provider.dart';
import 'services/auth_service.dart';
import 'services/item_service.dart';
import 'services/qr_service.dart';
import 'screens/main_layout.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Instantiate services
  final authService = MockAuthService();
  final itemService = MockItemService();
  final qrService = MockQrService();

  // Instantiate application state controller
  final appState = AppState(
    authService: authService,
    itemService: itemService,
    qrService: qrService,
  );

  runApp(
    AppStateProvider(
      notifier: appState,
      child: const KampusEmanetApp(),
    ),
  );
}

class KampusEmanetApp extends StatelessWidget {
  const KampusEmanetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    return MaterialApp(
      title: 'KampüsEmanet',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: AppTheme.buildTheme(
        isDark: false,
        paletteIndex: appState.selectedPaletteIndex,
      ),
      darkTheme: AppTheme.buildTheme(
        isDark: true,
        paletteIndex: appState.selectedPaletteIndex,
      ),
      home: const MainLayout(),
    );
  }
}
